import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris

// Island bar media: album art, title/artist, thin progress line.
// Left click = media popup (stock behavior), middle = play/pause, right/forward = next, back = previous.
MouseArea {
    id: root
    required property MprisPlayer player
    readonly property string title: StringUtils.cleanMusicTitle(player?.trackTitle) || Translation.tr("Spotify")
    readonly property real progress: (player?.length > 0) ? Math.min(1, player.position / player.length) : 0

    implicitWidth: row.implicitWidth + 10
    implicitHeight: 32
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton
    property double lastClick: 0
    onClicked: event => {
        const now = Date.now();
        if (now - lastClick < 350) return; // the click can arrive twice; ignore the echo
        lastClick = now;
        if (event.button === Qt.LeftButton) GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen;
        else if (event.button === Qt.MiddleButton) player?.togglePlaying();
        else if (event.button === Qt.BackButton) player?.previous();
        else player?.next(); // right click / forward
    }

    Timer {
        running: root.player?.playbackState == MprisPlaybackState.Playing
        interval: 1000
        repeat: true
        onTriggered: root.player?.positionChanged()
    }

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        ClippingRectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 24
            implicitHeight: 24
            radius: 12
            color: Appearance.colors.colSecondaryContainer
            Image {
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(48, 48)
                asynchronous: true
            }
            Rectangle { // pause overlay
                anchors.fill: parent
                color: "#80000000"
                visible: !(root.player?.isPlaying ?? false)
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "play_arrow"
                    fill: 1
                    iconSize: 16
                    color: "white"
                }
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 1
            StyledText {
                Layout.preferredWidth: 190 // fixed width
                Layout.maximumWidth: 190
                elide: Text.ElideRight
                text: root.title + (root.player?.trackArtist ? `  ·  ${root.player.trackArtist}` : "")
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer0
            }
            Rectangle { // progress line
                Layout.fillWidth: true
                implicitHeight: 2
                radius: 1
                color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.8)
                Rectangle {
                    width: parent.width * root.progress
                    height: parent.height
                    radius: 1
                    color: Appearance.colors.colPrimary
                }
            }
        }
    }
}
