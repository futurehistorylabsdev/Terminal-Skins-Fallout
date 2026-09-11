/*******************************************************************************
* Copyright (c) 2013-2021 "Filippo Scognamiglio"
* https://github.com/Swordfish90/cool-retro-term
*
* Modified 2026 by Future History Labs: docked the new PromptBar
* underneath the terminal, and added per-window live claude/codex/other
* color tracking (liveTool/effectiveFontColor/updateLiveTool below) so
* multiple windows running different tools each show their own color
* instead of fighting over one shared setting.
*
* This file is part of cool-retro-term.
*
* cool-retro-term is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*******************************************************************************/
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "menus"
import "utils.js" as Utils

ApplicationWindow {
    id: terminalWindow

    width: 1024
    height: 768

    // Show the window once it is ready.
    Component.onCompleted: {
        visible = true
    }

    minimumWidth: 320
    minimumHeight: 240

    visible: false

    property bool fullscreen: false
    onFullscreenChanged: visibility = (fullscreen ? Window.FullScreen : Window.Windowed)

    menuBar: WindowMenu { }

    property real normalizedWindowScale: 1024 / ((0.5 * width + 0.5 * height))

    // Modified 2026 by Future History Labs: this window's own live tool
    // color, kept separate from appSettings' shared/persisted profile
    // colors so a second window running a different tool doesn't fight
    // this one over a single shared value (see PromptBar's polling timer,
    // which calls updateLiveTool() with its session's foreground process
    // name). Mirrors ApplicationSettings.qml's own fontColor/backgroundColor
    // mix formula, just fed this window's tool color instead of the shared
    // _fontColor, so the CRT look (contrast, background tint) matches
    // exactly - only which color is live differs per window.
    property string liveTool: "other"
    readonly property bool toolColorActive: !appSettings.explicitProfileSelected
    readonly property string _effectiveRawFontColor: toolColorActive
        ? appSettings.toolColors[liveTool] : appSettings._fontColor
    readonly property real effectiveChromaColor: toolColorActive ? 0.0 : appSettings.chromaColor
    readonly property real effectiveSaturationColor: toolColorActive ? 0.0 : appSettings.saturationColor
    readonly property color _effectiveSaturatedColor: Utils.mix(
        Utils.strToColor(_effectiveRawFontColor), Utils.strToColor("#FFFFFF"),
        (effectiveSaturationColor * 0.5))
    readonly property color effectiveFontColor: Utils.mix(
        Utils.strToColor(appSettings._backgroundColor), _effectiveSaturatedColor,
        (0.7 + (appSettings.contrast * 0.3)))
    readonly property color effectiveBackgroundColor: Utils.mix(
        _effectiveSaturatedColor, Utils.strToColor(appSettings._backgroundColor),
        (0.7 + (appSettings.contrast * 0.3)))

    function updateLiveTool(processName) {
        liveTool = appSettings.detectToolFromProcessName(processName)
    }

    color: "#00000000"

    title: terminalTabs.currentTitle

    Action {
        id: fullscreenAction
        text: qsTr("Fullscreen")
        enabled: !appSettings.isMacOS
        shortcut: StandardKey.FullScreen
        onTriggered: fullscreen = !fullscreen
        checkable: true
        checked: fullscreen
    }
    Action {
        id: newWindowAction
        text: qsTr("New Window")
        shortcut: appSettings.isMacOS ? "Meta+N" : "Ctrl+Shift+N"
        onTriggered: appRoot.createWindow()
    }
    Action {
        id: quitAction
        text: qsTr("Quit")
        shortcut: appSettings.isMacOS ? StandardKey.Close : "Ctrl+Shift+Q"
        onTriggered: terminalWindow.close()
    }
    Action {
        id: showsettingsAction
        text: qsTr("Settings")
        onTriggered: {
            settingsWindow.show()
            settingsWindow.requestActivate()
            settingsWindow.raise()
        }
    }
    Action {
        id: copyAction
        text: qsTr("Copy")
        shortcut: appSettings.isMacOS ? StandardKey.Copy : "Ctrl+Shift+C"
    }
    Action {
        id: pasteAction
        text: qsTr("Paste")
        shortcut: appSettings.isMacOS ? StandardKey.Paste : "Ctrl+Shift+V"
    }
    Action {
        id: zoomIn
        text: qsTr("Zoom In")
        shortcut: StandardKey.ZoomIn
        onTriggered: appSettings.incrementScaling()
    }
    Action {
        id: zoomOut
        text: qsTr("Zoom Out")
        shortcut: StandardKey.ZoomOut
        onTriggered: appSettings.decrementScaling()
    }
    Action {
        id: showAboutAction
        text: qsTr("About")
        onTriggered: {
            aboutDialog.show()
            aboutDialog.requestActivate()
            aboutDialog.raise()
        }
    }
    Action {
        id: newTabAction
        text: qsTr("New Tab")
        shortcut: appSettings.isMacOS ? "Meta+T" : "Ctrl+Shift+T"
        onTriggered: terminalTabs.addTab()
    }
    Action {
        id: closeTabAction
        text: qsTr("Close Tab")
        shortcut: appSettings.isMacOS ? "Meta+W" : "Ctrl+Shift+W"
        onTriggered: terminalTabs.closeTab(terminalTabs.currentIndex)
    }
    Shortcut {
        sequence: appSettings.isMacOS ? "Meta+1" : "Alt+1"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 0) terminalTabs.currentIndex = 0
    }
    Shortcut {
        sequence: appSettings.isMacOS ? "Meta+2" : "Alt+2"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 1) terminalTabs.currentIndex = 1
    }
    Shortcut {
        sequence: appSettings.isMacOS ? "Meta+3" : "Alt+3"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 2) terminalTabs.currentIndex = 2
    }
    Shortcut {
        sequence: appSettings.isMacOS ? "Meta+4" : "Alt+4"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 3) terminalTabs.currentIndex = 3
    }
    Shortcut {
        sequence: appSettings.isMacOS ? "Meta+5" : "Alt+5"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 4) terminalTabs.currentIndex = 4
    }
    Shortcut {
        sequence: appSettings.isMacOS ? "Meta+6" : "Alt+6"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 5) terminalTabs.currentIndex = 5
    }
    Shortcut {
        sequence: appSettings.isMacOS ? "Meta+7" : "Alt+7"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 6) terminalTabs.currentIndex = 6
    }
    Shortcut {
        sequence: appSettings.isMacOS ? "Meta+8" : "Alt+8"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 7) terminalTabs.currentIndex = 7
    }
    Shortcut {
        sequence: appSettings.isMacOS ? "Meta+9" : "Alt+9"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 8) terminalTabs.currentIndex = 8
    }
    ColumnLayout {
        width: parent.width
        height: (parent.height + Math.abs(y))
        spacing: 0

        TerminalTabs {
            id: terminalTabs
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        PromptBar {
            id: promptBar
            Layout.fillWidth: true
            session: (terminalTabs.currentTerminalContainer && terminalTabs.currentTerminalContainer.mainTerminal)
                     ? terminalTabs.currentTerminalContainer.mainTerminal.session : null
        }
    }
    Loader {
        anchors.centerIn: parent
        active: appSettings.showTerminalSize
        sourceComponent: SizeOverlay {
            z: 3
            terminalSize: terminalTabs.terminalSize
        }
    }
    onClosing: {
        appRoot.closeWindow(terminalWindow)
    }
}
