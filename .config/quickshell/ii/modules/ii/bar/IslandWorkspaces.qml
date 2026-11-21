import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.modules.common.functions

// Island bar workspaces: app icon of each workspace's main window, dot when empty; active one sits on an accent pill.
MouseArea {
    id: root
    required property HyprlandMonitor monitor
    readonly property int shown: Config.options.bar.workspaces.shown
    readonly property int activeId: monitor?.activeWorkspace?.id ?? 1
    readonly property int group: Math.floor((activeId - 1) / shown)
    property bool showNumbers: false

    implicitWidth: row.implicitWidth
    implicitHeight: 32
    acceptedButtons: Qt.RightButton
    onWheel: event => {
        if (event.angleDelta.y < 0) Hyprland.dispatch(`hl.dsp.focus({workspace = "r+1"})`);
        else if (event.angleDelta.y > 0) Hyprland.dispatch(`hl.dsp.focus({workspace = "r-1"})`);
    }
    onPressed: event => {
        if (event.button === Qt.RightButton) Hyprland.dispatch(`hl.dsp.workspace.toggle_special("special")`);
    }

    Timer {
        id: numbersTimer
        interval: Config?.options.bar.autoHide.showWhenPressingSuper.delay ?? 100
        onTriggered: root.showNumbers = true
    }
    Connections {
        target: GlobalStates
        function onSuperDownChanged() {
            if (GlobalStates.superDown) numbersTimer.restart();
            else { numbersTimer.stop(); root.showNumbers = false; }
        }
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Repeater {
            model: root.shown
            delegate: MouseArea {
                id: slot
                required property int index
                readonly property int wsId: root.group * root.shown + index + 1
                readonly property bool active: wsId === root.activeId
                readonly property var mainWindow: HyprlandData.biggestWindowForWorkspace(wsId)
                readonly property bool occupied: mainWindow !== null && mainWindow !== undefined
                readonly property string iconSource: occupied
                    ? Quickshell.iconPath(AppSearch.guessIcon(mainWindow.class), "application-x-executable") : ""
                width: root.showNumbers ? 30 : (active ? 40 : occupied ? 28 : 16) // Super held: equal slots, number over faded logo
                Behavior on width { animation: Appearance.animation.elementMove.numberAnimation.createObject(this) }
                height: 32
                hoverEnabled: true
                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${wsId}})`)

                // Active pill / hover highlight (behind the icon)
                Rectangle {
                    anchors.centerIn: parent
                    width: slot.active ? (root.showNumbers ? 26 : 36) : (slot.occupied ? 26 : 0)
                    height: 24
                    radius: height / 2
                    color: slot.active ? Appearance.colors.colPrimary
                        : ColorUtils.transparentize(Appearance.colors.colOnLayer0, slot.containsMouse ? 0.82 : 1)
                    Behavior on width { animation: Appearance.animation.elementMove.numberAnimation.createObject(this) }
                    Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
                }

                // App logo (faded while Super is held)
                IconImage {
                    anchors.centerIn: parent
                    visible: slot.occupied
                    implicitSize: 18
                    source: slot.iconSource
                    opacity: root.showNumbers ? 0.6 : (slot.active ? 1 : 0.8)
                    Behavior on opacity { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                }

                // Dot for empty workspaces
                Rectangle {
                    anchors.centerIn: parent
                    visible: !slot.occupied && !root.showNumbers
                    width: slot.active ? 10 : 6
                    height: width
                    radius: width / 2
                    color: slot.active ? Appearance.colors.colOnPrimary : Appearance.colors.colOutlineVariant
                    opacity: slot.containsMouse ? 1 : 0.9
                }

                // Number on top of the logo while Super is held
                StyledText {
                    anchors.centerIn: parent
                    visible: root.showNumbers
                    text: slot.wsId
                    font.pixelSize: 12
                    font.weight: Font.Black
                    color: slot.active ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                    style: Text.Outline
                    styleColor: slot.active ? Appearance.colors.colPrimary : Appearance.m3colors.m3surfaceContainer
                }
            }
        }
    }
}
