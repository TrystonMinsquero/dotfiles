// Plasma desktop script: builds the top panel. Run by install.sh through
// `qdbus6 org.kde.plasmashell /PlasmaShell evaluateScript`.
//
//   [menu][workspaces] ---- [clock] ---- [cpu gpu ram bat][tray][show desktop]
//
// Leaves things alone if a panel with the workspace bar already exists, so
// re-running the installer never wipes a panel you've tweaked. Prints the
// system tray's id so install.sh can set which tray icons are hidden.
var REPLACE_EXISTING = true; // install.sh's test mode sets this to false

var built = panels().some(function (p) {
    return p.widgets().some(function (w) { return w.type == "glaze.workspacebar"; });
});

if (built) {
    print("exists");
} else {
    if (REPLACE_EXISTING) panels().forEach(function (p) { p.remove(); });

    var panel = new Panel;
    panel.location = REPLACE_EXISTING ? "top" : "bottom";
    panel.height = 32;

    panel.addWidget("org.kde.plasma.kickoff");
    panel.addWidget("glaze.workspacebar");
    panel.addWidget("org.kde.plasma.panelspacer");

    var clock = panel.addWidget("org.kde.plasma.digitalclock");
    clock.currentConfigGroup = ["Appearance"];
    clock.writeConfig("autoFontAndSize", false);
    clock.writeConfig("fontFamily", "JetBrains Mono");
    clock.writeConfig("fontSize", 10);
    clock.writeConfig("fontWeight", 400);

    panel.addWidget("org.kde.plasma.panelspacer");
    panel.addWidget("glaze.sysinfo");
    panel.addWidget("org.kde.plasma.marginsseparator");
    var tray = panel.addWidget("org.kde.plasma.systemtray");
    panel.addWidget("org.kde.plasma.showdesktop");

    print("panel=" + panel.id + " tray=" + tray.id);
}
