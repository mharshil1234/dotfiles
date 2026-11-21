import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

// Island bar battery: slim bar that fills; orange at low, red at critical, amber in power-saver mode, bolt while charging.
MouseArea {
    id: root
    readonly property real pct: Battery.percentage
    readonly property bool charging: Battery.isCharging
    readonly property color fillColor: charging ? Appearance.colors.colPrimary
        : (pct <= Config.options.battery.critical / 100) ? Appearance.colors.colError
        : (pct <= Config.options.battery.low / 100) ? "#ffb347"
        : powerSaver ? "#f5c451" // amber: power saver on
        : Appearance.colors.colPrimary
    readonly property bool powerSaver: PowerProfiles.profile === PowerProfile.PowerSaver

    implicitWidth: row.implicitWidth
    implicitHeight: 32
    hoverEnabled: !Config.options.bar.tooltips.clickToShow
    acceptedButtons: Qt.NoButton

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Item { // battery body + tip
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 30
            implicitHeight: 13
            Rectangle {
                id: body
                width: 27
                height: parent.height
                radius: 4
                color: "transparent"
                border.width: 1.5
                border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.45)
                Rectangle {
                    x: 2.5; y: 2.5
                    width: Math.max(3, (parent.width - 5) * root.pct)
                    height: parent.height - 5
                    radius: 2
                    color: root.fillColor
                    Behavior on width { animation: Appearance.animation.elementMove.numberAnimation.createObject(this) }
                    Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
                }
                MaterialSymbol {
                    anchors.centerIn: parent
                    visible: root.charging
                    text: "bolt"
                    fill: 1
                    iconSize: 13
                    color: Appearance.colors.colOnLayer0
                    style: Text.Outline
                    styleColor: Appearance.m3colors.m3surfaceContainer
                }
            }
            Rectangle {
                anchors { left: body.right; leftMargin: 1; verticalCenter: body.verticalCenter }
                width: 2; height: 5; radius: 1
                color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.45)
            }
        }
        StyledText {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: pctMetrics.width // fixed: room for "100%"
            horizontalAlignment: Text.AlignLeft
            TextMetrics { id: pctMetrics; text: "100%"; font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium }
            text: `${Math.round(root.pct * 100)}%`
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer0
        }
    }

    BatteryPopup { hoverTarget: root }
}
