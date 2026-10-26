(function () {
  const { THEMES, SIZES, WIDGETS } = window.MacdotBoard;

  const params = new URLSearchParams(location.search);
  const shot = params.get("shot") || "";
  const state = {
    widget: params.get("widget") || "clock",
    size: params.get("size") || "large",
    theme: params.get("theme") || "midnight",
    hours: params.get("hours") === "12" ? "12" : "24",
    message: params.get("message") || "MAKE SOMETHING GOOD",
    paused: params.get("pause") === "1" || Boolean(shot),
    midflip: params.get("midflip") === "1" || shot === "flip",
    shift: 0
  };

  if (!WIDGETS[state.widget]) state.widget = "clock";
  if (!THEMES[state.theme]) state.theme = "midnight";

  const fixedNow = params.get("now");
  const baseNow = fixedNow
    ? new Date(fixedNow)
    : shot
      ? new Date("2026-10-26T09:41:00")
      : new Date();

  const board = window.MacdotBoard.create({ hours: state.hours, message: state.message });

  function displayDate() {
    return new Date(baseNow.getTime() + state.shift * 60000);
  }

  function stageExtra() {
    if (state.widget === "clock") return { city: { name: "London", code: "LON", tz: "Europe/London" }, zone: "Europe/London" };
    if (state.widget === "world") return { zone: "UTC" };
    return { zone: "UTC", span: "year" };
  }

  function choices(host, items, current, onPick) {
    host.replaceChildren();
    items.forEach((item) => {
      const button = document.createElement("button");
      button.type = "button";
      button.dataset.value = item.id;
      button.setAttribute("aria-pressed", item.id === current ? "true" : "false");
      if (item.dot) {
        const dot = document.createElement("i");
        dot.className = "swatch";
        dot.style.background = item.dot;
        button.append(dot);
      }
      button.append(document.createTextNode(item.title));
      button.addEventListener("click", () => onPick(item.id));
      host.append(button);
    });
  }

  function renderControls() {
    choices(document.getElementById("widget-choices"), Object.entries(WIDGETS).map(([id, widget]) => ({ id, title: widget.title })), state.widget, (id) => {
      state.widget = id;
      if (!WIDGETS[id].sizes.includes(state.size)) {
        state.size = WIDGETS[id].sizes.includes("medium") ? "medium" : WIDGETS[id].sizes[0];
      }
      renderControls();
      renderStage(false);
    });
    choices(document.getElementById("size-choices"), WIDGETS[state.widget].sizes.map((id) => ({ id, title: SIZES[id].title })), state.size, (id) => {
      state.size = id;
      renderControls();
      renderStage(false);
    });
    choices(document.getElementById("theme-choices"), Object.entries(THEMES).map(([id, theme]) => ({ id, title: theme.title, dot: theme.on })), state.theme, (id) => {
      state.theme = id;
      renderControls();
      renderStage(false);
    });
    choices(document.getElementById("hour-choices"), [{ id: "24", title: "24-hour" }, { id: "12", title: "12-hour" }], state.hours, (id) => {
      state.hours = id;
      board.hours = id;
      renderControls();
      renderStage(true);
      renderDesk(false);
    });
  }

  let stageFigure = null;

  function renderStage(animate) {
    const host = document.getElementById("stage");
    if (!host) return;
    host.className = "stage-card";
    if (!stageFigure || stageFigure.dataset.widget !== state.widget || stageFigure.dataset.size !== state.size || stageFigure.dataset.theme !== state.theme) {
      const built = board.figure({
        widget: state.widget,
        size: state.size,
        theme: state.theme,
        extra: stageExtra()
      });
      stageFigure = built.el;
      stageFigure.dataset.widget = state.widget;
      stageFigure.dataset.size = state.size;
      stageFigure.dataset.theme = state.theme;
      stageFigure._paint = built.paint;
      stageFigure._hold = built.hold;
      host.replaceChildren(stageFigure);
    }
    const label = stageFigure._paint(displayDate(), animate && !state.midflip);
    if (state.midflip) stageFigure._hold(displayDate());
    const caption = document.getElementById("caption");
    if (caption) caption.textContent = label || "";
  }

  function renderDesk() {
    const desk = document.getElementById("desk");
    if (!desk) return;
    const date = shot ? new Date("2026-10-26T09:41:00") : displayDate();
    const cards = [
      ["clock", "large", "midnight", { city: { name: "London", code: "LON", tz: "Europe/London" }, zone: "Europe/London" }],
      ["world", "medium", "amber", { zone: "UTC" }],
      ["day", "medium", "phosphor", { zone: "UTC" }],
      ["countdown", "small", "matcha", { zone: "UTC" }],
      ["progress", "medium", "paper", { zone: "UTC", span: "year" }],
      ["sign", "medium", "sky", { zone: "UTC" }]
    ];
    desk.replaceChildren();
    cards.forEach(([widget, size, theme, extra]) => {
      const built = board.figure({ widget, size, theme, extra });
      desk.append(built.el);
      built.paint(date, false);
    });
  }

  function renderThemes() {
    const host = document.getElementById("themes");
    if (!host) return;
    host.replaceChildren();
    const date = shot ? new Date("2026-10-26T09:41:00") : displayDate();
    Object.keys(THEMES).forEach((theme) => {
      const built = board.figure({
        widget: "clock",
        size: "small",
        theme,
        extra: {
          city: { name: "London", code: "LON", tz: "Europe/London" },
          zone: "Europe/London"
        }
      });
      host.append(built.el);
      built.paint(date, false);
    });
  }

  function applyShotChrome() {
    if (!shot) return;
    document.body.classList.add("shot-" + (shot === "flip" ? "flip" : shot));
    if (shot === "clock" || shot === "flip") {
      state.widget = "clock";
      state.size = "large";
      state.theme = shot === "flip" ? "amber" : "midnight";
    }
    if (shot === "world") {
      state.widget = "world";
      state.size = "large";
      state.theme = "amber";
    }
  }

  applyShotChrome();
  renderControls();
  renderStage(false);
  renderDesk();
  renderThemes();

  const message = document.getElementById("message");
  if (message) {
    message.value = state.message;
    message.addEventListener("input", () => {
      state.message = message.value;
      board.message = message.value;
      if (state.widget === "sign" || state.widget === "countdown") renderStage(true);
      renderDesk();
    });
  }
  document.getElementById("pause").addEventListener("click", () => {
    state.paused = !state.paused;
    document.getElementById("pause").textContent = state.paused ? "Play" : "Pause";
  });
  document.getElementById("step").addEventListener("click", () => {
    state.shift += 1;
    renderStage(true);
  });

  setInterval(() => {
    if (state.paused || shot) return;
    state.shift += 1;
    renderStage(true);
  }, 2800);
})();
