# MVP acceptance checklist (M9.1)

This checklist defines the **current pre-payment functional acceptance**. It is not App Store/TestFlight release acceptance.

Current rule: verify everything that can be implemented and proven at zero cost before the user decides whether to pay for Apple distribution. Use Firebase Spark only; do not attach billing or upgrade to Blaze without explicit approval.

## Current blocker status

- Program week/date navigation remains regression-covered. Approved source `e17cb8173a6373059729226453c568e976954d33` was checked out and asserted by green authoritative macOS candidate run `33991955146`; its focused regression and candidate-full suite passed.
- Physical-iPhone and live Spark confirmation remain required; do not treat simulator CI as that evidence.

## Free acceptance matrix

| Scenario | Automated/static coverage | Free evidence required now |
| --- | --- | --- |
| Register via email/password | Unit + UI registration tests | Live Firebase Spark |
| Login/reset/logout via email/password | Unit + UI auth tests | Live Firebase Spark |
| Google Sign-In | Native SDK path + deterministic tests | Live Spark/provider configuration on device |
| First-use Today and create workout | Today/Program UI tests | Physical-iPhone review |
| Program date/week navigation | UI coverage exists | CI green; physical-iPhone proof |
| Create/edit/delete dated workout | Domain + Program UI tests | Physical-iPhone review |
| Search/add custom exercise | Domain + Program UI tests | Live Firestore persistence + device review |
| Arbitrary reps/weight/time and set ordering | Domain + UI tests | Physical-iPhone review |
| Copy workout independently | Domain + Program UI tests | Physical-iPhone review |
| Repeat workout independently | Domain + Program UI tests | Physical-iPhone review |
| Today complete/undo in arbitrary order | Domain + Today UI tests | Physical-iPhone review |
| Today planned/actual long-press edit | Domain + Today UI tests | Physical-iPhone review |
| Skip and restore exercise | Domain + Today UI tests | Physical-iPhone review |
| Rest day / no-program states | Today UI tests | Physical-iPhone review |
| Completion popup | Domain + Today UI tests | Device + VoiceOver review |
| Historical view / actual edit | Domain + Program UI tests | Relaunch/persistence proof |
| System/Light/Dark | Unit + UI tests | Device + contrast review |
| kg/lb display and input | Unit + UI tests | Device review |
| Firestore persistence | Mapping/repository tests | Create -> terminate -> relaunch on Spark |
| Two-user owner isolation | Rules/contracts | Two non-production Spark users |
| Offline execution/reconnect | Deterministic repository tests | Cache -> airplane mode -> mutate -> reconnect |
| Analytics | Event tests/contracts | Verify free Spark Analytics path |
| Crashlytics | Bootstrap/privacy contracts | Verify free Spark crash-reporting path |
| Accessibility | UI identifiers/Dynamic Type coverage | Manual VoiceOver + Dynamic Type + contrast |

## Current CI gates

- The required exact-candidate gate is satisfied: `33991955146` completed successfully after checking out and asserting `e17cb8173a6373059729226453c568e976954d33`, then running the focused blocker regression and candidate-full suite.
- Do not dispatch another macOS build/unit/UI/smoke/full run for this unchanged candidate. A later production, test, or project change requires the normal two-pass gate policy.
- A failure independently reproduced in the product cannot be waived as a test flake.

## Paid/billing-dependent checks deliberately deferred

These are not current acceptance failures:

- Apple Developer Program membership.
- App Store Connect and TestFlight.
- Paid/release signing, distribution secrets, and App Store submission.
- Live Sign in with Apple configuration where paid Apple capabilities are required.
- Live deployment/validation of `functions:deleteAccount` if Firebase requires Blaze/billing. The client flow, backend source, and automated contracts remain required now.
- Final App Store icon/release metadata and `dev -> main`.

## Final iPhone review script (single pass)

Пройти один раз целиком, по порядку, ничего не исправляя по ходу. Каждое замечание сразу заводить задачей в Linear (команда GYM, метка Bug): номер шага, что ожидалось, что произошло, скрин или запись экрана. Исправления делаются одним пакетом после окончания прохода; повторная проверка касается только исправленных пунктов.

Подготовка: свежий IPA с точного SHA (указан в `docs/progress.md`), Firebase Spark, тестовый аккаунт A и второй аккаунт B.

**1. Вход**
- [ ] 1.1 Вход аккаунтом A (email или Google). Открывается Today.
- [ ] 1.2 Свернуть и развернуть приложение — экран и данные на месте.

**2. Program — план**
- [ ] 2.1 Week ↔ Month, листание недель и месяцев: шапка и календарь не прыгают, нет пустой полосы и «призрачной» кнопки.
- [ ] 2.2 Тап по любой части ячейки дня (не только по цифре) выбирает день — и в Week, и в Month.
- [ ] 2.3 Будущий день → Create workout → одна пустая тренировка, без лишних вопросов.
- [ ] 2.4 Добавить системное упражнение и своё (custom), переименовать и удалить своё.
- [ ] 2.5 Add set (тап по всей строке «Add set»), редактировать reps/weight/time: целый вес показывается без `.0`, подписи полей видны.
- [ ] 2.6 Сменить тип упражнения (Weighted / Reps only / Timed) — все сеты меняются согласованно.
- [ ] 2.7 Свайп влево по сету → Delete → одно подтверждение → сет удалён.
- [ ] 2.8 Перетащить сет за ручку вверх и вниз; начать перетаскивание и отпустить на месте — ничего не ломается, нет залипших оверлеев.
- [ ] 2.9 Закрыть редактор сета свайпом вниз с несохранёнными изменениями — приложение спрашивает, данные не теряются молча.
- [ ] 2.10 Удалить тренировку → одно подтверждение → день пуст.

**3. Program — Copy и Repeat**
- [ ] 3.1 Пустой день → Copy из прошлой заполненной тренировки: в календаре источника отмечены только дни с сетами, тап по всей ячейке работает.
- [ ] 3.2 Copy в заполненный день: Add добавляет, Replace после подтверждения заменяет; отметки выполнения не копируются; дублей тренировок нет.
- [ ] 3.3 Repeat weekly до даты — создаются нужные дни, занятые пропускаются.

**4. Today — основной цикл**
- [ ] 4.1 Сегодняшняя тренировка: один тап по любой части строки сета отмечает выполнение, повторный тап снимает.
- [ ] 4.2 Долгое нажатие → редактор плана/факта; изменения сохраняются.
- [ ] 4.3 Пропустить упражнение через `⋯` и вернуть его.
- [ ] 4.4 Отметить все сеты → экран завершения; закрыть его.

**5. История**
- [ ] 5.1 Прошлый день в Program: тап по любой части выполненного сета открывает редактор факта; правка сохраняется.

**6. Settings**
- [ ] 6.1 Профиль: пол, дата рождения, рост → BMI появляется.
- [ ] 6.2 Вес тела: добавить, открыть запись тапом по любой части строки, изменить (остаётся одна запись), удалить → BMI исчезает, если веса нет.
- [ ] 6.3 kg ↔ lb: значения в Today/Program/Settings пересчитываются.
- [ ] 6.4 Тема System / Light / Dark, в том числе при открытом sheet: без мигания таб-бара и фона.

**7. Офлайн и восстановление (главный сценарий зала)**
- [ ] 7.1 Включить авиарежим. Отметить сеты в Today, изменить план в Program, добавить вес тела.
- [ ] 7.2 Заблокировать экран на минуту, разблокировать — изменения на месте.
- [ ] 7.3 Принудительно закрыть приложение (свайп из переключателя), открыть офлайн — изменения на месте.
- [ ] 7.4 Выключить авиарежим, подождать синхронизацию. **Не должно быть** баннеров «needs review» / «wasn’t saved».
- [ ] 7.5 Открыть приложение ещё раз — баннеров по-прежнему нет, данные совпадают.

**8. Аккаунты**
- [ ] 8.1 Logout → вход аккаунтом B: данных A не видно. Изменения B сохраняются.
- [ ] 8.2 Logout → снова A: данные A на месте.

## Product-acceptance gate

After the free matrix passes and the final CI is green, install the exact free candidate on the user's iPhone. The user then decides subjectively whether functionality and UX are acceptable. Only after that decision may paid Apple/Firebase work be proposed or activated.
