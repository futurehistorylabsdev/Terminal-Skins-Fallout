/*******************************************************************************
* A large prompt composer docked under the terminal, plus a push-to-talk
* microphone. Typing here and pressing Enter sends the text into the
* running session exactly as if it had been typed directly into the
* terminal above.
*******************************************************************************/
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property var session: null
    readonly property bool ptt: typeof pushToTalk !== "undefined"
    readonly property bool listening: ptt && pushToTalk.active

    implicitHeight: 150
    color: Qt.darker(appSettings.backgroundColor, 1.15)
    border.color: appSettings.frameColor
    border.width: 1

    Connections {
        target: root.ptt ? pushToTalk : null
        function onTranscriptReady(text) {
            const sep = promptField.text.length > 0 && !promptField.text.endsWith(" ") ? " " : ""
            promptField.text += sep + text
            promptField.cursorPosition = promptField.text.length
        }
    }

    function sendPrompt() {
        if (!session || promptField.text.length === 0)
            return
        session.sendText(promptField.text + "\n")
        promptField.text = ""
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            Label {
                text: qsTr("Prompt · Enter to send, Shift+Enter for a new line, hold Ctrl+Space or the mic button to talk")
                color: appSettings.fontColor
                opacity: 0.65
                font.family: "monospace"
                font.pixelSize: 11
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                TextArea {
                    id: promptField
                    placeholderText: qsTr("Type a prompt…")
                    placeholderTextColor: Qt.rgba(appSettings.fontColor.r, appSettings.fontColor.g, appSettings.fontColor.b, 0.4)
                    wrapMode: TextArea.Wrap
                    selectByMouse: true
                    font.family: "monospace"
                    font.pixelSize: 15
                    color: appSettings.fontColor
                    background: null

                    Keys.onPressed: function (event) {
                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                                && !(event.modifiers & Qt.ShiftModifier)) {
                            event.accepted = true
                            root.sendPrompt()
                        }
                    }
                }
            }

            Label {
                text: root.ptt ? pushToTalk.statusMessage : ""
                visible: text.length > 0
                color: appSettings.fontColor
                opacity: 0.8
                font.family: "monospace"
                font.pixelSize: 11
                Layout.fillWidth: true
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 10

            Rectangle {
                id: micButton
                Layout.alignment: Qt.AlignHCenter
                width: 54
                height: 54
                radius: 27
                color: root.listening ? appSettings.fontColor : "transparent"
                border.color: appSettings.fontColor
                border.width: 2

                // A plain vector mic glyph (no icon font/emoji dependency).
                Item {
                    anchors.centerIn: parent
                    width: 16
                    height: 26
                    Rectangle {
                        width: 14
                        height: 18
                        radius: 7
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: root.listening ? appSettings.backgroundColor : appSettings.fontColor
                    }
                    Rectangle {
                        width: 2
                        height: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        color: root.listening ? appSettings.backgroundColor : appSettings.fontColor
                    }
                }

                SequentialAnimation on opacity {
                    running: root.listening
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.55; duration: 500 }
                    NumberAnimation { from: 0.55; to: 1.0; duration: 500 }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.ptt
                    onPressed: pushToTalk.startPushToTalk()
                    onReleased: pushToTalk.stopPushToTalk()
                    onCanceled: pushToTalk.stopPushToTalk()
                }
            }

            Button {
                text: qsTr("Send")
                Layout.alignment: Qt.AlignHCenter
                onClicked: root.sendPrompt()
            }
        }
    }
}
