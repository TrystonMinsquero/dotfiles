import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager
import org.kde.plasma.workspace.dbus as DBus

// Shows every virtual desktop as a text label; click to switch, scroll to cycle.
PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation

    readonly property color accent: "#9dbcff"

    TaskManager.VirtualDesktopInfo { id: desktops }

    // KWin numbers desktops from 1.
    function activate(index) {
        DBus.SessionBus.asyncCall({
            service: "org.kde.KWin", path: "/KWin", iface: "org.kde.KWin",
            member: "setCurrentDesktop", arguments: [new DBus.int32(index + 1)], signature: "(i)",
        });
    }

    function switchBy(step) {
        const n = desktops.desktopIds.length;
        const i = desktops.desktopIds.indexOf(desktops.currentDesktop);
        activate((i + step + n) % n);
    }

    fullRepresentation: RowLayout {
        spacing: Kirigami.Units.smallSpacing
        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth
        Layout.fillHeight: true

        Repeater {
            model: desktops.desktopIds

            delegate: Rectangle {
                readonly property bool current: modelData === desktops.currentDesktop

                Layout.fillHeight: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                implicitWidth: label.implicitWidth + Kirigami.Units.largeSpacing * 2
                radius: 2
                // Faded blue from the memento wallpaper (#9dbcff)
                color: current ? Qt.alpha(root.accent, 0.3)
                     : mouse.containsMouse ? Qt.alpha(root.accent, 0.12)
                     : "transparent"

                PlasmaComponents.Label {
                    id: label
                    anchors.centerIn: parent
                    text: desktops.desktopNames[index] || (index + 1)
                    color: parent.current ? "#e6edf7" : Kirigami.Theme.textColor
                    font.family: "JetBrains Mono"
                    font.bold: parent.current
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.activate(index)
                    onWheel: (wheel) => root.switchBy(wheel.angleDelta.y > 0 ? -1 : 1)
                }
            }
        }
    }
}
