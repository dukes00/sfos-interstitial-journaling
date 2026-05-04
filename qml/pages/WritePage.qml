import QtQuick 2.0
import Sailfish.Silica 1.0
import org.duke.ilog 1.0

Page {
    id: page

    JournalStore {
        id: journal
        Component.onCompleted: loadEntries(100)
    }

    // Scroll to bottom when entries load or new entry added
    Timer {
        id: scrollTimer
        interval: 50
        onTriggered: listView.positionViewAtEnd()
    }

    function scrollToBottom() {
        scrollTimer.restart()
    }

    // Save current input
    function saveEntry() {
        var text = inputField.text.trim()
        if (text.length === 0)
            return

        journal.appendEntry(text)
        inputField.text = ""
        inputField.placeholderText = journal.randomPrompt()
        scrollToBottom()

        // Brief flash overlay
        flashAnimation.start()
    }

    // Flash overlay for new entries
    Rectangle {
        id: flashOverlay
        anchors.fill: listView
        color: Theme.highlightBackgroundColor
        opacity: 0
        visible: opacity > 0
        z: 10

        NumberAnimation on opacity {
            id: flashAnimation
            from: 0.15
            to: 0
            duration: 1200
            easing.type: Easing.OutQuad
        }
    }

    // The entry list
    SilicaListView {
        id: listView
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: inputArea.top
        }
        clip: true

        model: journal

        // Day divider header
        header: Item { width: listView.width; height: Theme.paddingLarge }

        delegate: ListItem {
            id: delegate
            contentHeight: entryColumn.height + Theme.paddingSmall

            Column {
                id: entryColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                }

                // Day divider (shown when isNewDay)
                Item {
                    width: parent.width
                    height: isNewDay ? dividerLabel.height + Theme.paddingLarge : 0
                    visible: isNewDay

                    // Left line
                    Rectangle {
                        anchors {
                            left: parent.left
                            right: dividerLabel.left
                            verticalCenter: dividerLabel.verticalCenter
                            rightMargin: Theme.paddingSmall
                        }
                        height: 1
                        color: Theme.secondaryColor
                        opacity: 0.3
                    }

                    Label {
                        id: dividerLabel
                        anchors.centerIn: parent
                        text: dateDisplay
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: "monospace"
                    }

                    // Right line
                    Rectangle {
                        anchors {
                            left: dividerLabel.right
                            right: parent.right
                            verticalCenter: dividerLabel.verticalCenter
                            leftMargin: Theme.paddingSmall
                        }
                        height: 1
                        color: Theme.secondaryColor
                        opacity: 0.3
                    }
                }

                // Entry row
                Row {
                    id: entryRow
                    spacing: Theme.paddingMedium

                    Label {
                        id: timeLabel
                        text: timeDisplay
                        color: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: "monospace"
                    }
                    Label {
                        text: entryText
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: "monospace"
                        width: entryColumn.width - timeLabel.width - entryRow.spacing
                        wrapMode: Text.Wrap
                    }
                }
            }


        }

        VerticalScrollDecorator {}
    }

    // Input area pinned at bottom
    Item {
        id: inputArea
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: inputRow.height + Theme.paddingMedium

        // Separator line
        Rectangle {
            anchors.top: parent.top
            width: parent.width
            height: 1
            color: Theme.highlightBackgroundColor
            opacity: 0.3
        }

        Row {
            id: inputRow
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: Theme.horizontalPageMargin
                rightMargin: Theme.horizontalPageMargin
                verticalCenter: parent.verticalCenter
            }
            spacing: Theme.paddingSmall

            TextField {
                id: inputField
                width: parent.width - saveBtn.width - Theme.paddingSmall
                placeholderText: journal.randomPrompt()
                label: "ilog"
                font.family: "monospace"
                focus: true
                EnterKey.enabled: text.trim().length > 0
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: saveEntry()
                Component.onCompleted: forceActiveFocus()
            }

            IconButton {
                id: saveBtn
                anchors.verticalCenter: inputField.verticalCenter
                icon.source: "image://theme/icon-m-enter-accept"
                enabled: inputField.text.trim().length > 0
                onClicked: saveEntry()
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            inputField.forceActiveFocus()
            scrollToBottom()
        }
    }
}
