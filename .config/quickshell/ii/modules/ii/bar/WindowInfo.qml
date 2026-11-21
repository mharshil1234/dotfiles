import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

// Island bar: app icon + app name (small) + window title, cut off at maxWidth.
Item {
    id: root
    property real maxWidth: 280
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property bool focusingThisMonitor: (HyprlandData.activeWorkspace?.monitor ?? "") === (monitor?.name ?? "-")
    readonly property var biggestWindow: HyprlandData.biggestWindowForWorkspace(HyprlandData.monitors[root.monitor?.id]?.activeWorkspace.id)
    readonly property bool useActive: !!(focusingThisMonitor && activeWindow?.activated && biggestWindow)
    readonly property string appId: useActive ? (activeWindow?.appId ?? "") : (biggestWindow?.class ?? "")
    readonly property string title: useActive ? (activeWindow?.title ?? "")
        : (biggestWindow?.title ?? `${Translation.tr("Workspace")} ${monitor?.activeWorkspace?.id ?? 1}`)
    readonly property string appName: {
        if (appId.length === 0) return Translation.tr("Desktop");
        const entry = DesktopEntries.heuristicLookup(appId);
        return entry?.name ?? appId;
    }

    implicitWidth: maxWidth // fixed width; long titles are cut off
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        width: root.implicitWidth
        spacing: 8

        IconImage {
            Layout.alignment: Qt.AlignVCenter
            visible: root.appId.length > 0
            implicitSize: 20
            source: Quickshell.iconPath(AppSearch.guessIcon(root.appId), "application-x-executable")
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: -4
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.appName
                font.pixelSize: 10
                color: Appearance.colors.colSubtext
            }
            StyledText {
                Layout.fillWidth: true
                Layout.maximumWidth: root.maxWidth - 28
                elide: Text.ElideRight
                text: root.title.length > 0 ? root.title : root.appName
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer0
            }
        }
    }
}
