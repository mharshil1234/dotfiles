import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

// Island bar status icons; click toggles the right sidebar.
RippleButton {
    id: root
    implicitWidth: icons.implicitWidth + 20
    implicitHeight: 26
    buttonRadius: Appearance.rounding.full
    colBackground: "transparent"
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.colors.colSecondaryContainerActive
    toggled: GlobalStates.sidebarRightOpen
    readonly property color colText: toggled ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0
    onPressed: GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen

    component Icon: MaterialSymbol {
        Layout.alignment: Qt.AlignVCenter
        iconSize: Appearance.font.pixelSize.larger
        color: root.colText
    }

    RowLayout {
        id: icons
        anchors.centerIn: parent
        spacing: 10

        Icon { readonly property bool muted: Audio.sink?.audio?.muted ?? false; text: muted ? "volume_off" : "volume_up"; color: muted ? Appearance.colors.colError : root.colText }
        Icon { readonly property bool muted: Audio.source?.audio?.muted ?? false; text: muted ? "mic_off" : "mic"; color: muted ? Appearance.colors.colError : root.colText }
        HyprlandXkbIndicator { Layout.alignment: Qt.AlignVCenter; color: root.colText }
        Icon { text: Network.materialSymbol }
        Icon {
            visible: BluetoothStatus.available
            text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
        }
        Item { // bell with unread badge
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: bell.implicitWidth
            implicitHeight: bell.implicitHeight
            Icon {
                id: bell
                text: Notifications.silent ? "notifications_off" : "notifications"
                fill: Notifications.unread > 0 ? 1 : 0
            }
            Rectangle {
                visible: Notifications.unread > 0 && !Notifications.silent
                anchors { top: parent.top; right: parent.right; topMargin: -3; rightMargin: -5 }
                implicitWidth: Math.max(14, badgeText.implicitWidth + 6)
                implicitHeight: 14
                radius: 7
                color: Appearance.colors.colPrimary
                StyledText {
                    id: badgeText
                    anchors.centerIn: parent
                    text: Notifications.unread > 9 ? "9+" : Notifications.unread
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnPrimary
                }
            }
        }
    }
}
