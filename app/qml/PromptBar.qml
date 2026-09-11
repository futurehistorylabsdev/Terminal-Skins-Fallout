/*******************************************************************************
* A large prompt composer docked under the terminal, styled as a rudimentary
* wall intercom unit: brushed-metal housing, a perforated speaker grille, a
* physical press-to-talk toggle, a pilot lamp, and a recessed "message slot"
* for the text. Purely a visual skin — the underlying behavior is unchanged:
* typing here and pressing Enter sends the text into the running session
* exactly as if it had been typed directly into the terminal above, and the
* grille/switch cluster is just a big press area over the same
* pushToTalk.startPushToTalk()/stopPushToTalk() calls (Ctrl+Space still
* works too, handled entirely on the C++ side).
*******************************************************************************/
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property var session: null
    readonly property bool ptt: typeof pushToTalk !== "undefined"
    readonly property bool listening: ptt && pushToTalk.active

    readonly property color housingColor: "#3c3a36"
    readonly property color housingDark: Qt.darker(housingColor, 1.9)
    readonly property color housingLight: Qt.lighter(housingColor, 1.5)
    readonly property color metalHi: "#d8d8d4"
    readonly property color metalLo: "#4a4a46"

    implicitHeight: 200
    radius: 3
    border.color: housingDark
    border.width: 2
    gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.lighter(housingColor, 1.2) }
        GradientStop { position: 0.06; color: housingColor }
        GradientStop { position: 0.94; color: housingColor }
        GradientStop { position: 1.0; color: Qt.darker(housingColor, 1.4) }
    }

    // Thin bevel lines top/bottom to sell a stamped-metal panel.
    Rectangle {
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 2 }
        height: 1
        color: root.housingLight
        opacity: 0.5
    }
    Rectangle {
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 2 }
        height: 1
        color: "black"
        opacity: 0.35
    }

    // Faint engraved title plate.
    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 3
        width: plateLabel.width
        height: plateLabel.height
        Text {
            text: "C L A U D E   I N T E R C O M"
            font.family: "sans-serif"
            font.bold: true
            font.pixelSize: 10
            color: root.housingDark
            x: 1
            y: 1
        }
        Text {
            id: plateLabel
            text: "C L A U D E   I N T E R C O M"
            font.family: "sans-serif"
            font.bold: true
            font.pixelSize: 10
            color: root.housingLight
            opacity: 0.8
        }
    }

    // Corner screws.
    Repeater {
        model: 4
        Item {
            readonly property bool leftSide: index % 2 === 0
            readonly property bool topSide: index < 2
            x: leftSide ? 7 : root.width - 7 - width
            y: topSide ? 16 : root.height - 7 - height
            width: 11
            height: 11

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                border.color: "#202020"
                border.width: 1
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.metalHi }
                    GradientStop { position: 0.55; color: "#8a8a86" }
                    GradientStop { position: 1.0; color: root.metalLo }
                }
            }
            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 3
                height: 1.4
                rotation: 35
                color: "#262626"
            }
        }
    }

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
        anchors.margins: 14
        anchors.topMargin: 22
        spacing: 14

        // ---- recessed "message slot" ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            Label {
                text: qsTr("MESSAGE")
                color: root.housingLight
                opacity: 0.7
                font.family: "sans-serif"
                font.bold: true
                font.pixelSize: 10
                Layout.fillWidth: true
            }

            // Recessed bezel around the actual "screen".
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 4
                color: root.housingDark
                border.color: "black"
                border.width: 1

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 3
                    color: "transparent"
                    border.color: root.housingLight
                    border.width: 1
                    opacity: 0.35
                }

                Rectangle {
                    id: screen
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: 2
                    color: Qt.darker(appSettings.backgroundColor, 1.1)
                    border.color: "black"
                    border.width: 1

                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 8
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
                }
            }

            Label {
                text: root.ptt ? pushToTalk.statusMessage : ""
                visible: text.length > 0
                color: root.housingLight
                opacity: 0.85
                font.family: "sans-serif"
                font.pixelSize: 10
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        // ---- intercom control cluster ----
        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillHeight: true
            spacing: 8

            Item { Layout.fillHeight: true }

            // Speaker/mic grille + toggle switch: one big press target.
            Item {
                id: talkCluster
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: clusterColumn.implicitWidth
                implicitHeight: clusterColumn.implicitHeight

            ColumnLayout {
                id: clusterColumn
                anchors.fill: parent
                spacing: 6

                Item {
                    id: grille
                    Layout.alignment: Qt.AlignHCenter
                    width: 68
                    height: 68

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        border.color: "black"
                        border.width: 2
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.lighter(root.housingColor, 1.35) }
                            GradientStop { position: 0.55; color: root.housingColor }
                            GradientStop { position: 1.0; color: root.housingDark }
                        }
                    }

                    // Concentric-ring perforation pattern.
                    Repeater {
                        model: 1 + 6 + 12
                        Rectangle {
                            readonly property int ring: index === 0 ? 0 : (index <= 6 ? 1 : 2)
                            readonly property int ringIndex: index === 0 ? 0 : (index <= 6 ? index - 1 : index - 7)
                            readonly property int ringCount: ring === 1 ? 6 : 12
                            readonly property real ringRadius: ring === 0 ? 0 : (ring === 1 ? 15 : 26)
                            readonly property real angle: (ringIndex / ringCount) * Math.PI * 2 + (ring === 2 ? 0.26 : 0)
                            width: 4
                            height: 4
                            radius: 2
                            color: "black"
                            opacity: 0.55
                            x: grille.width / 2 + Math.cos(angle) * ringRadius - width / 2
                            y: grille.height / 2 + Math.sin(angle) * ringRadius - height / 2
                        }
                    }

                    // Pilot lamp, top-center of the grille bezel.
                    Item {
                        id: lampHousing
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: -9
                        width: 16
                        height: 16

                        Repeater {
                            model: 3
                            Rectangle {
                                readonly property real haloScale: 1.0 + (index + 1) * 0.55
                                anchors.centerIn: parent
                                width: lampHousing.width * haloScale
                                height: lampHousing.height * haloScale
                                radius: width / 2
                                color: appSettings.fontColor
                                opacity: root.listening ? (0.22 - index * 0.06) : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }
                        }

                        Rectangle {
                            id: lampGlass
                            anchors.fill: parent
                            radius: width / 2
                            border.color: "#161616"
                            border.width: 1.5
                            color: root.listening ? appSettings.fontColor : Qt.darker(appSettings.fontColor, 3.4)

                            SequentialAnimation on opacity {
                                running: root.listening
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 0.6; duration: 450 }
                                NumberAnimation { from: 0.6; to: 1.0; duration: 450 }
                            }
                        }
                    }
                }

                // Toggle track + lever, labeled like a real fixture.
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    width: 34
                    height: 46

                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: root.housingDark
                        border.color: "black"
                        border.width: 1
                    }

                    Rectangle {
                        id: lever
                        width: parent.width - 6
                        height: 20
                        radius: 4
                        x: 3
                        y: root.listening ? parent.height - height - 3 : 3
                        border.color: "#262626"
                        border.width: 1
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: root.metalHi }
                            GradientStop { position: 0.5; color: "#8f8f8b" }
                            GradientStop { position: 1.0; color: root.metalLo }
                        }
                        Behavior on y { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - 10
                            height: 2
                            color: "#3a3a3a"
                        }
                    }
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("PRESS TO TALK")
                    color: root.housingLight
                    opacity: 0.75
                    font.family: "sans-serif"
                    font.bold: true
                    font.pixelSize: 9
                }
            } // clusterColumn

                MouseArea {
                    anchors.fill: parent
                    enabled: root.ptt
                    onPressed: pushToTalk.startPushToTalk()
                    onReleased: pushToTalk.stopPushToTalk()
                    onCanceled: pushToTalk.stopPushToTalk()
                }
            } // talkCluster

            Item { Layout.fillHeight: true }

            // Physical-looking send button.
            Rectangle {
                id: sendButton
                Layout.alignment: Qt.AlignHCenter
                width: 68
                height: 30
                radius: 4
                border.color: "black"
                border.width: 1
                gradient: Gradient {
                    GradientStop { position: 0.0; color: sendArea.pressed ? "#6a6a66" : Qt.lighter(root.housingColor, 1.5) }
                    GradientStop { position: 1.0; color: sendArea.pressed ? "#4a4a46" : root.housingColor }
                }

                Text {
                    anchors.centerIn: parent
                    text: qsTr("SEND")
                    font.family: "sans-serif"
                    font.bold: true
                    font.pixelSize: 11
                    color: root.metalHi
                }

                MouseArea {
                    id: sendArea
                    anchors.fill: parent
                    onClicked: root.sendPrompt()
                }
            }
        }
    }
}
