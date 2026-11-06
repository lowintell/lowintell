import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

// One notification. Used by both the toast popups and the notification centre.
Item {
    id: card

    property int nid: 0
    property string appName: ""
    property string appIcon: ""
    property string image: ""
    property string summary: ""
    property string body: ""
    property int urgency: 1
    property double time: 0
    property bool framed: true

    signal closeRequested()
    signal activated()

    implicitWidth: 340
    implicitHeight: content.implicitHeight + 24

    Rectangle {
        anchors.fill: parent
        visible: card.framed
        radius: Theme.radiusSm + 2
        color: area.containsMouse ? Theme.tileHover : Theme.tile
        border.width: 1
        border.color: card.urgency === 2 ? Theme.alpha(Theme.bad, 0.7) : Theme.hairline
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: card.activated()
    }

    RowLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 12

        ClippingRectangle {
            Layout.preferredWidth: 38
            Layout.preferredHeight: 38
            Layout.alignment: Qt.AlignTop
            radius: 11
            color: Theme.surface

            Image {
                anchors.fill: parent
                visible: card.image !== "" && status === Image.Ready
                source: card.image
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
            IconImage {
                anchors.centerIn: parent
                implicitSize: 24
                visible: card.image === ""
                source: NotificationService.iconSource(card.appIcon)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: card.appName
                    color: Theme.accent
                    font.family: Theme.fontSans
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.maximumWidth: 140
                }
                Text {
                    text: "·  " + NotificationService.ago(card.time, NotificationService.tick)
                    color: Theme.textMute
                    font.family: Theme.fontSans
                    font.pixelSize: 11
                }
                Item { Layout.fillWidth: true }
            }
            Text {
                Layout.fillWidth: true
                text: card.summary
                color: Theme.text
                font.family: Theme.fontSans
                font.pixelSize: 13
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: card.body !== ""
                text: card.body
                textFormat: Text.StyledText
                color: Theme.textDim
                font.family: Theme.fontSans
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                onLinkActivated: link => Qt.openUrlExternally(link)
            }
        }

        IconButton {
            Layout.alignment: Qt.AlignTop
            size: 26
            iconSize: 15
            icon: "close"
            iconColor: Theme.textMute
            onClicked: card.closeRequested()
        }
    }
}
