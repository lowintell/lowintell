import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

PanelPopup {
    id: win

    name: "weather"
    align: "center"
    panelWidth: 420
    panelHeight: col.implicitHeight + Theme.pad * 2

    function t(v) { return Math.round(v) + "°"; }

    ColumnLayout {
        id: col
        x: Theme.pad
        y: Theme.pad
        width: parent.width - Theme.pad * 2
        spacing: 16

        // header
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            WeatherIcon {
                Layout.preferredWidth: 84
                Layout.preferredHeight: 84
                kind: WeatherService.kind
                isDay: WeatherService.isDay
            }
            ColumnLayout {
                spacing: 0
                Text {
                    text: WeatherService.ready ? win.t(WeatherService.temp) + WeatherService.unit.slice(1) : "--"
                    color: Theme.text
                    font.family: Theme.fontSans
                    font.pixelSize: 46
                    font.weight: Font.Light
                }
                Text {
                    text: WeatherService.ready ? WeatherService.desc : (WeatherService.failed ? "Offline" : "Loading…")
                    color: Theme.accent
                    font.family: Theme.fontSans
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }
                Text {
                    text: Config.weatherName
                    color: Theme.textMute
                    font.family: Theme.fontSans
                    font.pixelSize: 12
                }
            }
            Item { Layout.fillWidth: true }
            IconButton {
                Layout.alignment: Qt.AlignTop
                size: 30
                iconSize: 17
                icon: "refresh"
                iconColor: Theme.textDim
                onClicked: WeatherService.refresh()
            }
        }

        // stats
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: 8
            rowSpacing: 8

            Repeater {
                model: [
                    { icon: "thermostat", label: "Feels like", value: WeatherService.ready ? win.t(WeatherService.feels) : "--" },
                    { icon: "water_drop", label: "Humidity", value: WeatherService.ready ? Math.round(WeatherService.humidity) + "%" : "--" },
                    { icon: "air", label: "Wind", value: WeatherService.ready ? Math.round(WeatherService.wind) + " km/h" : "--" },
                    { icon: "swap_vert", label: "High / Low", value: WeatherService.ready ? win.t(WeatherService.hi) + " / " + win.t(WeatherService.lo) : "--" }
                ]
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    radius: Theme.radiusSm
                    color: Theme.tile
                    border.width: 1
                    border.color: Theme.hairline
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 3
                        Icon { Layout.alignment: Qt.AlignHCenter; name: modelData.icon; size: 16; color: Theme.accent2 }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.value
                            color: Theme.text
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.label
                            color: Theme.textMute
                            font.family: Theme.fontSans
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }

        // forecast
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: WeatherService.forecast
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 108
                    radius: Theme.radiusSm
                    color: Theme.tile
                    border.width: 1
                    border.color: Theme.hairline
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.day
                            color: Theme.textDim
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }
                        WeatherIcon {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            kind: WeatherService.kindOf(modelData.code)
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: win.t(modelData.hi)
                            color: Theme.text
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: win.t(modelData.lo)
                            color: Theme.textMute
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            visible: modelData.rain > 0
                            text: modelData.rain + "%"
                            color: Theme.accent2
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Updated " + Qt.formatDateTime(WeatherService.updated, "HH:mm") + "  ·  Open-Meteo"
            color: Theme.textMute
            font.family: Theme.fontSans
            font.pixelSize: 10
        }
    }
}
