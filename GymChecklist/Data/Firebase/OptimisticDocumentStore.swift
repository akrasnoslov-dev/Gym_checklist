import Foundation

/// A failure of an optimistic write, before a repository maps it onto its own
/// domain failure type (GYM-13).
enum OptimisticDocumentFailure<Key, Value> {
    case saveRejected(Value)
    case deleteRejected(Value)
    /// A delete was rejected for a document that was not in the local list.
    case deleteRejectedWithoutLocalCopy(Key)
    case saveUnconfirmedAfterRestart(Value)
    case deleteUnconfirmedAfterRestart(Value)
}

/// The persistence bookkeeping shared by every Firestore repository (GYM-13):
/// per-document optimistic mutation tracking, the durable pending-write
/// journal, rollback of rejected writes, write/delete diagnostics, and the
/// post-restart reconcile. Repositories keep their own listener, decoding and
/// in-memory list; they apply rollbacks through `restore` and turn failures
/// into their domain failure type through `report`.
@MainActor
final class OptimisticDocumentStore<Key: Codable & Hashable, Value: Codable & Equatable> {
    typealias Ticket = ScopedDocumentMutationTicket<Key>
    typealias WriteCompletion = (Swift.Error?) -> Void

    private let collection: String
    private var mutations = ScopedDocumentMutationTracker<Key, Value>()
    private var journal: DurablePendingMutationJournal<Key, Value>?
    private let restore: @MainActor (Key, PersistedDocument<Value>) -> Void
    private let report: @MainActor (OptimisticDocumentFailure<Key, Value>) -> Void

    /// - Parameters:
    ///   - collection: Firestore collection name used in diagnostics.
    ///   - journalScope: one of `PendingMutationJournalStorage.scopes`.
    ///   - userID: owner of the journal; nil keeps no journal (signed out).
    init(
        collection: String,
        journalScope: String,
        userID: UserID?,
        restore: @escaping @MainActor (Key, PersistedDocument<Value>) -> Void,
        report: @escaping @MainActor (OptimisticDocumentFailure<Key, Value>) -> Void
    ) {
        self.collection = collection
        self.restore = restore
        self.report = report
        journal = userID.map {
            DurablePendingMutationJournal(storageKey: PendingMutationJournalStorage.key(scope: journalScope, userID: $0))
        }
    }

    /// Starts an optimistic mutation and records its intent in the journal.
    /// The caller applies `attempted` to its local list right after.
    func begin(
        key: Key,
        baseline: PersistedDocument<Value>,
        attempted: PersistedDocument<Value>
    ) -> Ticket {
        let ticket = mutations.begin(key: key, baseline: baseline, attempted: attempted)
        journal?.record(ticket, attempted: attempted)
        return ticket
    }

    /// Sends a write. `send` must pass the given completion to Firestore. A
    /// write that throws before reaching Firestore is rolled back without a
    /// failure report and the error is rethrown to the caller.
    func write(_ ticket: Ticket, documentID: String, send: (@escaping WriteCompletion) throws -> Void) throws {
        do {
            try send(completion(for: ticket, operation: .write, documentID: documentID))
        } catch {
            FirestoreDiagnostics.shared.recordIfFailed(
                error, operation: .write, collection: collection, documentID: documentID
            )
            complete(ticket, error: error, reportsFailure: false)
            throw error
        }
    }

    /// Sends a delete. `send` must pass the given completion to Firestore.
    func delete(_ ticket: Ticket, documentID: String, send: (@escaping WriteCompletion) -> Void) {
        send(completion(for: ticket, operation: .delete, documentID: documentID))
    }

    private func completion(
        for ticket: Ticket,
        operation: FirestoreDiagnosticOperation,
        documentID: String
    ) -> WriteCompletion {
        let collection = self.collection
        return { [weak self] error in
            FirestoreDiagnostics.shared.recordIfFailed(
                error, operation: operation, collection: collection, documentID: documentID
            )
            Task { @MainActor in self?.complete(ticket, error: error) }
        }
    }

    /// Settles a mutation. A rejected one that no newer write supersedes is
    /// rolled back through `restore` and, unless suppressed, reported.
    func complete(_ ticket: Ticket, error: Swift.Error?, reportsFailure: Bool = true) {
        let result: ScopedDocumentMutationResult = error == nil ? .accepted : .rejected
        journal?.complete(ticket, result: result)
        guard case let .rejected(rollback, attempted) = mutations.complete(ticket, result: result) else { return }
        restore(ticket.key, rollback)
        guard reportsFailure else { return }
        switch (rollback, attempted) {
        case let (_, .value(value)):
            report(.saveRejected(value))
        case let (.value(value), .missing):
            report(.deleteRejected(value))
        case (.missing, .missing):
            report(.deleteRejectedWithoutLocalCopy(ticket.key))
        }
    }

    /// Reports journal entries from a previous launch that the server does not
    /// confirm. Only a server snapshot without pending writes is authoritative.
    func reconcileRestarted(
        isFromCache: Bool,
        hasPendingWrites: Bool,
        stableValues: @autoclosure () -> [Key: Value]
    ) {
        guard !isFromCache, !hasPendingWrites else { return }
        for unconfirmed in journal?.reconcileRestarted(stableValues: stableValues()) ?? [] {
            switch (unconfirmed.attempted, unconfirmed.stable) {
            case let (.value(value), _):
                report(.saveUnconfirmedAfterRestart(value))
            case let (.missing, .value(value)):
                report(.deleteUnconfirmedAfterRestart(value))
            case (.missing, .missing):
                break
            }
        }
    }
}
