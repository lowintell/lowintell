import QtQuick
import QtQuick.Layouts
import qs.config

// Metric card: header, big value, sub-line, rolling sparkline. Optional second series.
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string value: ""
    property string sub: ""
    property var values: []
    property var values2: []
    property real maxValue: 100
    property color tint: Theme.accent
    property color tint2: Theme.violet
    property int graphHeight: 46

    implicitHeight: col.implicitHeight + 24
    radius: Theme.radiusSm + 2
    color: Theme.tile
    border.width: 1
    border.color: Theme.hairline

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Icon { name: root.icon; size: 16; color: root.tint }
            Text {
                text: root.title
                color: Theme.textDim
                font.family: Theme.fontSans
                font.pixelSize: 12
                font.weight: Font.Medium
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.sub
                color: Theme.textMute
                font.family: Theme.fontMono
                font.pixelSize: 11
            }
        }

        Text {
            text: root.value
            color: Theme.text
            font.family: Theme.fontMono
            font.pixelSize: 22
            font.weight: Font.DemiBold
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.graphHeight
            Sparkline {
                anchors.fill: parent
                values: root.values
                maxValue: root.maxValue
                lineColor: root.tint
            }
            Sparkline {
                anchors.fill: parent
                visible: root.values2.length > 0
                values: root.values2
                maxValue: root.maxValue
                lineColor: root.tint2
                filled: false
            }
        }
    }
}
