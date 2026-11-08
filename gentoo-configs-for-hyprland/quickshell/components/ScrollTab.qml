import QtQuick
import QtQuick.Layouts
import qs.config

// Scrollable settings page. Children are stacked in a column.
Item {
    id: root

    default property alias content: col.data

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: col.implicitHeight + 8
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        ColumnLayout {
            id: col
            width: flick.width - 12
            spacing: 12
        }
    }

    Rectangle {
        visible: flick.visibleArea.heightRatio < 1
        x: root.width - 4
        y: flick.visibleArea.yPosition * root.height
        width: 3
        height: flick.visibleArea.heightRatio * root.height
        radius: 2
        color: Theme.alpha(Theme.accent, 0.45)
    }
}
