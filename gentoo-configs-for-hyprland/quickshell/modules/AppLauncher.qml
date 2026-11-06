import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

PanelPopup {
    id: win

    name: "launcher"
    align: "center"
    keyboard: true
    panelWidth: 640
    panelHeight: 74 + rows * rowHeight + 20
    topMargin: 130

    readonly property int rows: 7
    readonly property int rowHeight: 54

    property string query: ""
    property var recents: []
    readonly property var results: search(query, recents)

    // ── search ──
    function score(app, q) {
        const name = (app.name || "").toLowerCase();
        if (name === q) return 120;
        if (name.startsWith(q)) return 100;
        if (name.indexOf(" " + q) >= 0) return 80;
        if (name.indexOf(q) >= 0) return 60;
        const extra = ((app.genericName || "") + " " + (app.comment || "") + " " + (app.keywords ? app.keywords.join(" ") : "")).toLowerCase();
        if (extra.indexOf(q) >= 0) return 30;
        return 0;
    }

    function search(q, rec) {
        const apps = DesktopEntries.applications.values.filter(a => !a.noDisplay);
        q = q.trim().toLowerCase();
        const bonus = a => { const i = rec.indexOf(a.id); return i >= 0 ? 40 - i * 2 : 0; };
        if (q === "") {
            return apps.slice().sort((a, b) => (bonus(b) - bonus(a)) || a.name.localeCompare(b.name)).slice(0, 60);
        }
        const scored = [];
        for (const a of apps) {
            const s = score(a, q);
            if (s > 0) scored.push({ a: a, s: s + bonus(a) });
        }
        scored.sort((x, y) => (y.s - x.s) || x.a.name.localeCompare(y.a.name));
        return scored.slice(0, 60).map(x => x.a);
    }

    function launch(entry) {
        if (!entry) return;
        remember(entry.id);
        UiState.close();
        if (entry.runInTerminal) Quickshell.execDetached([Config.terminal, "-e"].concat(entry.command));
        else entry.execute();
    }

    // ── recents (persisted to ~/.local/state/qs-glass/recents.json) ──
    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/qs-glass"

    function remember(id) {
        const next = [id].concat(recents.filter(x => x !== id)).slice(0, 12);
        recents = next;
        store.setText(JSON.stringify(next));
    }

    Process { id: mk; command: ["mkdir", "-p", win.stateDir]; running: true }
    FileView {
        id: store
        path: win.stateDir + "/recents.json"
        printErrors: false
        onLoaded: { try { win.recents = JSON.parse(text()); } catch (e) {} }
    }

    onOpenChanged: {
        if (open) {
            query = "";
            field.text = "";
            list.currentIndex = 0;
            focusTimer.restart();
        }
    }
    Timer { id: focusTimer; interval: 40; onTriggered: field.forceActiveFocus() }

    // ── ui ──
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        // search field
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 74

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                spacing: 14

                Icon { name: "search"; size: 24; color: Theme.accent }

                TextInput {
                    id: field
                    Layout.fillWidth: true
                    color: Theme.text
                    selectionColor: Theme.alpha(Theme.accent, 0.4)
                    selectedTextColor: Theme.text
                    font.family: Theme.fontSans
                    font.pixelSize: 20
                    clip: true
                    focus: true
                    onTextChanged: { win.query = text; list.currentIndex = 0; }

                    Text {
                        visible: field.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search applications"
                        color: Theme.textMute
                        font: field.font
                    }

                    Keys.onPressed: e => {
                        if (e.key === Qt.Key_Down || (e.key === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier)) || (e.key === Qt.Key_N && (e.modifiers & Qt.ControlModifier))) {
                            list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1); e.accepted = true;
                        } else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab || (e.key === Qt.Key_P && (e.modifiers & Qt.ControlModifier))) {
                            list.currentIndex = Math.max(0, list.currentIndex - 1); e.accepted = true;
                        } else if (e.key === Qt.Key_PageDown) {
                            list.currentIndex = Math.min(list.count - 1, list.currentIndex + win.rows); e.accepted = true;
                        } else if (e.key === Qt.Key_PageUp) {
                            list.currentIndex = Math.max(0, list.currentIndex - win.rows); e.accepted = true;
                        } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                            win.launch(win.results[list.currentIndex]); e.accepted = true;
                        } else if (e.key === Qt.Key_Escape) {
                            UiState.close(); e.accepted = true;
                        }
                    }
                }

                Text {
                    text: win.results.length + " apps"
                    color: Theme.textMute
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                }
            }

            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 16; rightMargin: 16 }
                height: 1
                color: Theme.hairline
            }
        }

        // results
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.preferredHeight: win.rows * win.rowHeight
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            Layout.topMargin: 8
            model: win.results
            clip: true
            currentIndex: 0
            boundsBehavior: Flickable.StopAtBounds
            highlightFollowsCurrentItem: true
            highlightMoveDuration: 120
            keyNavigationEnabled: false

            highlight: Rectangle {
                radius: Theme.radiusSm + 2
                color: Theme.alpha(Theme.accent, 0.14)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.40)
                Rectangle {
                    width: 3
                    height: parent.height - 18
                    radius: 2
                    anchors.verticalCenter: parent.verticalCenter
                    x: 6
                    color: Theme.accent
                }
            }

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                width: list.width
                height: win.rowHeight

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 14
                    spacing: 14

                    IconImage {
                        implicitSize: 32
                        source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.name
                            color: Theme.text
                            font.family: Theme.fontSans
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: row.modelData.comment || row.modelData.genericName || ""
                            color: Theme.textMute
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                    Icon {
                        visible: win.recents.indexOf(row.modelData.id) >= 0 && win.query === ""
                        name: "history"
                        size: 15
                        color: Theme.textMute
                    }
                    Icon {
                        visible: row.index === list.currentIndex
                        name: "keyboard_return"
                        size: 16
                        color: Theme.accent
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onPositionChanged: list.currentIndex = row.index
                    onClicked: win.launch(row.modelData)
                }
            }

            Text {
                anchors.centerIn: parent
                visible: list.count === 0
                text: "No matching applications"
                color: Theme.textMute
                font.family: Theme.fontSans
                font.pixelSize: 13
            }
        }
    }
}
