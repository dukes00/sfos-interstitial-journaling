import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    Label {
        anchors.centerIn: parent
        text: "ilog"
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeLarge
        font.family: "monospace"
    }

    CoverActionList {
        CoverAction {
            iconSource: "image://theme/icon-cover-new"
            onTriggered: {
                // Bring app to front and focus input
                pageStack.pop(null)
                activate()
            }
        }
    }
}
