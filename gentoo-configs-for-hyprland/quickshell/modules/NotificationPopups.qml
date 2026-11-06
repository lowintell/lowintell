import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.components
import qs.config
import qs.services

// Toast notifications, top-right under the bar. Hidden while the notification centre is open.
PanelWindow {
    id: win

    readonly property int cardWidth: 360

    screen: UiState.screen
    visible: NotificationService.popups.count > 0 && UiState.active !== "notifs"
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: cardWidth + Theme.shadowPad * 2
    implicitHeight: Math.max(1, stack.contentHeight + Theme.shadowPad * 2)

    anchors { top: true; right: true }
    margins {
        top: Theme.barMargin + Theme.barHeight + 8 - Theme.shadowPad
        right: Theme.barMargin - Theme.shadowPad
    }

    WlrLayershell.namespace: "qsglass-toast"
    WlrLayershell.layer: WlrLayer.Overlay

    mask: Region { item: stack }

    ListView {
        id: stack
        x: Theme.shadowPad
        y: Theme.shadowPad
        width: win.cardWidth
        height: contentHeight
        interactive: false
        spacing: 10
        model: NotificationService.popups

        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animMed }
            NumberAnimation { property: "x"; from: 70; to: 0; duration: Theme.animMed + 80; easing.type: Easing.OutCubic }
        }
        remove: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: Theme.animMed }
            NumberAnimation { property: "x"; to: 70; duration: Theme.animMed }
        }
        displaced: Transition {
            NumberAnimation { properties: "y"; duration: Theme.animMed; easing.type: Easing.OutCubic }
        }

        delegate: Item {
            id: toast
            width: stack.width
            height: glass.height

            GlassPanel {
                id: glass
                width: parent.width
                height: card.implicitHeight
                radius: Theme.radiusSm + 4
                borderColor: model.urgency === 2 ? Theme.alpha(Theme.bad, 0.7) : Theme.hairline

                NotificationCard {
                    id: card
                    anchors.fill: parent
                    framed: false
                    nid: model.nid
                    appName: model.appName
                    appIcon: model.appIcon
                    image: model.image
                    summary: model.summary
                    body: model.body
                    urgency: model.urgency
                    time: model.time
                    onCloseRequested: NotificationService.dismissPopup(model.nid)
                    onActivated: { NotificationService.invokeDefault(model.nid); NotificationService.dismissPopup(model.nid); }
                }

                HoverHandler { id: hover }
            }

            Timer {
                interval: model.timeout
                running: model.timeout > 0 && !hover.hovered
                onTriggered: NotificationService.dismissPopup(model.nid)
            }
        }
    }
}
