if (!window.__wothless_damageui_loaded) {
  window.__wothless_damageui_loaded = true;
  window.damageDisplayMode = "always";

  const parts = {
    head: document.getElementById("head"),
    torso: document.getElementById("torso"),
    leftArm: document.getElementById("leftArm"),
    rightArm: document.getElementById("rightArm"),
    leftLeg: document.getElementById("leftLeg"),
    rightLeg: document.getElementById("rightLeg")
  };

  const injuries = {
    head: 0,
    torso: 0,
    leftArm: 0,
    rightArm: 0,
    leftLeg: 0,
    rightLeg: 0
  };

  function renderInjuries() {
    for (const part in parts) {
      const el = parts[part];
      if (!el) continue;

      el.classList.remove("injury-1", "injury-2", "injury-3");

      const level = injuries[part] || 0;
      if (level >= 1) el.classList.add("injury-1");
      if (level >= 2) el.classList.add("injury-2");
      if (level >= 3) el.classList.add("injury-3");
    }
  }

  function damagePart(part, amount = 1) {
    if (injuries[part] === undefined) return;
    injuries[part] = Math.min(3, injuries[part] + amount);
    renderInjuries();
    syncDamageUIVisibility();
  }

  function healAll() {
    for (const part in injuries) injuries[part] = 0;
    renderInjuries();
    syncDamageUIVisibility();
  }

  function isPlayerInjured() {
    return Object.values(injuries).some(level => level > 0);
  }

  function showMedicalProgress(ms) {
    const bar = document.getElementById("medical-progress");
    const fill = document.getElementById("medical-progress-fill");
    if (!bar || !fill) return;

    bar.style.display = "block";
    fill.style.width = "0%";

    let start = Date.now();
    const timer = setInterval(() => {
      const pct = Math.min(((Date.now() - start) / ms) * 100, 100);
      fill.style.width = pct + "%";

      if (pct >= 100) {
        clearInterval(timer);
        bar.style.display = "none";
      }
    }, 16);
  }

  const DAMAGE_FADE_MS = 350;

  function fadeInDamageUI() {
    const hud = document.getElementById("damage-hud");
    if (!hud) return;

    hud.style.display = "block";

    requestAnimationFrame(() => {
      hud.classList.add("visible");
      hud.setAttribute("aria-hidden", "false");
    });
  }

  function fadeOutDamageUI() {
    const hud = document.getElementById("damage-hud");
    if (!hud) return;

    hud.classList.remove("visible");
    hud.setAttribute("aria-hidden", "true");

    setTimeout(() => {
      if (!hud.classList.contains("visible")) {
        hud.style.display = "none";
      }
    }, DAMAGE_FADE_MS);
  }

  function syncDamageUIVisibility() {
    const hud = document.getElementById("damage-hud");
    if (!hud) return;

    const modeRaw = String(window.damageDisplayMode || "").toLowerCase().trim();
    const injured = isPlayerInjured();

    if (modeRaw === "injured" && !injured) {
      fadeOutDamageUI();
      return;
    }

    fadeInDamageUI();
  }

  function setHealVisible(state) {
    const c = document.getElementById("heal-container");
    if (!c) return;
    c.style.display = state ? "block" : "none";
  }

  function setHealProgress(progress01) {
    const fill = document.getElementById("heal-fill");
    const pct = document.getElementById("heal-percent");
    if (!fill || !pct) return;

    const percent = Math.max(0, Math.min(100, Math.floor(progress01 * 100)));
    fill.style.width = percent + "%";
    pct.innerText = percent + "%";
  }

  function showMedicalMenu(state) {
    const menu = document.getElementById("medical-menu");
    if (!menu) return;
    menu.style.display = state ? "block" : "none";
  }

  window.move = function(axis, value) {
    fetch(`https://${GetParentResourceName()}/updateDamageUI`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ axis, value })
    }).catch(() => {});
  };

  window.closeMenu = function() {
    fetch(`https://${GetParentResourceName()}/closeConfig`, {
      method: "POST"
    }).catch(() => {});
  };

  document.addEventListener("DOMContentLoaded", () => {
    const menu = document.getElementById("medical-menu");
    if (menu) {
      menu.querySelectorAll("button[data-part]").forEach(btn => {
        btn.addEventListener("click", () => {
          const part = btn.dataset.part;

          fetch(`https://${GetParentResourceName()}/healBodyPart`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ part })
          }).catch(() => {});
        });
      });

    const hud = document.getElementById("damage-hud");
    if (hud) {
      hud.style.display = "none";
      hud.classList.remove("visible");
      hud.setAttribute("aria-hidden", "true");
    }

    syncDamageUIVisibility();
  }
});

  window.setDisplayMode = function (mode) {
    window.damageDisplayMode = mode;
    syncDamageUIVisibility();

    fetch(`https://${GetParentResourceName()}/updateDamageUI`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ displayMode: mode })
    }).catch(() => {});
  };

  const colorPicker = document.getElementById("colorPicker");
  if (colorPicker) {
    colorPicker.addEventListener("input", (e) => {
      const rgb = hexToRgb(e.target.value);
      fetch(`https://${GetParentResourceName()}/updateDamageUI`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ color: rgb })
      }).catch(() => {});
    });
  }

  function hexToRgb(hex) {
    const bigint = parseInt(hex.replace("#", ""), 16);
    return {
      r: (bigint >> 16) & 255,
      g: (bigint >> 8) & 255,
      b: bigint & 255
    };
  }

  function rgbToHex(r, g, b) {
    return "#" + [r, g, b].map(x => x.toString(16).padStart(2, "0")).join("");
  }

  window.addEventListener("message", (event) => {
    const data = event.data;
    if (!data || !data.type) return;

    if (data.type === "damageShow") {
      syncDamageUIVisibility();
      return;
    }

    if (data.type === "damageHide") {
      const hud = document.getElementById("damage-hud");
      if (hud) fadeOutDamageUI();
      return;
    }

    if (data.type === "damage") {
      if (data.amount === 0) {
        injuries[data.part] = 0;
        renderInjuries();
        syncDamageUIVisibility();
        return;
      }

      if (data.amount < 0) {
        injuries[data.part] = Math.max(0, injuries[data.part] + data.amount);
        renderInjuries();
        syncDamageUIVisibility();
        return;
      }

      damagePart(data.part, data.amount || 1);
      return;
    }

    if (data.type === "heal") {
      healAll();
      return;
    }

    if (data.type === "healShow") {
      setHealVisible(true);
      return;
    }

    if (data.type === "healHide") {
      setHealVisible(false);
      setHealProgress(0);
      return;
    }

    if (data.type === "healProgress") {
      setHealVisible(true);
      setHealProgress(data.progress || 0);
      return;
    }

    if (data.type === "medicalProgress") {
      showMedicalProgress(data.duration || 2000);
      return;
    }

    if (data.type === "openMedicalMenu") {
      showMedicalMenu(true);
      return;
    }

    if (data.type === "closeMedicalMenu") {
      showMedicalMenu(false);
      return;
    }

    if (data.type === "toggleConfig") {
      if (data.settings && data.settings.displayMode) {
        window.damageDisplayMode = data.settings.displayMode;
        syncDamageUIVisibility();
      }

      const displaySelect = document.getElementById("displayMode");
      if (displaySelect && data.settings && data.settings.displayMode) {
        displaySelect.value = data.settings.displayMode;
      }

      const menu = document.getElementById("config");
      if (menu) menu.style.display = data.state ? "block" : "none";

      if (data.settings && data.settings.color) {
        const c = data.settings.color;
        const root = document.documentElement;
        root.style.setProperty("--inj-r", c.r);
        root.style.setProperty("--inj-g", c.g);
        root.style.setProperty("--inj-b", c.b);

        if (colorPicker) colorPicker.value = rgbToHex(c.r, c.g, c.b);

        if (typeof updateColorUI === "function") {
          updateColorUI(c.r, c.g, c.b);
        }
      }

      syncDamageUIVisibility();
      return;
    }

    if (data.type === "damageUpdate") {
      const hud = document.getElementById("damage-hud");
      if (hud && data.x !== undefined && data.y !== undefined) {
        hud.style.left = (data.x * 100) + "%";
        hud.style.top = (data.y * 100) + "%";
        hud.style.transform = "translate(-50%, -50%)";
      }

      if (data.displayMode) {
        window.damageDisplayMode = data.displayMode;
      }

      if (data.color) {
        const c = data.color;
        const root = document.documentElement;
        root.style.setProperty("--inj-r", c.r);
        root.style.setProperty("--inj-g", c.g);
        root.style.setProperty("--inj-b", c.b);
      }

      syncDamageUIVisibility();
      return;
    }
  });

  const rSlider = document.getElementById("rSlider");
  const gSlider = document.getElementById("gSlider");
  const bSlider = document.getElementById("bSlider");

  const rVal = document.getElementById("rVal");
  const gVal = document.getElementById("gVal");
  const bVal = document.getElementById("bVal");
  const preview = document.getElementById("colorPreview");

  function updateColorUI(r, g, b) {
    if (!rSlider || !gSlider || !bSlider || !rVal || !gVal || !bVal || !preview) return;

    rSlider.value = r;
    gSlider.value = g;
    bSlider.value = b;

    rVal.textContent = r;
    gVal.textContent = g;
    bVal.textContent = b;

    preview.style.background = `rgb(${r}, ${g}, ${b})`;

    fetch(`https://${GetParentResourceName()}/updateDamageUI`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ color: { r, g, b } })
    }).catch(() => {});
  }

  if (rSlider && gSlider && bSlider) {
    [rSlider, gSlider, bSlider].forEach(slider => {
      slider.addEventListener("input", () => {
        updateColorUI(
          parseInt(rSlider.value),
          parseInt(gSlider.value),
          parseInt(bSlider.value)
        );
      });
    });
  }

  window.resetDefaults = function () {
    fetch(`https://${GetParentResourceName()}/resetDamageUI`, {
      method: "POST",
      headers: { "Content-Type": "application/json" }
    }).catch(() => {});
  };

document.addEventListener("DOMContentLoaded", () => {
  const menu = document.getElementById("medical-menu");

  if (menu) {
    menu.querySelectorAll("button[data-part]").forEach(btn => {
      btn.addEventListener("click", () => {
        const part = btn.dataset.part;

        fetch(`https://${GetParentResourceName()}/healBodyPart`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ part })
        }).catch(() => {});
      });
    });

    const cancelBtn = menu.querySelector(".medical-close");
    if (cancelBtn) {
      cancelBtn.addEventListener("click", () => {
        menu.style.display = "none";

        fetch(`https://${GetParentResourceName()}/closeMedicalMenu`, {
          method: "POST"
        }).catch(() => {});
      });
    }
  }

  const hud = document.getElementById("damage-hud");
  if (hud) {
    hud.style.display = "none";
    hud.classList.remove("visible");
    hud.setAttribute("aria-hidden", "true");
  }

  syncDamageUIVisibility();
});
}
