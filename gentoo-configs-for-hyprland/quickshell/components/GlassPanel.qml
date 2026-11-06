import QtQuick
import qs.config

// Frosted-glass surface: translucent fill (Hyprland blurs what is behind it), hairline border,
// top sheen, an accent glow line along the top edge, and a soft ring shadow that stays outside
// the panel so it never darkens the glass itself.
Item {
    id: root

    property real radius: Theme.radius
    property color fill: Theme.glass
    property color borderColor: Theme.hairline
    property real shadowStrength: 1
    default property alias content: inner.data

    // soft shadow (rings outside the body only)
    Repeater {
        model: Theme.shadowPad
        Rectangle {
            required property int index
            x: -(index + 1)
            y: -(index + 1) + 3
            width: root.width + 2 * (index + 1)
            height: root.height + 2 * (index + 1)
            radius: root.radius + index + 1
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(0, 0, 0, 0.18 * Math.pow(1 - index / Theme.shadowPad, 2) * root.shadowStrength)
        }
    }

    Rectangle {
        id: body
        anchors.fill: parent
        radius: root.radius
        color: root.fill
        border.width: 1
        border.color: root.borderColor

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: root.radius - 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.07) }
                GradientStop { position: 0.4; color: Qt.rgba(1, 1, 1, 0.0) }
                GradientStop { position: 1.0; color: Theme.alpha(Theme.accent, 0.04) }
            }
        }

        Rectangle {
            x: root.radius
            y: 0
            width: parent.width - root.radius * 2
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.alpha(Theme.accent, 0) }
                GradientStop { position: 0.5; color: Theme.alpha(Theme.accent, 0.55) }
                GradientStop { position: 1.0; color: Theme.alpha(Theme.accent, 0) }
            }
        }
    }

    Item { id: inner; anchors.fill: parent }
}
