import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.panels.lock
import qs.modules.ii.bar as Bar
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris

MouseArea {
    id: root
    required property LockContext context
    property bool active: false
    property bool showInputField: active || context.currentText.length > 0
    readonly property bool requirePasswordToPower: Config.options.lock.security.requirePasswordToPower

    // Force focus on entry
    function forceFieldFocus() {
        passwordBox.forceActiveFocus();
    }
    Connections {
        target: context
        function onShouldReFocus() {
            forceFieldFocus();
        }
    }
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPressed: mouse => {
        forceFieldFocus();
    }
    onPositionChanged: mouse => {
        forceFieldFocus();
    }

    // Toolbar appearing animation
    property real toolbarScale: 0.9
    property real toolbarOpacity: 0
    Behavior on toolbarScale {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
        }
    }
    Behavior on toolbarOpacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    // Init
    Component.onCompleted: {
        forceFieldFocus();
        toolbarScale = 1;
        toolbarOpacity = 1;
    }

    // Key presses
    property bool ctrlHeld: false
    Keys.onPressed: event => {
        root.context.resetClearTimer();
        if (event.key === Qt.Key_Control) {
            root.ctrlHeld = true;
        }
        if (event.key === Qt.Key_Escape) { // Esc to clear
            root.context.currentText = "";
        } 
        forceFieldFocus();
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Control) {
            root.ctrlHeld = false;
        }
        forceFieldFocus();
    }

    // ───────────── Custom lock layout ─────────────
    // Centered card: clock, greeting, date, stats row, password box.
    // Bottom-left: now playing. Bottom-right: power buttons.

    readonly property color colHeaderText: Appearance.colors.colOnLayer0
    property date lockedAt: new Date()
    readonly property int lockedMinutes: Math.max(0, Math.floor((DateTime.clock.date - lockedAt) / 60000))
    readonly property string greeting: {
        const h = DateTime.clock.date.getHours();
        if (h < 5) return Translation.tr("Good night");
        if (h < 12) return Translation.tr("Good morning");
        if (h < 17) return Translation.tr("Good afternoon");
        return Translation.tr("Good evening");
    }
    readonly property string displayName: {
        const n = SystemInfo.username;
        return n.length > 0 ? n.charAt(0).toUpperCase() + n.slice(1) : n;
    }
    readonly property bool weatherReady: typeof Weather.data.temp === "string" && Weather.data.temp.indexOf("°") !== -1
    // Only the Spotify desktop app is shown on the lock screen
    readonly property MprisPlayer spotify: Mpris.players.values.find(p =>
        (p.dbusName ?? "").startsWith("org.mpris.MediaPlayer2.spotify")) ?? null
    readonly property bool hasMedia: spotify !== null && (spotify.trackTitle ?? "").length > 0

    ColumnLayout {
        id: centerCard
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40
        spacing: 14
        scale: root.toolbarScale
        opacity: root.toolbarOpacity

        // Clock + greeting + date (with a soft shadow for readability on any wallpaper)
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 2
            layer.enabled: true
            layer.effect: DropShadow {
                radius: 16
                samples: 33
                color: Qt.rgba(0, 0, 0, 0.35)
                verticalOffset: 2
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: DateTime.time
                color: root.colHeaderText
                font.family: Appearance.font.family.expressive
                font.pixelSize: 112
                font.weight: Font.DemiBold
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: `${root.greeting}, ${root.displayName}`
                color: root.colHeaderText
                font.family: Appearance.font.family.title
                font.pixelSize: 30
                font.weight: Font.Medium
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: DateTime.collapsedCalendarFormat
                color: ColorUtils.transparentize(root.colHeaderText, 0.25)
                font.pixelSize: Appearance.font.pixelSize.larger
            }
        }

        // Stats row: weather, battery, keyboard layout, time locked
        Toolbar {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            implicitHeight: 44
            padding: 6

            IconAndTextPair {
                visible: root.weatherReady
                icon: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
                text: `${Weather.data.temp} · ${Weather.data.city}`
            }
            IconAndTextPair {
                visible: Battery.available
                icon: Battery.isCharging ? "bolt" : "battery_android_full"
                text: `${Math.round(Battery.percentage * 100)}%`
                color: (Battery.isLow && !Battery.isCharging) ? Appearance.colors.colError : Appearance.colors.colOnSurfaceVariant
            }
            IconAndTextPair {
                icon: "keyboard_alt"
                text: HyprlandXkb.currentLayoutCode
            }
            Bar.SysTray { // Fcitx keyboard layout, if used
                Layout.rightMargin: 6
                Layout.alignment: Qt.AlignVCenter
                showSeparator: false
                showOverflowMenu: false
                pinnedItems: SystemTray.items.values.filter(i => i.id == "Fcitx")
                visible: pinnedItems.length > 0
            }
            IconAndTextPair {
                icon: "lock_clock"
                text: root.lockedMinutes < 1 ? Translation.tr("Just locked")
                    : root.lockedMinutes < 60 ? Translation.tr("Locked %1m").arg(root.lockedMinutes)
                    : Translation.tr("Locked %1h %2m").arg(Math.floor(root.lockedMinutes / 60)).arg(root.lockedMinutes % 60)
            }
        }

        // Password box
        Toolbar {
            id: mainIsland
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4

            // Fingerprint
            Loader {
                Layout.leftMargin: 10
                Layout.rightMargin: 6
                Layout.alignment: Qt.AlignVCenter
                active: root.context.fingerprintsConfigured
                visible: active

                sourceComponent: MaterialSymbol {
                    fill: 1
                    text: "fingerprint"
                    iconSize: Appearance.font.pixelSize.hugeass
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }

            ToolbarTextField {
                id: passwordBox
                Layout.preferredWidth: 280
                Layout.rightMargin: -Layout.leftMargin
                placeholderText: GlobalStates.screenUnlockFailed ? Translation.tr("Incorrect password") : Translation.tr("Enter password")

                // Style
                clip: true
                font.pixelSize: Appearance.font.pixelSize.small
                selectedTextColor: materialShapeChars ? "transparent" : Appearance.colors.colOnSecondaryContainer
                selectionColor: materialShapeChars ? "transparent" : Appearance.colors.colSecondaryContainer

                // Password
                enabled: !root.context.unlockInProgress
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData

                // Synchronizing (across monitors) and unlocking
                onTextChanged: root.context.currentText = this.text
                onAccepted: {
                    root.context.tryUnlock(ctrlHeld);
                }
                Connections {
                    target: root.context
                    function onCurrentTextChanged() {
                        passwordBox.text = root.context.currentText;
                    }
                }

                Keys.onPressed: event => {
                    root.context.resetClearTimer();
                }

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: passwordBox.width - 8
                        height: passwordBox.height
                        radius: height / 2
                    }
                }

                // Shake when wrong password
                ErrorShakeAnimation {
                    id: wrongPasswordShakeAnim
                    target: passwordBox
                }
                Connections {
                    target: GlobalStates
                    function onScreenUnlockFailedChanged() {
                        if (GlobalStates.screenUnlockFailed) wrongPasswordShakeAnim.restart();
                    }
                }

                // We're drawing dots manually
                property bool materialShapeChars: Config.options.lock.materialShapeChars
                color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, materialShapeChars ? 1 : 0)
                Loader {
                    active: passwordBox.materialShapeChars
                    anchors {
                        fill: parent
                        leftMargin: passwordBox.padding
                        rightMargin: passwordBox.padding
                    }
                    sourceComponent: PasswordChars {
                        length: root.context.currentText.length
                        selectionStart: passwordBox.selectionStart
                        selectionEnd: passwordBox.selectionEnd
                        cursorPosition: passwordBox.cursorPosition
                    }
                }
            }

            ToolbarButton {
                id: confirmButton
                implicitWidth: height
                toggled: true
                enabled: !root.context.unlockInProgress
                colBackgroundToggled: Appearance.colors.colPrimary

                onClicked: root.context.tryUnlock()

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    iconSize: 24
                    text: {
                        if (root.context.targetAction === LockContext.ActionEnum.Unlock) {
                            return root.ctrlHeld ? "coffee" : "arrow_right_alt";
                        } else if (root.context.targetAction === LockContext.ActionEnum.Poweroff) {
                            return "power_settings_new";
                        } else if (root.context.targetAction === LockContext.ActionEnum.Reboot) {
                            return "restart_alt";
                        }
                    }
                    color: confirmButton.enabled ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
                }
            }
        }
    }

    // Now playing (bottom-left)
    Toolbar {
        id: mediaIsland
        visible: root.hasMedia
        anchors {
            left: parent.left
            bottom: parent.bottom
            leftMargin: 24
            bottomMargin: 24
        }
        implicitHeight: 72
        radius: Appearance.rounding.large
        scale: root.toolbarScale
        opacity: root.toolbarOpacity

        Item {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 2
            implicitWidth: 56
            implicitHeight: 56

            Rectangle { // placeholder when there's no art
                anchors.fill: parent
                radius: Appearance.rounding.normal
                color: Appearance.colors.colPrimaryContainer
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "music_note"
                    iconSize: Appearance.font.pixelSize.hugeass
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }
            Image {
                id: albumArt
                anchors.fill: parent
                source: root.spotify?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                sourceSize.width: 112
                sourceSize.height: 112
                visible: status === Image.Ready
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: albumArt.width
                        height: albumArt.height
                        radius: Appearance.rounding.normal
                    }
                }
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 8
            Layout.rightMargin: 4
            Layout.maximumWidth: 240
            spacing: 0
            StyledText {
                Layout.fillWidth: true
                text: root.spotify?.trackTitle ?? ""
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer2
            }
            StyledText {
                Layout.fillWidth: true
                text: root.spotify?.trackArtist ?? ""
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }

        IconToolbarButton {
            enabled: root.spotify?.canGoPrevious ?? false
            onClicked: root.spotify.previous()
            text: "skip_previous"
        }
        IconToolbarButton {
            enabled: root.spotify?.canTogglePlaying ?? false
            onClicked: root.spotify.togglePlaying()
            text: (root.spotify?.isPlaying ?? false) ? "pause" : "play_arrow"
        }
        IconToolbarButton {
            Layout.rightMargin: 4
            enabled: root.spotify?.canGoNext ?? false
            onClicked: root.spotify.next()
            text: "skip_next"
        }
    }

    // Power buttons (bottom-right)
    Toolbar {
        id: powerIsland
        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: 24
            bottomMargin: 24
        }
        scale: root.toolbarScale
        opacity: root.toolbarOpacity

        IconToolbarButton {
            id: sleepButton
            onClicked: Session.suspend()
            text: "dark_mode"
        }

        PasswordGuardedIconToolbarButton {
            id: powerButton
            text: "power_settings_new"
            targetAction: LockContext.ActionEnum.Poweroff
        }

        PasswordGuardedIconToolbarButton {
            id: rebootButton
            text: "restart_alt"
            targetAction: LockContext.ActionEnum.Reboot
        }
    }

    component PasswordGuardedIconToolbarButton: IconToolbarButton {
        id: guardedBtn
        required property var targetAction

        toggled: root.context.targetAction === guardedBtn.targetAction

        onClicked: {
            if (!root.requirePasswordToPower) {
                root.context.unlocked(guardedBtn.targetAction);
                return;
            }
            if (root.context.targetAction === guardedBtn.targetAction) {
                root.context.resetTargetAction();
            } else {
                root.context.targetAction = guardedBtn.targetAction;
                root.context.shouldReFocus();
            }
        }
    }

    component IconAndTextPair: Row {
        id: pair
        required property string icon
        required property string text
        property color color: Appearance.colors.colOnSurfaceVariant

        spacing: 4
        Layout.fillHeight: true
        Layout.leftMargin: 10
        Layout.rightMargin: 10
        

        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            fill: 1
            text: pair.icon
            iconSize: Appearance.font.pixelSize.huge
            animateChange: true
            color: pair.color
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: pair.text
            color: pair.color
        }
    }
}
