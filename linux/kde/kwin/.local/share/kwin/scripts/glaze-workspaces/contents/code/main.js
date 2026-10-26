// GlazeWM-style workspaces for KWin (ported from glazewm/config.yaml).
//
// - Every desktop has a key: Meta+Alt+<key> goes there, Meta+Alt+Shift+<key>
//   moves the focused window there. Desktop names show the key, e.g. [T]erminal.
// - SLOTS are fixed: windows matching their rules always open there.
// - Any other app opens on its own desktop and gets the first free letter of
//   its name, e.g. Outlook -> [O]utlook. If none is free: "Steam [B]".
// - Empty desktops are removed once you leave them (except keepAlive slots),
//   so the panel bar only shows what's in use, like zebar.

const SLOTS = [
    // expand: new windows open expanded (Meta+Alt+Enter size)
    { key: "d", name: "Discord", keepAlive: true, expand: true, match: [{ cls: /^(discord|vesktop|webcord)$/i }] },
    { key: "e", name: "Explorer", expand: true, match: [{ cls: /firefox|chrom(e|ium)|brave|zen/i }] },
    { key: "t", name: "Terminal", keepAlive: true, expand: true, match: [{ cls: /wezterm/i }] },
];

// Letters taken by the window hotkeys below.
const RESERVED = "fhjklw";
const KEYS = "abcdefghijklmnopqrstuvwxyz".split("").filter((k) => !RESERVED.includes(k));

// Windows the script never touches.
const IGNORE = [
    { cls: /^(plasmashell|krunner|org\.kde\.spectacle|org\.kde\.polkit-kde-authentication-agent-1|xdg-desktop-portal-kde)$/i },
    { caption: /picture.in.picture/i },
];

// "Term" + "t" -> "[T]erm", "Misc" + "1" -> "[1] Misc", "Steam" + "b" -> "Steam [B]"
function label(name, key) {
    const K = key.toUpperCase();
    if (!name) return "[" + K + "]";
    const i = name.toLowerCase().indexOf(key);
    if (i >= 0) return name.slice(0, i) + "[" + name.charAt(i) + "]" + name.slice(i + 1);
    return /[0-9]/.test(key) ? "[" + K + "] " + name : name + " [" + K + "]";
}

SLOTS.forEach((s) => { s.label = label(s.name, s.key); });

// desktop id -> { key, slot? , app?: resourceClass, appName? }
const kinds = {};
let previousDesktop = null;

function log(msg) { print("glaze-workspaces: " + msg); }

function matches(w, rules) {
    return (rules || []).some((r) =>
        (!r.cls || r.cls.test(w.resourceClass || "")) &&
        (!r.caption || r.caption.test(w.caption || "")));
}

function managed(w) {
    return w && w.normalWindow && !w.transient && !w.skipTaskbar &&
        !w.specialWindow && !w.onAllDesktops && !matches(w, IGNORE);
}

function appName(cls) {
    const last = (cls || "app").split(".").pop();
    return last.charAt(0).toUpperCase() + last.slice(1);
}

function findDesktop(pred) {
    return workspace.desktops.find((d) => kinds[d.id] && pred(kinds[d.id])) || null;
}

function windowsOn(desktop, exclude) {
    return workspace.windowList().filter((w) =>
        w !== exclude && managed(w) && w.desktops.some((d) => d.id === desktop.id));
}

function keyInUse(k) {
    return SLOTS.some((s) => s.key === k) ||
        workspace.desktops.some((d) => kinds[d.id] && kinds[d.id].key === k);
}

// First free letter of the name, else any free letter.
function pickKey(name) {
    const fromName = name.toLowerCase().split("").filter((c) => c >= "a" && c <= "z");
    const letters = fromName.concat("abcdefghijklmnopqrstuvwxyz".split(""));
    return letters.find((c) => KEYS.includes(c) && !keyInUse(c)) || null;
}

// Slot desktops stay in config order; everything else goes after them.
function insertPosition(slot) {
    const order = slot ? SLOTS.indexOf(slot) : SLOTS.length;
    let pos = 0;
    workspace.desktops.forEach((d, i) => {
        const k = kinds[d.id];
        const o = k && k.slot ? SLOTS.indexOf(k.slot) : SLOTS.length;
        if (o <= order) pos = i + 1;
    });
    return pos;
}

function createDesktop(name, kind) {
    const pos = insertPosition(kind.slot);
    workspace.createDesktop(pos, name);
    const d = workspace.desktops[pos];
    kinds[d.id] = kind;
    return d;
}

function slotDesktop(slot) {
    return findDesktop((k) => k.slot === slot) ||
        createDesktop(slot.label, { key: slot.key, slot: slot });
}

function appDesktop(cls, w) {
    const name = appName(cls);
    const d = findDesktop((k) => k.app === cls || (!k.slot && !k.app && k.appName === name));
    if (d) {
        const k = kinds[d.id];
        k.app = cls;
        if (!k.key) {
            k.key = pickKey(name);
            d.name = k.key ? label(name, k.key) : name;
        }
        return d;
    }
    // On an empty, unclaimed workspace (e.g. [S] from Meta+Alt+S)? The app takes it
    // over and keeps its key: Steam opened on [S] becomes [S]team.
    const cur = workspace.currentDesktop;
    const ck = kinds[cur.id];
    if (ck && ck.key && !ck.slot && !ck.app && !ck.appName && windowsOn(cur, w).length === 0) {
        ck.app = cls;
        ck.appName = name;
        cur.name = label(name, ck.key);
        return cur;
    }
    const key = pickKey(name);
    return createDesktop(key ? label(name, key) : name, { key: key, app: cls, appName: name });
}

// Desktop for a key: the slot, the app that owns it, or a new empty one.
function keyDesktop(key) {
    const slot = SLOTS.find((s) => s.key === key);
    if (slot) return slotDesktop(slot);
    return findDesktop((k) => k.key === key) || createDesktop(label("", key), { key: key });
}

function cleanup(exclude) {
    const current = workspace.currentDesktop;
    const empty = workspace.desktops.filter((d) => {
        const k = kinds[d.id];
        return k && !(k.slot && k.slot.keepAlive) && d.id !== current.id &&
            windowsOn(d, exclude).length === 0;
    });
    empty.forEach((d) => {
        delete kinds[d.id];
        workspace.removeDesktop(d);
    });
}

function show(desktop, w) {
    workspace.currentDesktop = desktop;
    if (w) workspace.activeWindow = w;
}

// Where a window belongs according to the rules.
function targetFor(w) {
    const slot = SLOTS.find((s) => matches(w, s.match));
    return slot ? slotDesktop(slot) : appDesktop(w.resourceClass, w);
}

function place(w, follow) {
    if (!managed(w)) return;
    const target = targetFor(w);
    w.desktops = [target];
    if (follow) show(target, w);
}

function watch(w) {
    // Some apps (Godot, Rider) set their real title after opening. Re-check
    // while the window still sits on its own app desktop.
    w.captionChanged.connect(() => {
        const d = w.desktops[0];
        const k = d && kinds[d.id];
        if (!k || !k.app || !managed(w)) return;
        const slot = SLOTS.find((s) => matches(w, s.match));
        if (!slot) return;
        const follow = workspace.currentDesktop.id === d.id;
        place(w, follow);
        cleanup();
    });
    w.desktopsChanged.connect(() => cleanup());
    // No minimizing: there's no taskbar to get a window back from.
    w.minimizedChanged.connect(() => { if (w.minimized) w.minimized = false; });
}

// Title bars hidden by default (Meta+Alt+; toggles one window's).
const HIDE_TITLE_BARS = true;

workspace.windowAdded.connect((w) => {
    if (!managed(w)) return;
    if (HIDE_TITLE_BARS) w.noBorder = true;
    watch(w);
    place(w, true);
    const slot = SLOTS.find((s) => matches(w, s.match));
    if (slot && slot.expand) expandOnOpen(w);
    cleanup();
});

workspace.windowRemoved.connect((w) => cleanup(w));

workspace.currentDesktopChanged.connect((prev) => {
    if (prev) previousDesktop = prev;
    cleanup();
});

function moveToKey(key) {
    const w = workspace.activeWindow;
    if (!managed(w)) return;
    const d = keyDesktop(key);
    w.desktops = [d];
    show(d, w);
    cleanup();
}

KEYS.forEach((key) => {
    const K = key.toUpperCase();
    registerShortcut("Glaze: focus " + key, "Glaze: Go to workspace " + K,
        "Meta+Alt+" + K, () => show(keyDesktop(key)));
    registerShortcut("Glaze: move " + key, "Glaze: Move window to workspace " + K,
        "Meta+Alt+Shift+" + K, () => moveToKey(key));
});

// Window navigation (GlazeWM-ish). hjkl = focus, Shift+hjkl = snap to that side.
[
    ["focus left", "Meta+Alt+H", "slotSwitchWindowLeft"],
    ["focus down", "Meta+Alt+J", "slotSwitchWindowDown"],
    ["focus up", "Meta+Alt+K", "slotSwitchWindowUp"],
    ["focus right", "Meta+Alt+L", "slotSwitchWindowRight"],
    ["snap left", "Meta+Alt+Shift+H", "slotWindowQuickTileLeft"],
    ["snap down", "Meta+Alt+Shift+J", "slotWindowQuickTileBottom"],
    ["snap up", "Meta+Alt+Shift+K", "slotWindowQuickTileTop"],
    ["snap right", "Meta+Alt+Shift+L", "slotWindowQuickTileRight"],
    ["toggle fullscreen", "Meta+Alt+Shift+F", "slotWindowFullScreen"],
    ["close", "Meta+Alt+Shift+W", "slotWindowClose"],
].forEach(([name, key, slot]) => {
    registerShortcut("Glaze: " + name, "Glaze: " + name, key, () => workspace[slot]());
});

// Expand: like maximize, but leaves gaps (px) around the window.
const EXPAND_GAP = { top: 2, right: 2, bottom: 11, left: 2 };
const expanded = {}; // window internalId -> geometry before expanding

function expandedRect(w) {
    const a = workspace.clientArea(KWin.MaximizeArea, w);
    return {
        x: a.x + EXPAND_GAP.left,
        y: a.y + EXPAND_GAP.top,
        width: a.width - EXPAND_GAP.left - EXPAND_GAP.right,
        height: a.height - EXPAND_GAP.top - EXPAND_GAP.bottom,
    };
}

function expand(w) {
    const id = String(w.internalId);
    if (w.fullScreen) w.fullScreen = false;
    w.setMaximize(false, false);
    const g = w.frameGeometry;
    expanded[id] = { x: g.x, y: g.y, width: g.width, height: g.height };
    w.frameGeometry = expandedRect(w);
}

// Wayland apps pick their own size right after opening, undoing the expand.
// Re-apply it when that happens, and stop once the size sticks (max 3 tries)
// so later manual resizes are left alone.
function expandOnOpen(w) {
    expand(w);
    let tries = 0;
    const settle = () => {
        const want = expandedRect(w), g = w.frameGeometry;
        const fits = Math.abs(g.width - want.width) < 4 && Math.abs(g.height - want.height) < 4;
        if (fits || ++tries > 3) {
            w.frameGeometryChanged.disconnect(settle);
            return;
        }
        w.frameGeometry = want;
    };
    w.frameGeometryChanged.connect(settle);
}

registerShortcut("Glaze: toggle expand", "Glaze: Toggle expanded window", "Meta+Alt+Return", () => {
    const w = workspace.activeWindow;
    if (!w || !w.normalWindow) return;
    const id = String(w.internalId);
    if (expanded[id]) {
        w.frameGeometry = expanded[id];
        delete expanded[id];
        return;
    }
    expand(w);
});
workspace.windowRemoved.connect((w) => delete expanded[String(w.internalId)]);

registerShortcut("Glaze: toggle title bar", "Glaze: Show/hide title bar", "Meta+Alt+;", () => {
    const w = workspace.activeWindow;
    if (w && w.normalWindow) w.noBorder = !w.noBorder;
});

// Switch to the previous window on this workspace; press again to switch back.
registerShortcut("Glaze: other window", "Glaze: Switch to previous window", "Meta+Alt+.", () => {
    const cur = workspace.currentDesktop, active = workspace.activeWindow;
    const others = workspace.stackingOrder.filter((w) =>
        w !== active && managed(w) && w.desktops.some((d) => d.id === cur.id));
    if (others.length) workspace.activeWindow = others[others.length - 1];  // topmost
});

registerShortcut("Glaze: recent", "Glaze: Go to previous workspace", "Meta+Alt+,", () => {
    if (previousDesktop && workspace.desktops.some((d) => d.id === previousDesktop.id)) {
        workspace.currentDesktop = previousDesktop;
    }
});

// Startup: adopt existing desktops by name, make sure keepAlive slots exist,
// then sort every open window.
(function init() {
    const startDesktop = workspace.currentDesktop;
    workspace.desktops.forEach((d) => {
        // Match by name, or by the [x] key so renamed slots ([T]erm -> [T]erminal) are kept.
        const tag = d.name.match(/\[(.)\]/);
        const slot = SLOTS.find((s) => s.label === d.name || s.name === d.name) ||
            (tag && SLOTS.find((s) => s.key === tag[1].toLowerCase()));
        if (slot) {
            kinds[d.id] = { key: slot.key, slot: slot };
            d.name = slot.label;
            return;
        }
        // "[O]utlook" / "Steam [B]" / "Konsole" -> app name + key
        const m = d.name.match(/\[(.)\]/);
        const key = m && KEYS.includes(m[1].toLowerCase()) ? m[1].toLowerCase() : null;
        const name = d.name.replace(/\[(.)\]/, "$1").replace(/ [A-Z0-9]$/, "").trim();
        // A bare "[S]" is an empty workspace, not an app called "S"
        kinds[d.id] = { key: key, appName: name.length > 1 ? name : null };
    });
    SLOTS.filter((s) => s.keepAlive).forEach(slotDesktop);

    workspace.windowList().forEach((w) => {
        if (!managed(w)) return;
        if (w.minimized) w.minimized = false;
        if (HIDE_TITLE_BARS) w.noBorder = true;
        watch(w);
        place(w, false);
    });

    if (windowsOn(startDesktop).length === 0) {
        workspace.currentDesktop = slotDesktop(SLOTS.find((s) => s.keepAlive));
    }
    cleanup();
    log("loaded: " + workspace.desktops.map((d) => d.name).join(", "));
})();
