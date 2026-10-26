/* Shared dot-matrix board renderer used by WebPreview and the landing site.
   The desktop widgets fade with SwiftUI's opacity content transition.
   This renderer turns a cell in 3D when its character changes. */
(function (global) {
  const THEMES = {
    midnight: { title: "Midnight", background: "#141414", flap: "#1c1c1c", on: "#f4f1ea", off: "rgba(244,241,234,0.07)", glow: "rgba(255,248,230,0.55)", glows: true },
    obsidian: { title: "Obsidian", background: "#000000", flap: "#070707", on: "#f2f2f2", off: "rgba(255,255,255,0.05)", glow: "rgba(180,200,255,0.38)", glows: true },
    paper: { title: "Paper", background: "#f3efe6", flap: "#e7e1d4", on: "#2a261f", off: "rgba(42,38,31,0.10)", glow: "transparent", glows: false },
    matcha: { title: "Matcha", background: "#d7e4d4", flap: "#c9d9c6", on: "#1e3a24", off: "rgba(30,58,36,0.12)", glow: "transparent", glows: false },
    lemon: { title: "Lemon", background: "#f6efc4", flap: "#efe6ae", on: "#3d3412", off: "rgba(61,52,18,0.12)", glow: "transparent", glows: false },
    sky: { title: "Sky", background: "#d5e4f2", flap: "#c5d8ea", on: "#16324d", off: "rgba(22,50,77,0.12)", glow: "transparent", glows: false },
    amber: { title: "Amber", background: "#140e08", flap: "#1c140c", on: "#ffb03a", off: "rgba(255,176,58,0.09)", glow: "rgba(255,150,30,0.62)", glows: true },
    phosphor: { title: "Phosphor", background: "#07110c", flap: "#0c1a12", on: "#9dff6a", off: "rgba(157,255,106,0.08)", glow: "rgba(80,255,70,0.55)", glows: true }
  };

  const SIZES = {
    small: { title: "Small", w: 164, h: 164 },
    medium: { title: "Medium", w: 344, h: 164 },
    large: { title: "Large", w: 344, h: 344 },
    extraLarge: { title: "Extra Large", w: 724, h: 344 }
  };

  const WIDGETS = {
    world: { title: "World Board", sizes: ["medium", "large", "extraLarge"] },
    clock: { title: "Clock", sizes: ["small", "medium", "large"] },
    day: { title: "Day", sizes: ["small", "medium", "large"] },
    progress: { title: "Progress", sizes: ["small", "medium", "large"] },
    countdown: { title: "Countdown", sizes: ["small", "medium", "large"] },
    sign: { title: "Sign", sizes: ["small", "medium", "large", "extraLarge"] }
  };

  /* Sample used by the browser preview. The Mac app catalog has 68 cities plus This Mac. */
  const CITIES = [
    { name: "New York", code: "NYC", tz: "America/New_York" },
    { name: "London", code: "LON", tz: "Europe/London" },
    { name: "Tokyo", code: "TYO", tz: "Asia/Tokyo" },
    { name: "Sydney", code: "SYD", tz: "Australia/Sydney" },
    { name: "Los Angeles", code: "LAX", tz: "America/Los_Angeles" },
    { name: "Paris", code: "PAR", tz: "Europe/Paris" },
    { name: "Singapore", code: "SIN", tz: "Asia/Singapore" },
    { name: "Dubai", code: "DXB", tz: "Asia/Dubai" }
  ];

  const WEEKDAYS = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
  const WEEKDAY_NAMES = ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"];
  const MONTHS = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];

  function font() {
    return global.DOT_FONT || {};
  }

  function create(initial) {
    const session = {
      hours: initial && initial.hours === "12" ? "12" : "24",
      message: (initial && initial.message) || "MAKE SOMETHING GOOD"
    };

    function sanitize(text) {
      const folded = String(text || "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toUpperCase();
      const glyphs = font();
      return Array.from(folded).map((ch) => (glyphs[ch] ? ch : " ")).join("");
    }

    function zoned(date, timeZone) {
      const fmt = new Intl.DateTimeFormat("en-US", {
        timeZone,
        hourCycle: "h23",
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
        hour: "2-digit",
        minute: "2-digit",
        weekday: "short"
      });
      const bag = {};
      for (const part of fmt.formatToParts(date)) bag[part.type] = part.value;
      const weekday = bag.weekday.toUpperCase().slice(0, 3);
      return {
        year: Number(bag.year),
        month: Number(bag.month),
        day: Number(bag.day),
        hour: Number(bag.hour),
        minute: Number(bag.minute),
        weekday,
        weekdayIndex: WEEKDAYS.indexOf(weekday)
      };
    }

    function timeText(parts, compact) {
      if (session.hours === "24") return String(parts.hour).padStart(2, "0") + ":" + String(parts.minute).padStart(2, "0");
      const hour = parts.hour % 12 === 0 ? 12 : parts.hour % 12;
      const mark = parts.hour < 12 ? "A" : "P";
      const hh = String(hour).padStart(2, "0");
      const mm = String(parts.minute).padStart(2, "0");
      return compact ? hh + ":" + mm + mark : hh + ":" + mm + " " + mark + "M";
    }

    function pair(label, time, width) {
      let name = sanitize(label).trim().replace(/\s+/g, " ");
      const clock = sanitize(time);
      const room = Math.max(1, width - clock.length - 1);
      if (name.length > room) name = name.slice(0, room).trim();
      const gap = Math.max(1, width - name.length - clock.length);
      return name + " ".repeat(gap) + clock;
    }

    function trim(text, max) {
      const clean = sanitize(text).trim();
      return clean.length <= max ? clean : clean.slice(0, max).trim();
    }

    function dayOfYear(parts) {
      const start = Date.UTC(parts.year, 0, 1);
      const current = Date.UTC(parts.year, parts.month - 1, parts.day);
      return Math.floor((current - start) / 86400000) + 1;
    }

    function isLeap(year) {
      return (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0;
    }

    function daysInMonth(year, month) {
      return new Date(Date.UTC(year, month, 0)).getUTCDate();
    }

    function spanStats(span, parts) {
      if (span === "day") {
        const mins = parts.hour * 60 + parts.minute;
        const left = 24 * 60 - mins;
        const text = Math.floor(left / 60) + "H " + String(left % 60).padStart(2, "0") + "M LEFT";
        return { fraction: mins / (24 * 60), short: text, long: text };
      }
      if (span === "week") {
        const index = Math.max(0, parts.weekdayIndex);
        const fraction = (index + (parts.hour * 60 + parts.minute) / 1440) / 7;
        const days = Math.max(0, 6 - index);
        return { fraction, short: days + "D LEFT", long: days + (days === 1 ? " DAY LEFT" : " DAYS LEFT") };
      }
      if (span === "month") {
        const total = daysInMonth(parts.year, parts.month);
        const fraction = (parts.day - 1 + (parts.hour * 60 + parts.minute) / 1440) / total;
        const days = Math.max(0, total - parts.day);
        return { fraction, short: days + "D LEFT", long: days + (days === 1 ? " DAY LEFT" : " DAYS LEFT") };
      }
      const total = isLeap(parts.year) ? 366 : 365;
      const doy = dayOfYear(parts);
      const fraction = (doy - 1 + (parts.hour * 60 + parts.minute) / 1440) / total;
      const days = Math.max(0, total - doy);
      return { fraction, short: days + "D LEFT", long: days + " DAYS LEFT" };
    }

    function isoWeek(parts) {
      const date = new Date(Date.UTC(parts.year, parts.month - 1, parts.day));
      const dayNum = date.getUTCDay() || 7;
      date.setUTCDate(date.getUTCDate() + 4 - dayNum);
      const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
      return Math.ceil(((date - yearStart) / 86400000 + 1) / 7);
    }

    function compose(widget, size, date, extra) {
      const zone = (extra && extra.zone) || "UTC";
      const parts = zoned(date, zone);
      if (widget === "world") {
        const limit = size === "large" ? 8 : size === "extraLarge" ? 7 : 4;
        const width = size === "large" ? 14 : size === "extraLarge" ? 16 : 12;
        const useCode = size === "medium" || size === "small";
        const lines = CITIES.slice(0, limit).map((city) => {
          const cityParts = zoned(date, city.tz);
          const label = useCode ? city.code : city.name;
          return { text: pair(label, timeText(cityParts, true), width), weight: 1 };
        });
        const label = CITIES.slice(0, limit).map((city) => city.name + " " + timeText(zoned(date, city.tz), true)).join(", ");
        return { lines, progress: null, label };
      }
      if (widget === "clock") {
        const city = (extra && extra.city) || { name: "UTC", code: "UTC", tz: zone };
        const cityParts = zoned(date, city.tz);
        const lines = [
          { text: sanitize(size === "small" ? city.code : city.name), weight: size === "large" ? 0.42 : 0.48 },
          { text: timeText(cityParts, size === "small"), weight: size === "small" ? 0.92 : 1.15 },
          { text: (size === "small" ? "" : cityParts.weekday + " ") + MONTHS[cityParts.month - 1] + " " + cityParts.day, weight: 0.4 }
        ];
        const stats = spanStats("day", cityParts);
        return {
          lines,
          progress: size === "large" ? stats.fraction : null,
          label: city.name + " " + timeText(cityParts, false)
        };
      }
      if (widget === "day") {
        const month = MONTHS[parts.month - 1];
        if (size === "small") {
          return {
            lines: [
              { text: parts.weekday, weight: 0.7 },
              { text: month, weight: 0.55 },
              { text: String(parts.day).padStart(2, "0"), weight: 1.05 }
            ],
            progress: null,
            label: WEEKDAY_NAMES[parts.weekdayIndex] + " " + month + " " + parts.day
          };
        }
        if (size === "large") {
          const week = isoWeek(parts);
          const doy = dayOfYear(parts);
          return {
            lines: [
              { text: WEEKDAY_NAMES[parts.weekdayIndex], weight: 0.55 },
              { text: parts.day + " " + month, weight: 1 },
              { text: String(parts.year), weight: 0.42 },
              { text: "W" + String(week).padStart(2, "0") + "  DAY " + doy, weight: 0.36 }
            ],
            progress: spanStats("day", parts).fraction,
            label: WEEKDAY_NAMES[parts.weekdayIndex] + " " + month + " " + parts.day + ", week " + week
          };
        }
        return {
          lines: [
            { text: WEEKDAY_NAMES[parts.weekdayIndex], weight: 0.62 },
            { text: parts.day + " " + month, weight: 0.95 }
          ],
          progress: spanStats("day", parts).fraction,
          label: WEEKDAY_NAMES[parts.weekdayIndex] + " " + month + " " + parts.day
        };
      }
      if (widget === "progress") {
        const span = (extra && extra.span) || "year";
        const stats = spanStats(span, parts);
        const percent = Math.round(stats.fraction * 100) + "%";
        const name = span.toUpperCase();
        if (size === "small") {
          return { lines: [{ text: name, weight: 0.5 }, { text: percent, weight: 1.05 }], progress: stats.fraction, label: name + " " + percent };
        }
        if (size === "large") {
          return {
            lines: [
              { text: name, weight: 0.48 },
              { text: percent, weight: 1.2 },
              { text: stats.long, weight: 0.4 }
            ],
            progress: stats.fraction,
            label: name + " " + percent + ", " + stats.long
          };
        }
        return {
          lines: [
            { text: pair(name, percent, 12), weight: 0.72 },
            { text: stats.short, weight: 0.42 }
          ],
          progress: stats.fraction,
          label: name + " " + percent
        };
      }
      if (widget === "countdown") {
        const target = (extra && extra.target) || new Date("2027-01-01T00:00:00");
        const remaining = target - date;
        const custom = extra && extra.useMessage ? session.message : "";
        const titleSource = custom && String(custom).trim() ? custom : "NEW YEAR";
        const title = trim(titleSource, size === "small" ? 8 : size === "large" ? 12 : 16);
        if (remaining <= 0) {
          return { lines: [{ text: title, weight: 0.5 }, { text: "NOW", weight: 1.2 }], progress: null, label: title + " is now" };
        }
        const minutes = Math.floor(remaining / 60000);
        const days = Math.floor(minutes / (60 * 24));
        const hours = Math.floor(minutes / 60) % 24;
        const mins = minutes % 60;
        if (days >= 1) {
          const lines = [
            { text: title, weight: 0.48 },
            { text: String(days), weight: size === "small" ? 1.05 : 1.25 },
            { text: days === 1 ? "DAY" : "DAYS", weight: 0.45 }
          ];
          if (size !== "small") lines.push({ text: String(days).padStart(2, "0") + "D " + String(hours).padStart(2, "0") + "H " + String(mins).padStart(2, "0") + "M", weight: 0.36 });
          return { lines, progress: null, label: title + ", " + days + " days" };
        }
        const lines = [
          { text: title, weight: 0.48 },
          { text: String(hours).padStart(2, "0") + ":" + String(mins).padStart(2, "0"), weight: 1.05 }
        ];
        lines.push(size === "small"
          ? { text: "LEFT", weight: 0.42 }
          : { text: String(hours).padStart(2, "0") + "H " + String(mins).padStart(2, "0") + "M", weight: 0.4 });
        return { lines, progress: null, label: title + ", " + hours + " hours " + mins + " minutes" };
      }
      return { lines: [], fitMessage: session.message || "HELLO", progress: null, label: session.message || "HELLO" };
    }

    function wrap(text, columns) {
      const width = Math.max(1, columns);
      const lines = [];
      let current = "";
      for (const word of text.split(/\s+/).filter(Boolean)) {
        const pieces = [];
        let rest = word;
        while (rest.length > width) {
          pieces.push(rest.slice(0, width));
          rest = rest.slice(width);
        }
        pieces.push(rest);
        for (const piece of pieces) {
          if (!current) current = piece;
          else if (current.length + 1 + piece.length <= width) current += " " + piece;
          else {
            lines.push(current);
            current = piece;
          }
        }
      }
      if (current) lines.push(current);
      return lines.length ? lines : [" "];
    }

    function unitSize(lines, hasBar) {
      let width = 1;
      let height = 0;
      lines.forEach((line, index) => {
        const count = Math.max(line.text.length, 1);
        width = Math.max(width, count * 5 * line.weight + Math.max(count - 1, 0) * 0.75 * line.weight);
        if (index) height += 1.25;
        height += 7 * line.weight;
      });
      if (hasBar) height += 2.55;
      return { width: Math.max(width, 1), height: Math.max(height, 1) };
    }

    function resolvedLines(model, width, height) {
      if (!model.fitMessage) return model.lines;
      const source = sanitize(model.fitMessage).trim() || "HELLO";
      const pad = Math.min(width, height) * 0.075;
      const usableW = Math.max(width - pad * 2, 1);
      const usableH = Math.max(height - pad * 2, 1);
      let best = [source];
      let bestPitch = -1;
      const upper = Math.min(28, Math.max(4, source.length));
      for (let columns = 4; columns <= Math.max(4, upper); columns += 1) {
        const wrapped = wrap(source, columns);
        if (wrapped.length > 8) continue;
        const lines = wrapped.map((text) => ({ text, weight: 1 }));
        const units = unitSize(lines, false);
        const pitch = Math.min(usableW / units.width, usableH / units.height);
        if (pitch > bestPitch) {
          bestPitch = pitch;
          best = wrapped;
        }
      }
      return best.map((text) => ({ text, weight: 1 }));
    }

    function drawGlyph(canvas, ch, pitch, theme) {
      const dpr = Math.min(global.devicePixelRatio || 1, 2);
      const glyphs = font();
      const w = pitch * 5;
      const h = pitch * 7;
      canvas.width = Math.max(1, Math.ceil(w * dpr));
      canvas.height = Math.max(1, Math.ceil(h * dpr));
      canvas.style.width = w + "px";
      canvas.style.height = h + "px";
      const ctx = canvas.getContext("2d");
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      ctx.clearRect(0, 0, w, h);
      const rows = glyphs[ch] || glyphs[" "];
      const dot = pitch * 0.72;
      for (let row = 0; row < 7; row += 1) {
        const bits = rows[row];
        for (let col = 0; col < 5; col += 1) {
          const on = bits[col] === "1";
          const x = col * pitch + (pitch - dot) / 2 + dot / 2;
          const y = row * pitch + (pitch - dot) / 2 + dot / 2;
          if (on && theme.glows) {
            ctx.fillStyle = theme.glow;
            ctx.beginPath();
            ctx.arc(x, y, dot * 0.78, 0, Math.PI * 2);
            ctx.fill();
          }
          ctx.fillStyle = on ? theme.on : theme.off;
          ctx.beginPath();
          ctx.arc(x, y, dot / 2, 0, Math.PI * 2);
          ctx.fill();
        }
      }
    }

    function makeFlap(ch, pitch, theme) {
      const flap = document.createElement("div");
      flap.className = "flap";
      flap.style.width = pitch * 5 + "px";
      flap.style.height = pitch * 7 + "px";
      flap.style.background = theme.flap;
      flap.style.borderRadius = Math.max(1, pitch * 0.18) + "px";
      const canvas = document.createElement("canvas");
      flap.append(canvas);
      flap.dataset.char = ch;
      drawGlyph(canvas, ch, pitch, theme);
      return flap;
    }

    function setFlapChar(flap, ch, pitch, theme, animate) {
      if (flap.dataset.char === ch) return;
      const canvas = flap.querySelector("canvas");
      const apply = () => {
        flap.dataset.char = ch;
        drawGlyph(canvas, ch, pitch, theme);
      };
      if (!animate || global.matchMedia("(prefers-reduced-motion: reduce)").matches) {
        apply();
        return;
      }
      clearTimeout(flap._timer);
      flap.classList.add("turning");
      flap._timer = setTimeout(() => {
        apply();
        flap.classList.remove("turning");
      }, 180);
    }

    function syncBoard(host, model, theme, themeName, animate) {
      const frame = host.parentElement;
      const width = host.clientWidth || (frame ? parseFloat(frame.style.width) : 0);
      const height = host.clientHeight || (frame ? parseFloat(frame.style.height) : 0);
      if (width < 2 || height < 2) return null;
      const lines = resolvedLines(model, width, height);
      const signature = themeName + "|" + width + "x" + height + "|" + lines.map((line) => line.weight + ":" + line.text.length).join(",") + "|" + (model.progress == null ? "-" : "bar");
      const canUpdate = host.dataset.signature === signature && host.querySelector(".line");
      if (!canUpdate) {
        host.dataset.signature = signature;
        host.style.background = theme.background;
        host.setAttribute("role", "img");
        host.setAttribute("aria-label", model.label || "Mac Flip board");
        host.replaceChildren();
        const inner = document.createElement("div");
        inner.className = "board-inner";
        const units = unitSize(lines, model.progress != null);
        const pad = Math.min(width, height) * 0.075;
        const pitch = Math.max(1.1, Math.min((width - pad * 2) / units.width, (height - pad * 2) / units.height));
        inner.style.gap = pitch * 1.25 + "px";
        lines.forEach((line) => {
          const row = document.createElement("div");
          row.className = "line";
          const glyphPitch = pitch * line.weight;
          row.style.gap = glyphPitch * 0.75 + "px";
          Array.from(line.text).forEach((ch) => row.append(makeFlap(ch, glyphPitch, theme)));
          inner.append(row);
        });
        if (model.progress != null) {
          const count = Math.max(8, Math.min(40, Math.floor((width - pad * 2) / (pitch * 1.2))));
          const lit = Math.round(Math.min(1, Math.max(0, model.progress)) * count);
          const bar = document.createElement("div");
          bar.className = "bar";
          bar.style.gap = pitch * 0.85 * 0.42 + "px";
          const dot = pitch * 0.85 * 0.72;
          for (let index = 0; index < count; index += 1) {
            const mark = document.createElement("i");
            mark.style.width = dot + "px";
            mark.style.height = dot + "px";
            mark.style.borderRadius = "50%";
            mark.style.background = index < lit ? theme.on : theme.off;
            if (theme.glows && index < lit) mark.style.boxShadow = "0 0 " + dot * 0.6 + "px " + theme.glow;
            bar.append(mark);
          }
          inner.append(bar);
        }
        host.append(inner);
        return model.label;
      }
      const rows = host.querySelectorAll(".line");
      lines.forEach((line, index) => {
        const flaps = rows[index].querySelectorAll(".flap");
        const glyphPitch = flaps[0] ? flaps[0].offsetWidth / 5 : 4;
        Array.from(line.text).forEach((ch, charIndex) => {
          if (flaps[charIndex]) setFlapChar(flaps[charIndex], ch, glyphPitch, theme, animate);
        });
      });
      host.setAttribute("aria-label", model.label || "Mac Flip board");
      return model.label;
    }

    function figure(spec) {
      const widget = spec.widget;
      const sizeName = spec.size;
      const themeName = spec.theme;
      const size = SIZES[sizeName];
      const theme = THEMES[themeName];
      const extra = spec.extra || {};
      const node = document.createElement("figure");
      node.className = "macflip-figure";
      const caption = document.createElement("figcaption");
      caption.textContent = WIDGETS[widget].title + " · " + theme.title;
      const frame = document.createElement("div");
      frame.className = "widget";
      frame.style.width = size.w + "px";
      frame.style.height = size.h + "px";
      const board = document.createElement("div");
      board.className = "board";
      frame.append(board);
      node.append(caption, frame);

      function paint(date, animate) {
        const model = compose(widget, sizeName, date, extra);
        syncBoard(board, model, theme, themeName, animate);
        return model.label;
      }

      function hold(date) {
        const previous = compose(widget, sizeName, new Date(date.getTime() - 60000), extra);
        const current = compose(widget, sizeName, date, extra);
        const rows = node.querySelectorAll(".line");
        current.lines.forEach((line, index) => {
          const old = (previous.lines[index] && previous.lines[index].text) || "";
          const flaps = rows[index] ? rows[index].querySelectorAll(".flap") : [];
          Array.from(line.text).forEach((ch, charIndex) => {
            if (old[charIndex] !== ch && flaps[charIndex]) flaps[charIndex].classList.add("turning");
          });
        });
      }

      return { el: node, paint, hold, frame, board };
    }

    return {
      get hours() { return session.hours; },
      set hours(value) { session.hours = value === "12" ? "12" : "24"; },
      get message() { return session.message; },
      set message(value) { session.message = value; },
      figure
    };
  }

  global.MacFlipBoard = { THEMES, SIZES, WIDGETS, CITIES, create };
})(window);
