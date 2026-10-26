import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

// CPU temperature, NVIDIA GPU power state, RAM (focused app / available / total),
// Wi-Fi (only when there's a problem) and battery with time left,
// read by ../code/stats.sh every few seconds. Never touches nvidia-smi, so it
// can't wake the GPU.
PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation

    readonly property color accent: "#9dbcff"
    readonly property color muted: "#6c7a90"
    readonly property color hot: "#ff9d9d"
    readonly property string font: "JetBrains Mono"

    property int cpuTemp: 0         // °C
    property real ramFree: 0        // GiB available
    property real ramTotal: 0       // GiB
    property real appRam: -1        // GiB used by the focused app (-1 = unknown)
    property string gpu: "?"        // "on" / "off"
    property string wifi: ""        // connection name, "" when disconnected
    property int signal: 0          // %
    property int battery: -1        // %
    property string batState: ""    // Charging / Discharging / Full / Not charging
    property string net: "full"     // NetworkManager connectivity
    property real batCharge: 0      // uAh left
    property real batDraw: 0        // uA, smoothed while discharging (0 = unknown)

    // Only show Wi-Fi when something is wrong. "" = all good, so it's hidden.
    readonly property string netProblem:
        net === "none" || (!wifi && net !== "full" && net !== "unknown") ? "off"
        : net === "portal" ? "login"
        : net === "limited" ? "limited"
        : wifi && signal < 40 ? signal + "%"
        : ""

    // Battery time left while discharging, Go-style: 3h12m / 45m
    readonly property string timeLeft: {
        if (batState !== "Discharging" || batDraw <= 0) return "";
        const mins = Math.round(batCharge / batDraw * 60);
        const h = Math.floor(mins / 60), m = mins % 60;
        return h > 0 ? h + "h" + m + "m" : m + "m";
    }

    // Focused window's process, from the same task list the taskbar uses.
    TaskManager.TasksModel {
        id: tasks
        filterByVirtualDesktop: false
        filterByScreen: false
        filterByActivity: false
    }
    readonly property int appPid: tasks.activeTask.valid
        ? (tasks.data(tasks.activeTask, TaskManager.AbstractTasksModel.AppPid) || 0) : 0
    readonly property string appName: tasks.activeTask.valid
        ? (tasks.data(tasks.activeTask, TaskManager.AbstractTasksModel.AppName) || "") : ""
    readonly property string appId: tasks.activeTask.valid
        ? (tasks.data(tasks.activeTask, TaskManager.AbstractTasksModel.AppId) || appName) : ""

    // Tell ~/.local/bin/kanata-modes.py which app is focused, so it can restore
    // that app's kanata mode. Does nothing if the helper isn't installed.
    onAppIdChanged: {
        const id = appId.replace(/[^A-Za-z0-9._-]/g, "_");
        if (id) notifier.connectSource("sh -c '[ -x \"$HOME/.local/bin/kanata-modes.py\" ] && "
            + "\"$HOME/.local/bin/kanata-modes.py\" focus " + id + "; true'");
    }
    P5Support.DataSource {
        id: notifier
        engine: "executable"
        onNewData: (source) => disconnectSource(source)
    }

    readonly property string script: Qt.resolvedUrl("../code/stats.sh").toString().replace("file://", "")
    readonly property string command: "sh '" + script + "' " + appPid

    P5Support.DataSource {
        engine: "executable"
        connectedSources: [root.command]
        interval: 3000
        onNewData: (source, data) => {
            const v = {};
            data.stdout.trim().split("\n").forEach((line) => {
                const i = line.indexOf("=");
                if (i > 0) v[line.slice(0, i)] = line.slice(i + 1);
            });
            const gib = (kb) => parseInt(kb) / 1048576;
            root.cpuTemp = Math.round(parseInt(v.cpu) / 1000);
            root.ramFree = gib(v.memavail);
            root.ramTotal = gib(v.memtotal);
            root.gpu = v.gpu === "suspended" || v.gpu === "removed" ? "off" : (v.gpu ? "on" : "?");
            root.appRam = v.app !== undefined ? gib(v.app) : -1;
            root.wifi = v.wifi || "";
            root.signal = parseInt(v.signal) || 0;
            root.battery = v.bat !== undefined ? parseInt(v.bat) : -1;
            root.batState = v.batstate || "";
            root.net = v.net || "unknown";
            root.batCharge = parseInt(v.batcharge) || 0;
            // Current jumps around; smooth it so the estimate doesn't flicker.
            const draw = parseInt(v.batcurrent) || 0;
            root.batDraw = root.batState !== "Discharging" || draw <= 0 ? 0
                : root.batDraw > 0 ? root.batDraw * 0.8 + draw * 0.2 : draw;
        }
    }

    toolTipMainText: "System"
    toolTipSubText: "Focused app" + (appName ? " (" + appName + ")" : "") + ": "
        + (appRam >= 0 ? appRam.toFixed(2) + " GiB" : "n/a")
        + "\nAvailable: " + ramFree.toFixed(1) + " GiB of " + ramTotal.toFixed(1) + " GiB"
        + "\nNVIDIA GPU: " + gpu + "\nCPU: " + cpuTemp + " °C"
        + "\nWi-Fi: " + (wifi ? wifi + " (" + signal + "%)" : "disconnected")
        + "\nBattery: " + battery + "% (" + batState.toLowerCase() + ")"
        + (timeLeft ? ", " + timeLeft + " left" : "")

    component Stat: Row {
        property string label
        property string value
        property color valueColor: Kirigami.Theme.textColor
        spacing: Kirigami.Units.smallSpacing
        PlasmaComponents.Label { text: parent.label; color: root.muted; font.family: root.font }
        PlasmaComponents.Label { text: parent.value; color: parent.valueColor; font.family: root.font }
    }

    component Dot: PlasmaComponents.Label {
        text: "·"; color: root.muted; font.family: root.font
    }

    fullRepresentation: RowLayout {
        spacing: Kirigami.Units.largeSpacing
        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth

        Stat {
            label: "cpu"
            value: root.cpuTemp + "°"
            valueColor: root.cpuTemp >= 85 ? root.hot : Kirigami.Theme.textColor
        }
        Dot {}
        Stat {
            label: "gpu"
            value: root.gpu
            valueColor: root.gpu === "on" ? root.accent : root.muted
        }
        Dot {}
        // focused app / available / total
        Row {
            spacing: Kirigami.Units.smallSpacing
            PlasmaComponents.Label { text: "ram"; color: root.muted; font.family: root.font }
            PlasmaComponents.Label {
                text: root.appRam >= 0 ? root.appRam.toFixed(1) : "-"
                color: root.accent; font.family: root.font
            }
            PlasmaComponents.Label { text: "/"; color: root.muted; font.family: root.font }
            PlasmaComponents.Label { text: root.ramFree.toFixed(1); font.family: root.font }
            PlasmaComponents.Label { text: "/"; color: root.muted; font.family: root.font }
            PlasmaComponents.Label { text: root.ramTotal.toFixed(0) + "G"; color: root.muted; font.family: root.font }
        }
        Dot { visible: root.netProblem !== "" }
        Stat {
            visible: root.netProblem !== ""
            label: "wifi"
            value: root.netProblem
            valueColor: root.hot
        }
        Dot {}
        Stat {
            label: "bat"
            // + while charging, = when plugged in but holding (charge limit / full)
            value: root.battery + "%" + (root.batState === "Charging" ? "+"
                 : root.batState === "Discharging" ? "" : "=")
            valueColor: root.batState === "Discharging" && root.battery <= 20 ? root.hot
                      : root.batState === "Charging" ? root.accent : Kirigami.Theme.textColor
        }
        PlasmaComponents.Label {
            visible: root.timeLeft !== ""
            text: root.timeLeft
            color: root.muted
            font.family: root.font
        }
    }
}
