(function () {
  const { THEMES, SIZES, WIDGETS } = window.MacdotBoard;
  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const london = { city: { name: "London", code: "LON", tz: "Europe/London" }, zone: "Europe/London" };

  const heroBoard = window.MacdotBoard.create({ message: "MAKE SOMETHING GOOD" });
  const tryBoard = window.MacdotBoard.create({ message: "MAKE SOMETHING GOOD" });
  const stillBoard = window.MacdotBoard.create({ message: "MAKE SOMETHING GOOD" });

  const heroStarted = new Date();
  const tryStarted = new Date();
  let heroShift = 0;
  let tryShift = 0;
  let heroPaused = reduced;
  let tryPaused = reduced;

  const tryState = {
    widget: "clock",
    size: "large",
    theme: "midnight"
  };

  function heroDate() {
    return new Date(heroStarted.getTime() + heroShift * 60000);
  }

  function tryDate() {
    return new Date(tryStarted.getTime() + tryShift * 60000);
  }

  function fit(mount) {
    const frame = mount.querySelector(".widget");
    const figure = mount.querySelector("figure");
    if (!frame || !figure) return;
    const naturalW = parseFloat(frame.style.width);
    const naturalH = parseFloat(frame.style.height);
    const available = mount.clientWidth;
    if (!naturalW || !available) return;
    const scale = Math.min(1, available / naturalW);
    if (scale === 1) {
      frame.style.position = "";
      frame.style.left = "";
      frame.style.top = "";
      frame.style.transform = "";
      figure.style.position = "";
      figure.style.width = "";
      figure.style.height = "";
      figure.style.overflow = "";
      return;
    }
    figure.style.position = "relative";
    figure.style.width = naturalW * scale + "px";
    figure.style.height = naturalH * scale + "px";
    figure.style.overflow = "hidden";
    frame.style.position = "absolute";
    frame.style.left = "0";
    frame.style.top = "0";
    frame.style.transformOrigin = "top left";
    frame.style.transform = "scale(" + scale + ")";
  }

  function fitAll() {
    document.querySelectorAll(".mount").forEach(fit);
  }

  const hero = heroBoard.figure({ widget: "clock", size: "large", theme: "amber", extra: london });
  const heroMount = document.getElementById("hero-mount");
  heroMount.append(hero.el);
  function paintHero(animate) {
    const label = hero.paint(heroDate(), animate);
    const caption = document.getElementById("hero-caption");
    if (caption) caption.textContent = label || "";
    fit(heroMount);
  }
  paintHero(false);

  document.getElementById("hero-pause").addEventListener("click", () => {
    heroPaused = !heroPaused;
    document.getElementById("hero-pause").textContent = heroPaused ? "Play" : "Pause";
  });
  document.getElementById("hero-step").addEventListener("click", () => {
    heroShift += 1;
    paintHero(true);
  });
  if (reduced) document.getElementById("hero-pause").textContent = "Play";

  let tryFigure = null;

  function renderChoices() {
    fillChoices(document.getElementById("widget-choices"), Object.entries(WIDGETS).map(([id, widget]) => ({
      id, title: widget.title
    })), tryState.widget, (id) => {
      tryState.widget = id;
      if (!WIDGETS[id].sizes.includes(tryState.size)) {
        tryState.size = WIDGETS[id].sizes.includes("medium") ? "medium" : WIDGETS[id].sizes[0];
      }
      renderChoices();
      renderTry(false);
    });
    fillChoices(document.getElementById("size-choices"), WIDGETS[tryState.widget].sizes.map((id) => ({
      id, title: SIZES[id].title
    })), tryState.size, (id) => {
      tryState.size = id;
      renderChoices();
      renderTry(false);
    });
    fillChoices(document.getElementById("theme-choices"), Object.entries(THEMES).map(([id, theme]) => ({
      id, title: theme.title, dot: theme.on
    })), tryState.theme, (id) => {
      tryState.theme = id;
      renderChoices();
      renderTry(false);
    });
  }

  function fillChoices(host, items, current, onPick) {
    host.replaceChildren();
    items.forEach((item) => {
      const button = document.createElement("button");
      button.type = "button";
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

  function tryExtra() {
    if (tryState.widget === "clock") return london;
    if (tryState.widget === "world") return { zone: "UTC" };
    if (tryState.widget === "countdown") return { zone: "UTC", useMessage: false };
    return { zone: "UTC", span: "year" };
  }

  function renderTry(animate) {
    const mount = document.getElementById("try-mount");
    if (!tryFigure || tryFigure.dataset.widget !== tryState.widget || tryFigure.dataset.size !== tryState.size || tryFigure.dataset.theme !== tryState.theme) {
      const built = tryBoard.figure({
        widget: tryState.widget,
        size: tryState.size,
        theme: tryState.theme,
        extra: tryExtra()
      });
      tryFigure = built.el;
      tryFigure.dataset.widget = tryState.widget;
      tryFigure.dataset.size = tryState.size;
      tryFigure.dataset.theme = tryState.theme;
      tryFigure._paint = built.paint;
      mount.replaceChildren(tryFigure);
    }
    const label = tryFigure._paint(tryDate(), animate);
    const caption = document.getElementById("try-caption");
    if (caption) caption.textContent = label || "";
    fit(mount);
  }

  renderChoices();
  renderTry(false);

  document.getElementById("message").addEventListener("input", (event) => {
    tryBoard.message = event.target.value;
    stillBoard.message = event.target.value;
    if (tryState.widget === "sign") renderTry(true);
    paintStill();
  });
  document.getElementById("try-pause").addEventListener("click", () => {
    tryPaused = !tryPaused;
    document.getElementById("try-pause").textContent = tryPaused ? "Play" : "Pause";
  });
  document.getElementById("try-step").addEventListener("click", () => {
    tryShift += 1;
    renderTry(true);
  });
  if (reduced) document.getElementById("try-pause").textContent = "Play";

  const blurbs = {
    world: {
      size: "medium",
      theme: "amber",
      extra: { zone: "UTC" },
      text: "The cities you list, in order, with the time beside each name. Medium uses three-letter codes for the first four. Large names the first eight. Extra large names the first seven.",
      sizes: "Medium, Large, Extra Large"
    },
    clock: {
      size: "medium",
      theme: "midnight",
      extra: london,
      text: "One city, the time, and the date. Large adds a bar for how much of that city’s day has passed. Small uses the city code so the time can stay large.",
      sizes: "Small, Medium, Large"
    },
    day: {
      size: "medium",
      theme: "phosphor",
      extra: { zone: "UTC" },
      text: "Weekday and date, plus how much of the day has passed. Large adds the year, the week number, and the day of the year.",
      sizes: "Small, Medium, Large"
    },
    progress: {
      size: "medium",
      theme: "paper",
      extra: { zone: "UTC", span: "year" },
      text: "Day, week, month, or year, as a percent, a row of dots, and the time left. The Mac app chooses the period. This preview shows the year.",
      sizes: "Small, Medium, Large"
    },
    countdown: {
      size: "medium",
      theme: "matcha",
      extra: { zone: "UTC" },
      text: "Days until a moment you name. On the last day it switches to hours and minutes. Once that moment has passed, the board reads NOW. The first launch uses a New Year countdown.",
      sizes: "Small, Medium, Large"
    },
    sign: {
      size: "medium",
      theme: "sky",
      extra: { zone: "UTC" },
      text: "Your message, wrapped so the dots are as large as they can be. Letters outside the 5×7 Latin uppercase set are left blank. The default message is MAKE SOMETHING GOOD.",
      sizes: "Small, Medium, Large, Extra Large"
    }
  };

  const grid = document.getElementById("widget-grid");
  const stills = [];
  Object.entries(WIDGETS).forEach(([id, widget]) => {
    const info = blurbs[id];
    const card = document.createElement("article");
    card.className = "widget-card";
    const title = document.createElement("h3");
    title.textContent = widget.title;
    const copy = document.createElement("p");
    copy.textContent = info.text;
    const meta = document.createElement("p");
    meta.className = "meta";
    meta.textContent = info.sizes;
    const mount = document.createElement("div");
    mount.className = "mount desk";
    const built = stillBoard.figure({ widget: id, size: info.size, theme: info.theme, extra: info.extra });
    mount.append(built.el);
    card.append(title, copy, meta, mount);
    grid.append(card);
    stills.push({ built, mount });
  });

  function paintStill() {
    const date = new Date();
    stills.forEach(({ built, mount }) => {
      built.paint(date, false);
      fit(mount);
    });
  }
  paintStill();

  const themeGrid = document.getElementById("theme-grid");
  Object.entries(THEMES).forEach(([id, theme]) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "theme-card";
    const name = document.createElement("strong");
    name.textContent = theme.title;
    const mount = document.createElement("div");
    mount.className = "mount";
    const built = stillBoard.figure({ widget: "clock", size: "small", theme: id, extra: london });
    mount.append(built.el);
    built.paint(new Date(), false);
    button.append(name, mount);
    button.addEventListener("click", () => {
      tryState.widget = "clock";
      tryState.size = "large";
      tryState.theme = id;
      renderChoices();
      renderTry(false);
      document.getElementById("try").scrollIntoView({ behavior: reduced ? "auto" : "smooth" });
    });
    themeGrid.append(button);
  });

  const buildMount = document.getElementById("build-mount");
  const sign = stillBoard.figure({
    widget: "sign",
    size: "medium",
    theme: "phosphor",
    extra: { zone: "UTC" }
  });
  stillBoard.message = "BUILD FROM SOURCE";
  buildMount.append(sign.el);
  sign.paint(new Date(), false);
  stillBoard.message = document.getElementById("message").value;
  fit(buildMount);

  window.addEventListener("resize", fitAll);
  requestAnimationFrame(fitAll);

  setInterval(() => {
    if (!heroPaused) {
      heroShift += 1;
      paintHero(true);
    }
    if (!tryPaused) {
      tryShift += 1;
      renderTry(true);
    }
  }, 2800);
})();
