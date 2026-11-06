import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

PanelPopup {
    id: win

    name: "system"
    align: "right"
    panelWidth: 440
    panelHeight: col.implicitHeight + Theme.pad * 2

    readonly property bool hasGpu: SystemService.gpu >= 0

    ColumnLayout {
        id: col
        x: Theme.pad
        y: Theme.pad
        width: parent.width - Theme.pad * 2
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: "System"
                color: Theme.text
                font.family: Theme.fontSans
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
            Rectangle {
                width: 7; height: 7; radius: 4
                color: Theme.good
                SequentialAnimation on opacity {
                    running: win.open
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.25; duration: 900 }
                    NumberAnimation { to: 1.0; duration: 900 }
                }
            }
            Text { text: "live"; color: Theme.textMute; font.family: Theme.fontSans; font.pixelSize: 11 }
            Item { Layout.fillWidth: true }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 10
            rowSpacing: 10

            StatCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: "memory"
                title: "CPU"
                value: Math.round(SystemService.cpu) + "%"
                sub: SystemService.cpuTemp >= 0 ? Math.round(SystemService.cpuTemp) + " °C" : "no sensor"
                values: SystemService.cpuHist
                tint: Theme.accent2
            }
            StatCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: "data_usage"
                title: "Memory"
                value: Math.round(SystemService.ram) + "%"
                sub: SystemService.ramUsed.toFixed(1) + " / " + SystemService.ramTotal.toFixed(1) + " GiB"
                values: SystemService.ramHist
                tint: Theme.violet
            }
            StatCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                visible: win.hasGpu
                icon: "developer_board"
                title: "GPU"
                value: Math.round(SystemService.gpu) + "%"
                sub: (SystemService.gpuTemp >= 0 ? Math.round(SystemService.gpuTemp) + " °C · " : "") +
                     (SystemService.vramTotal > 0 ? (SystemService.vramUsed / 1024).toFixed(1) + "/" + (SystemService.vramTotal / 1024).toFixed(0) + " GiB" : "")
                values: SystemService.gpuHist
                tint: Theme.accent
            }
            StatCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.columnSpan: win.hasGpu ? 1 : 2
                icon: "swap_vert"
                title: "Network"
                value: "↓ " + SystemService.fmtBytes(SystemService.netDown)
                sub: "↑ " + SystemService.fmtBytes(SystemService.netUp)
                values: SystemService.netDownHist
                values2: SystemService.netUpHist
                maxValue: 0
                tint: Theme.accent2
                tint2: Theme.violet
            }
        }

        // disks
        Rectangle {
            Layout.fillWidth: true
            visible: SystemService.disks.length > 0
            implicitHeight: diskCol.implicitHeight + 24
            radius: Theme.radiusSm + 2
            color: Theme.tile
            border.width: 1
            border.color: Theme.hairline

            ColumnLayout {
                id: diskCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 10

                RowLayout {
                    spacing: 8
                    Icon { name: "hard_drive"; size: 16; color: Theme.accent }
                    Text {
                        text: "Storage"
                        color: Theme.textDim
                        font.family: Theme.fontSans
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                }

                Repeater {
                    model: SystemService.disks
                    delegate: ColumnLayout {
                        id: diskRow
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 4
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: diskRow.modelData.mount
                                color: Theme.text
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: SystemService.fmtSize(diskRow.modelData.used) + " / " + SystemService.fmtSize(diskRow.modelData.size) +
                                      "  ·  " + diskRow.modelData.pct + "%"
                                color: Theme.textMute
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 5
                            radius: 3
                            color: Qt.rgba(1, 1, 1, 0.08)
                            Rectangle {
                                width: parent.width * Math.min(1, diskRow.modelData.pct / 100)
                                height: parent.height
                                radius: 3
                                color: diskRow.modelData.pct > 90 ? Theme.bad : (diskRow.modelData.pct > 75 ? Theme.warn : Theme.accent)
                                Behavior on width { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic } }
                            }
                        }
                    }
                }
            }
        }
    }
}
