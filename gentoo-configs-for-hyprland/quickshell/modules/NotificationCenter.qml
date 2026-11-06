import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

PanelPopup {
    id: win

    name: "notifs"
    align: "right"
    panelWidth: 390
    panelHeight: 62 + Math.max(130, Math.min(list.contentHeight, 440)) + Theme.pad

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.pad
        anchors.topMargin: 10
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: 6

            Text {
                text: "Notifications"
                color: Theme.text
                font.family: Theme.fontSans
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
            Text {
                visible: NotificationService.count > 0
                text: NotificationService.count
                color: Theme.textMute
                font.family: Theme.fontMono
                font.pixelSize: 12
            }
            Item { Layout.fillWidth: true }
            IconButton {
                size: 32
                iconSize: 18
                icon: NotificationService.dnd ? "notifications_off" : "notifications_active"
                active: NotificationService.dnd
                onClicked: NotificationService.dnd = !NotificationService.dnd
            }
            IconButton {
                size: 32
                iconSize: 18
                icon: "delete_sweep"
                opacity: NotificationService.count > 0 ? 1 : 0.4
                onClicked: NotificationService.clearAll()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: list
                anchors.fill: parent
                model: NotificationService.history
                spacing: 8
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animMed }
                    NumberAnimation { property: "x"; from: 40; to: 0; duration: Theme.animMed + 40; easing.type: Easing.OutCubic }
                }
                remove: Transition {
                    NumberAnimation { property: "opacity"; to: 0; duration: Theme.animFast }
                    NumberAnimation { property: "x"; to: 60; duration: Theme.animFast + 40 }
                }
                displaced: Transition {
                    NumberAnimation { properties: "y"; duration: Theme.animMed; easing.type: Easing.OutCubic }
                }

                delegate: NotificationCard {
                    width: list.width
                    nid: model.nid
                    appName: model.appName
                    appIcon: model.appIcon
                    image: model.image
                    summary: model.summary
                    body: model.body
                    urgency: model.urgency
                    time: model.time
                    onCloseRequested: NotificationService.remove(model.nid)
                    onActivated: NotificationService.invokeDefault(model.nid)
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                visible: NotificationService.count === 0
                spacing: 8
                Icon { Layout.alignment: Qt.AlignHCenter; name: "notifications_paused"; size: 34; color: Theme.textMute }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: NotificationService.dnd ? "Do not disturb is on" : "You're all caught up"
                    color: Theme.textMute
                    font.family: Theme.fontSans
                    font.pixelSize: 13
                }
            }
        }
    }
}
