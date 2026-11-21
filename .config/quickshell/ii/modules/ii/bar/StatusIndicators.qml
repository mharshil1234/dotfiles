import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Island bar status icons; click toggles the right sidebar, right-click = Do-not-disturb menu.
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
    altAction: () => root.dndMenuOpen = !root.dndMenuOpen

    // ── Do not disturb ──────────────────────────────────────────────────
    property bool dndMenuOpen: false
    function setDnd(minutes) { // minutes: >0 = for that long, 0 = until turned off, -1 = until 8:00 tomorrow, -2 = off
        if (minutes === -2) {
            Notifications.silent = false;
            GlobalStates.dndUntil = 0;
        } else {
            let until = 0;
            if (minutes > 0) until = Date.now() + minutes * 60000;
            else if (minutes === -1) {
                const d = new Date();
                d.setDate(d.getDate() + 1);
                d.setHours(8, 0, 0, 0);
                until = d.getTime();
            }
            GlobalStates.dndUntil = until;
            Notifications.silent = true;
        }
        root.dndMenuOpen = false;
    }
    readonly property string dndStatus: !Notifications.silent ? Translation.tr("Off")
        : GlobalStates.dndUntil > 0 ? Translation.tr("On until %1").arg(Qt.formatDateTime(new Date(GlobalStates.dndUntil),
            new Date(GlobalStates.dndUntil).getDate() === new Date().getDate() ? "hh:mm" : "ddd hh:mm"))
        : Translation.tr("On until turned off")
    Timer { // end a timed Do-not-disturb
        running: Notifications.silent && GlobalStates.dndUntil > 0
        interval: 15000
        repeat: true
        triggeredOnStart: true
        onTriggered: if (Date.now() >= GlobalStates.dndUntil) root.setDnd(-2)
    }
    Connections { // turned off elsewhere (sidebar): forget the end time
        target: Notifications
        function onSilentChanged() { if (!Notifications.silent) GlobalStates.dndUntil = 0; }
    }

    LazyLoader {
        active: root.dndMenuOpen
        component: PanelWindow {
            id: dndWindow
            color: "transparent"
            anchors { top: true; left: true }
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:popup"
            WlrLayershell.layer: WlrLayer.Overlay
            implicitWidth: menuBg.implicitWidth + Appearance.sizes.elevationMargin * 2
            implicitHeight: menuBg.implicitHeight + Appearance.sizes.elevationMargin * 2
            margins {
                top: Appearance.sizes.barHeight
                left: Math.min(root.QsWindow?.mapFromItem(bellItem, bellItem.width / 2, 0).x - implicitWidth / 2,
                    (dndWindow.screen?.width ?? 1920) - implicitWidth - 4)
            }
            mask: Region { item: menuBg }
            Component.onCompleted: GlobalFocusGrab.addDismissable(dndWindow)
            Component.onDestruction: GlobalFocusGrab.removeDismissable(dndWindow)
            Connections {
                target: GlobalFocusGrab
                function onDismissed() { root.dndMenuOpen = false; }
            }

            StyledRectangularShadow { target: menuBg; opacity: 0.6 }
            Rectangle {
                id: menuBg
                anchors.centerIn: parent
                implicitWidth: menuCol.implicitWidth + 12
                implicitHeight: menuCol.implicitHeight + 12
                radius: Appearance.rounding.large
                color: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainerHigh, 0.18) // like the bar islands
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.45)

                component MenuItem: RippleButton {
                    id: item
                    required property string symbol
                    required property string label
                    property bool current: false
                    Layout.fillWidth: true
                    implicitWidth: itemRow.implicitWidth + 28
                    implicitHeight: 34
                    buttonRadius: Appearance.rounding.full
                    colBackground: current ? Appearance.colors.colSecondaryContainer : "transparent"
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    colRipple: Appearance.colors.colLayer1Active
                    RowLayout {
                        id: itemRow
                        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                        spacing: 10
                        MaterialSymbol { text: item.symbol; iconSize: 18; color: Appearance.colors.colOnLayer0 }
                        StyledText { text: item.label; color: Appearance.colors.colOnLayer0 }
                    }
                }

                ColumnLayout {
                    id: menuCol
                    anchors.centerIn: parent
                    spacing: 2
                    RowLayout { // header
                        Layout.margins: 8
                        Layout.bottomMargin: 4
                        spacing: 10
                        MaterialSymbol { text: "do_not_disturb_on"; iconSize: 20; fill: 1; color: Appearance.colors.colPrimary }
                        ColumnLayout {
                            spacing: 0
                            StyledText { text: Translation.tr("Do not disturb"); font.weight: Font.DemiBold; color: Appearance.colors.colOnLayer0 }
                            StyledText { text: root.dndStatus; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext }
                        }
                    }
                    MenuItem { symbol: "schedule"; label: Translation.tr("For 1 hour"); onClicked: root.setDnd(60) }
                    MenuItem { symbol: "bedtime"; label: Translation.tr("Until 8:00 tomorrow"); onClicked: root.setDnd(-1) }
                    MenuItem { symbol: "notifications_paused"; label: Translation.tr("Until I turn it off"); current: Notifications.silent && GlobalStates.dndUntil === 0; onClicked: root.setDnd(0) }
                    MenuItem { visible: Notifications.silent; symbol: "notifications_active"; label: Translation.tr("Turn off"); onClicked: root.setDnd(-2) }
                }
            }
        }
    }

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
            id: bellItem
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
