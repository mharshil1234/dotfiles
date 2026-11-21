import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

/**
 * Volume / brightness pop-up, styled like the top bar's islands:
 * translucent pill, thin outline, icon in a tinted circle, bar + value.
 */
Item {
    id: root
    required property real value
    required property string icon
    required property string name
    property bool rotateIcon: false
    property bool scaleIcon: false
    property alias from: valueProgressBar.from
    property alias to: valueProgressBar.to

    readonly property real pillWidth: 250
    readonly property real pillHeight: 44

    implicitWidth: pillWidth + 2 * Appearance.sizes.elevationMargin
    implicitHeight: pillHeight + 2 * Appearance.sizes.elevationMargin

    StyledRectangularShadow {
        target: pill
        opacity: 0.6
    }
    Rectangle {
        id: pill
        anchors {
            fill: parent
            margins: Appearance.sizes.elevationMargin
        }
        radius: height / 2
        color: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainerHigh, 0.18) // same as the bar islands
        border.width: 1
        border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.45)

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 6
                rightMargin: 16
            }
            spacing: 12

            Rectangle { // Icon in a tinted circle
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 32
                implicitHeight: 32
                radius: 16
                color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.78)

                MaterialSymbol {
                    anchors {
                        centerIn: parent
                        alignWhenCentered: !root.rotateIcon
                    }
                    fill: 1
                    color: Appearance.colors.colPrimary
                    renderType: Text.QtRendering
                    text: root.icon
                    iconSize: 16 + 4 * (root.scaleIcon ? root.value : 1)
                    rotation: 180 * (root.rotateIcon ? root.value : 0)

                    Behavior on iconSize {
                        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
                    }
                    Behavior on rotation {
                        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
                    }
                }
            }

            StyledProgressBar {
                id: valueProgressBar
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                valueBarHeight: 6
                value: root.value
            }

            StyledText { // Value, fixed width so the bar doesn't jump
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 26
                horizontalAlignment: Text.AlignRight
                color: Appearance.colors.colOnLayer0
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
                text: Math.round(root.value * 100)
            }
        }
    }
}
