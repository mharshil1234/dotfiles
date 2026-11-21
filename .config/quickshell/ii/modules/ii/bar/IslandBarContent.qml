pragma ComponentBehavior: Bound
import qs.modules.ii.bar.weather
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

/**
 * Custom "Islands" bar: floating translucent islands instead of a full-width strip.
 * Left half: scroll = brightness, click empty space = left sidebar.
 * Right half: scroll = volume, click empty space = right sidebar.
 * To go back to the stock bar, change `IslandBarContent {` back to `BarContent {` in Bar.qml.
 */
Item {
    id: root

    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    readonly property real islandHeight: 32
    readonly property real gap: 8
    readonly property real edge: 10
    readonly property color colIsland: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainer, 0.18)
    readonly property color colIslandBorder: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.45)
    readonly property color colText: Appearance.colors.colOnLayer0
    readonly property color colDim: Appearance.colors.colSubtext

    readonly property MprisPlayer spotify: Mpris.players.values.find(p =>
        (p.dbusName ?? "").startsWith("org.mpris.MediaPlayer2.spotify")) ?? null

    // ── Shared island look ──────────────────────────────────────────────
    component Island: Item {
        id: island
        default property alias content: inner.data
        property real padding: 12
        property alias radius: bg.radius
        implicitHeight: root.islandHeight
        implicitWidth: inner.childrenRect.width + padding * 2
        Layout.alignment: Qt.AlignVCenter

        StyledRectangularShadow { target: bg; opacity: 0.6 }
        Rectangle {
            id: bg
            anchors.fill: parent
            radius: height / 2
            color: root.colIsland
            border.width: 1
            border.color: root.colIslandBorder
        }
        Item {
            id: inner
            anchors.fill: parent
            anchors.leftMargin: island.padding
            anchors.rightMargin: island.padding
        }
        // No width animation here: contents animate themselves, so the island always hugs them exactly
    }

    component Ring: Item {
        id: ring
        required property string icon
        property real value: 0
        property int warningThreshold: 100
        readonly property bool warning: value * 100 >= warningThreshold
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 24
        implicitHeight: 24
        CircularProgress {
            anchors.centerIn: parent
            implicitSize: 24
            lineWidth: 3
            value: ring.value
            enableAnimation: false
            colPrimary: ring.warning ? Appearance.colors.colError : Appearance.colors.colPrimary
            colSecondary: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.82)
        }
        MaterialSymbol {
            anchors.centerIn: parent
            fill: 1
            text: ring.icon
            iconSize: 13
            color: ring.warning ? Appearance.colors.colError : Appearance.colors.colOnLayer0
        }
    }

    // ── Full-width background strip, 50% opaque ─────────────────────────
    Rectangle {
        anchors.fill: parent
        color: ColorUtils.transparentize(Appearance.m3colors.m3background, 0.5)
    }

    // ── Left half: launcher + window, resources ─────────────────────────
    FocusedScrollMouseArea {
        id: leftArea
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left; right: workspacesIsland.left }
        onScrollDown: Brightness.decreaseBrightness()
        onScrollUp: Brightness.increaseBrightness()
        onMovedAway: GlobalStates.osdBrightnessOpen = false
        onPressed: event => {
            if (event.button === Qt.LeftButton)
                GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
        }

        ScrollHint {
            reveal: leftArea.hovered
            icon: "light_mode"
            tooltipText: Translation.tr("Scroll to change brightness")
            side: "left"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        RowLayout {
            anchors { left: parent.left; leftMargin: root.edge; verticalCenter: parent.verticalCenter }
            spacing: root.gap

            // Launcher + active window
            Island {
                padding: 4
                RowLayout {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    LeftSidebarButton {
                        Layout.alignment: Qt.AlignVCenter
                        colBackground: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.82)
                    }
                    WindowInfo {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.rightMargin: 10
                    }
                }
            }

            // Resources: three ring gauges
            Island {
                padding: 6
                MouseArea {
                    id: resArea
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: resRow.implicitWidth
                    implicitHeight: root.islandHeight
                    hoverEnabled: !Config.options.bar.tooltips.clickToShow
                    acceptedButtons: Qt.NoButton
                    RowLayout {
                        id: resRow
                        anchors.centerIn: parent
                        spacing: 6
                        Ring { icon: "planner_review"; value: ResourceUsage.cpuUsage; warningThreshold: Config.options.bar.resources.cpuWarningThreshold }
                        Ring { icon: "memory"; value: ResourceUsage.memoryUsedPercentage; warningThreshold: Config.options.bar.resources.memoryWarningThreshold }
                        Ring { icon: "swap_horiz"; value: ResourceUsage.swapUsedPercentage; warningThreshold: Config.options.bar.resources.swapWarningThreshold }
                    }
                    ResourcesPopup { hoverTarget: resArea }
                }
            }
        }
    }

    // ── Center: workspaces ──────────────────────────────────────────────
    Island {
        id: workspacesIsland
        anchors.centerIn: parent
        padding: 10
        IslandWorkspaces {
            anchors.verticalCenter: parent.verticalCenter
            monitor: root.monitor
        }
    }

    // ── Right half: Spotify, tools, status, battery + clock ─────────────
    FocusedScrollMouseArea {
        id: rightArea
        anchors { top: parent.top; bottom: parent.bottom; left: workspacesIsland.right; right: parent.right }
        onScrollDown: Audio.decrementVolume()
        onScrollUp: Audio.incrementVolume()
        onMovedAway: GlobalStates.osdVolumeOpen = false
        onPressed: event => {
            if (event.button === Qt.LeftButton)
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }

        ScrollHint {
            reveal: rightArea.hovered
            icon: "volume_up"
            tooltipText: Translation.tr("Scroll to change volume")
            side: "right"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }

        // Tell the media popup where the Spotify island is, so it opens right under it
        Binding {
            target: GlobalStates
            property: "mediaPillX"
            value: rightArea.x + mediaIsland.x
            when: mediaIsland.visible
        }

        // Spotify, placed just right of the workspaces
        Island {
            id: mediaIsland
            visible: root.spotify !== null
            anchors { left: parent.left; leftMargin: root.gap; verticalCenter: parent.verticalCenter }
            padding: 4
            SpotifyPill {
                anchors.verticalCenter: parent.verticalCenter
                player: root.spotify
            }
        }

        RowLayout {
            anchors { right: parent.right; rightMargin: root.edge; verticalCenter: parent.verticalCenter }
            spacing: root.gap

            // Weather (only if enabled in settings)
            Loader {
                Layout.alignment: Qt.AlignVCenter
                active: Config.options.bar.weather.enable
                visible: active
                sourceComponent: Island { padding: 8; WeatherBar { anchors.verticalCenter: parent.verticalCenter } }
            }

            // Tools: always shown (screenshot, on-screen keyboard, dark mode)
            Island {
                padding: 4
                UtilButtons { anchors.verticalCenter: parent.verticalCenter }
            }

            // Status: tray + indicators (click = right sidebar)
            Island {
                padding: 4
                RowLayout {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    SysTray {
                        id: tray
                        readonly property bool hasItems: TrayService.pinnedItems.length + TrayService.unpinnedItems.length > 0
                        visible: hasItems // no empty gap when the tray is empty
                        Layout.fillHeight: true
                        Layout.leftMargin: 6
                        invertSide: Config?.options.bar.bottom
                        showSeparator: false
                    }
                    Rectangle {
                        visible: tray.hasItems
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 1
                        implicitHeight: 14
                        color: root.colIslandBorder
                    }
                    StatusIndicators { Layout.alignment: Qt.AlignVCenter }
                }
            }

            // Battery + clock (hover for popups, click = right sidebar)
            Island {
                padding: 12
                RowLayout {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    BatteryPill { Layout.alignment: Qt.AlignVCenter; visible: Battery.available }
                    Rectangle {
                        visible: Battery.available
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 1
                        implicitHeight: 18
                        color: root.colIslandBorder
                    }
                    MouseArea {
                        id: clockArea
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: clockCol.implicitWidth
                        implicitHeight: root.islandHeight
                        hoverEnabled: !Config.options.bar.tooltips.clickToShow
                        acceptedButtons: Qt.NoButton
                        ColumnLayout {
                            id: clockCol
                            anchors.centerIn: parent
                            spacing: -2
                            // Time over date, both centered in a fixed-width column
                            TextMetrics { id: dateMetrics; text: "WED 30 SEP"; font.pixelSize: 9; font.weight: Font.DemiBold; font.letterSpacing: 0.8 }
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: dateMetrics.width + 4 // fixed width
                                horizontalAlignment: Text.AlignHCenter
                                text: DateTime.time
                                font.pixelSize: 15
                                font.weight: Font.Bold
                                font.family: Appearance.font.family.title
                                font.features: { "tnum": 1 } // equal-width digits
                                color: root.colText
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: dateMetrics.width + 4
                                horizontalAlignment: Text.AlignHCenter
                                text: Qt.locale().toString(DateTime.clock.date, "ddd d MMM").toUpperCase()
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.8
                                color: Appearance.colors.colPrimary
                            }
                        }
                        ClockWidgetPopup { hoverTarget: clockArea }
                    }
                }
            }
        }
    }
}
