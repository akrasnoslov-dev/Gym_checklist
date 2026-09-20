const workout = [
  {
    name: "Bench Press",
    sets: [
      { value: "8 reps × 60 kg", completed: true },
      { value: "8 reps × 60 kg", completed: true },
      { value: "6 reps × 60 kg", completed: false }
    ]
  },
  {
    name: "Barbell Row",
    sets: [
      { value: "10 reps × 50 kg", completed: true },
      { value: "10 reps × 50 kg", completed: false }
    ]
  },
  {
    name: "Cable Face Pull",
    sets: [
      { value: "12 reps × 26 kg", completed: false },
      { value: "12 reps × 26 kg", completed: false }
    ]
  }
];

const workoutList = document.querySelector("#workout");
const groupTemplate = document.querySelector("#exercise-group-template");
const rowTemplate = document.querySelector("#set-row-template");

function renderWorkout() {
  workoutList.replaceChildren();

  workout.forEach((exercise) => {
    const group = groupTemplate.content.cloneNode(true);
    const title = group.querySelector("h3");
    const list = group.querySelector(".set-list");
    title.textContent = exercise.name;
    group.querySelector(".overflow-button").setAttribute("aria-label", `${exercise.name} actions`);

    exercise.sets.forEach((set, index) => {
      const row = rowTemplate.content.cloneNode(true);
      const button = row.querySelector(".set-row");
      button.querySelector(".set-value").textContent = set.value;
      button.dataset.description = `${exercise.name}, set ${index + 1}: ${set.value}`;
      setRowState(button, set.completed);
      button.addEventListener("click", () => {
        set.completed = !set.completed;
        setRowState(button, set.completed);
      });
      list.append(row);
    });

    workoutList.append(group);
  });
}

function setRowState(row, completed) {
  row.classList.toggle("is-completed", completed);
  row.setAttribute("aria-pressed", String(completed));
  row.setAttribute("aria-label", `${row.dataset.description}, ${completed ? "completed" : "incomplete"}`);
  row.setAttribute("aria-description", completed ? "Completed. Tap to undo." : "Incomplete. Tap to complete.");
}

document.querySelectorAll("[data-theme-choice]").forEach((button) => {
  button.addEventListener("click", () => {
    const theme = button.dataset.themeChoice;
    document.documentElement.dataset.theme = theme;
    document.querySelectorAll("[data-theme-choice]").forEach((choice) => {
      choice.setAttribute("aria-pressed", String(choice === button));
    });
  });
});

document.querySelectorAll("[data-variant-choice]").forEach((button) => {
  button.addEventListener("click", () => {
    const variant = button.dataset.variantChoice;
    document.documentElement.dataset.variant = variant;
    document.querySelectorAll("[data-variant-choice]").forEach((choice) => {
      choice.setAttribute("aria-pressed", String(choice === button));
    });
  });
});

renderWorkout();
