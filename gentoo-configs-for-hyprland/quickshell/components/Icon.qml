import QtQuick
import qs.config

// Material Symbols Rounded glyph, addressed by ligature name ("volume_up", "wifi", ...).
Text {
    property string name: ""
    property int size: 18

    text: name
    font.family: Theme.fontIcon
    font.pixelSize: size
    color: Theme.text
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    renderType: Text.QtRendering
}
