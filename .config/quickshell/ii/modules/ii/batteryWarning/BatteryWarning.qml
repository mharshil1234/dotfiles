import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

/**
 * Custom low-battery warning: a large card at the top of the screen.
 * - Appears at the "low" threshold, turns red at "critical",
 *   and gets a border as a final warning at finalWarningAt (default 5%).
 * - Disappears when you plug in. Dismissable; comes back at each new level.
 * Thresholds: battery.low / battery.critical / battery.suspend in
 * ~/.config/illogical-impulse/config.json, plus finalWarningAt below.
 */
Scope {
    id: root

    readonly property int finalWarningAt: 5 // %, last warning before auto-suspend
    readonly property string level: (Battery.available && !Battery.isCharging && percent <= finalWarningAt) ? "final"
        : Battery.isCriticalAndNotCharging ? "critical"
        : Battery.isLowAndNotCharging ? "low" : "none"
    property bool dismissed: false
    onLevelChanged: dismissed = false // re-show when it gets worse (or after charging)

    readonly property bool shown: level !== "none" && !dismissed && !GlobalStates.screenLocked
    readonly property bool critical: level === "critical" || level === "final"
    readonly property bool isFinal: level === "final"
    readonly property int percent: Math.round(Battery.percentage * 100)

    function formatTimeLeft(seconds) {
        if (!seconds || seconds <= 0) return "";
        const h = Math.floor(seconds / 3600);
        const m = Math.round((seconds % 3600) / 60);
        if (h > 0) return Translation.tr("about %1h %2m left").arg(h).arg(m);
        return Translation.tr("about %1 min left").arg(Math.max(1, m));
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: root.shown
            color: "transparent"

            WlrLayershell.namespace: "quickshell:batteryWarning"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            anchors.top: true
            margins.top: Appearance.sizes.barHeight + 12

            implicitWidth: card.implicitWidth + 40
            implicitHeight: card.implicitHeight + 40
            mask: Region { item: card }

            onVisibleChanged: if (visible) enterAnim.restart()

            StyledRectangularShadow { target: card }

            Rectangle {
                id: card
                anchors.horizontalCenter: parent.horizontalCenter
                y: 8
                implicitWidth: Math.max(420, content.implicitWidth + 40)
                implicitHeight: content.implicitHeight + 32
                radius: Appearance.rounding.large
                color: root.critical ? Appearance.colors.colErrorContainer : Appearance.m3colors.m3surfaceContainer
                Behavior on color { ColorAnimation { duration: 300 } }
                border.width: root.isFinal ? 3 : 0
                border.color: Appearance.colors.colError


                readonly property color fg: root.critical ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnLayer1

                ParallelAnimation {
                    id: enterAnim
                    NumberAnimation { target: card; property: "y"; from: -card.height; to: 8; duration: 450; easing.type: Easing.OutBack }
                    NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 250 }
                }

                RowLayout {
                    id: content
                    anchors.fill: parent
                    anchors.margins: 16
                    anchors.leftMargin: 20
                    spacing: 16

                    // Battery icon in a tinted circle
                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 56
                        implicitHeight: 56
                        radius: width / 2
                        color: root.critical ? Appearance.colors.colError : Appearance.colors.colTertiaryContainer
                        MaterialSymbol {
                            anchors.centerIn: parent
                            fill: 1
                            iconSize: 32
                            text: root.critical ? "battery_alert" : "battery_2_bar"
                            color: root.critical ? Appearance.colors.colOnError : Appearance.colors.colOnTertiaryContainer
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        StyledText {
                            text: root.isFinal ? Translation.tr("Suspending soon — %1%").arg(root.percent)
                                : root.critical ? Translation.tr("Battery critical — %1%").arg(root.percent)
                                                : Translation.tr("Low battery — %1%").arg(root.percent)
                            font.family: Appearance.font.family.title
                            font.pixelSize: Appearance.font.pixelSize.huge
                            font.weight: Font.DemiBold
                            color: card.fg
                        }
                        StyledText {
                            readonly property string timeLeft: root.formatTimeLeft(Battery.timeToEmpty)
                            text: root.isFinal
                                ? (Config.options.battery.automaticSuspend
                                    ? Translation.tr("Save your work. Suspending at %1%").arg(Config.options.battery.suspend)
                                    : Translation.tr("Save your work and plug in"))
                                  + (timeLeft ? " · " + timeLeft : "")
                                : root.critical
                                ? (Config.options.battery.automaticSuspend
                                    ? Translation.tr("Plug in now. Suspending at %1%").arg(Config.options.battery.suspend)
                                    : Translation.tr("Plug in now"))
                                  + (timeLeft ? " · " + timeLeft : "")
                                : Translation.tr("Plug in your charger") + (timeLeft ? " · " + timeLeft : "")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: ColorUtils.transparentize(card.fg, 0.2)
                        }
                    }

                    // Dismiss
                    RippleButton {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 40
                        implicitHeight: 40
                        buttonRadius: Appearance.rounding.full
                        colBackground: "transparent"
                        onClicked: root.dismissed = true
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            text: "close"
                            iconSize: 22
                            color: card.fg
                        }
                    }
                }
            }
        }
    }
}
