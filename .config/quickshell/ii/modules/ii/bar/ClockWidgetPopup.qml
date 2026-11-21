import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

StyledPopup {
    id: root
    property string formattedDate: Qt.locale().toString(DateTime.clock.date, "dddd, MMMM dd, yyyy")
    property string formattedTime: DateTime.time
    property string formattedUptime: DateTime.uptime
    property string todosSection: getUpcomingTodos()

    // ── Calendar (custom): today's + tomorrow's events from iCal links in ~/.config/illogical-impulse/calendars.txt
    property var calendar: ({ configured: false, events: [] })
    onActiveChanged: if (active) calendarProc.running = true // refresh when the popup opens

    function getUpcomingTodos() {
        const unfinishedTodos = Todo.list.filter(function (item) {
            return !item.done;
        });
        if (unfinishedTodos.length === 0) {
            return Translation.tr("No pending tasks");
        }

        // Limit to first 5 todos to keep popup manageable
        const limitedTodos = unfinishedTodos.slice(0, 5);
        let todoText = limitedTodos.map(function (item, index) {
            return `  ${index + 1}. ${item.content}`;
        }).join('\n');

        if (unfinishedTodos.length > 5) {
            todoText += `\n  ${Translation.tr("... and %1 more").arg(unfinishedTodos.length - 5)}`;
        }

        return todoText;
    }

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 4

        Process {
            id: calendarProc
            running: true
            command: ["bash", "-c", `"\${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/.venv/bin/python" "${FileUtils.trimFileProtocol(Directories.scriptPath)}/calendar/upcoming-events.py"`]
            stdout: StdioCollector {
                onStreamFinished: {
                    try { root.calendar = JSON.parse(text); } catch (e) {}
                }
            }
        }
        Timer { // refresh every 5 min (downloads are cached for 10)
            running: true
            repeat: true
            interval: 5 * 60 * 1000
            onTriggered: calendarProc.running = true
        }

        StyledPopupHeaderRow {
            icon: "calendar_month"
            label: root.formattedDate
        }

        StyledPopupValueRow {
            icon: "timelapse"
            label: Translation.tr("System uptime:")
            value: root.formattedUptime
        }

        // Calendar events (only once calendars are set up)
        Column {
            visible: root.calendar.configured
            spacing: 2
            Layout.fillWidth: true
            Layout.maximumWidth: 320

            StyledPopupValueRow {
                icon: "event"
                label: Translation.tr("Events:")
                value: root.calendar.events.length === 0 ? Translation.tr("Nothing today or tomorrow") : ""
            }
            Repeater {
                model: root.calendar.events
                delegate: ColumnLayout {
                    required property var modelData
                    required property int index
                    readonly property bool newDay: index === 0 || root.calendar.events[index - 1].day !== modelData.day
                    width: parent.width
                    spacing: 0
                    StyledText { // "Today" / "Tomorrow" heading
                        visible: parent.newDay
                        Layout.topMargin: parent.index === 0 ? 0 : 4
                        text: parent.modelData.day === "today" ? Translation.tr("Today") : Translation.tr("Tomorrow")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colPrimary
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        StyledText {
                            Layout.preferredWidth: 52
                            text: parent.parent.modelData.allDay ? Translation.tr("All day") : parent.parent.modelData.time
                            font.features: { "tnum": 1 }
                            font.weight: parent.parent.modelData.now ? Font.Bold : Font.Normal
                            color: parent.parent.modelData.now ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                        }
                        StyledText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: parent.parent.modelData.title
                            font.weight: parent.parent.modelData.now ? Font.Bold : Font.Normal
                            color: parent.parent.modelData.now ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
                        }
                    }
                }
            }
        }

        // Tasks
        Column {
            spacing: 0
            Layout.fillWidth: true

            StyledPopupValueRow {
                icon: "checklist"
                label: Translation.tr("To Do:")
                value: ""
            }

            StyledText {
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.Wrap
                color: Appearance.colors.colOnSurfaceVariant
                text: root.todosSection
            }
        }
    }
}
