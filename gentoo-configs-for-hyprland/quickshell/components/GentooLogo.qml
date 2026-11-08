import Quickshell
import QtQuick

// Gentoo logo from assets/gentoo.png (transparent background).
Image {
    source: "file://" + Quickshell.shellPath("assets/gentoo.png")
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
    asynchronous: true
}
