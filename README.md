# claude-retro-term

A fork of [cool-retro-term](https://github.com/Swordfish90/cool-retro-term)
(the CRT-styled Qt terminal emulator) set up as a dedicated skin for
**Claude Code**: it launches `claude` by default, and adds a large prompt
composer under the terminal plus a push-to-talk microphone.

## What's different from upstream

- **Launches `claude` by default.** If `claude` is on `PATH` and you don't
  pass `-e`, it runs that instead of your shell. Falls back to a normal
  shell if `claude` isn't found, so it still works as a plain terminal.
- **A prompt bar under the terminal.** A large, multi-line text box styled
  to match whichever CRT color profile is active. Enter sends the text into
  the running session exactly as if you'd typed it directly into the
  terminal (Shift+Enter for a newline). The terminal above still behaves
  like a normal terminal — you can type/scroll/Ctrl+C there directly too.
- **Push-to-talk.** Hold **Ctrl+Space** anywhere in the window, or
  press-and-hold the mic button in the prompt bar, to record from the
  microphone; release to transcribe and drop the text into the prompt box.
  The chord is caught application-wide (not a QML shortcut), specifically
  because the terminal widget normally consumes every keystroke itself —
  a bare Space, or Ctrl combined with any other key, is untouched and
  behaves exactly as it always did.
- **A Qt 6.4 shader-baking compatibility fix.** Upstream's checked-in
  `.qsb` shader binaries are baked for Qt 6.5+; this fork regenerates them
  without the newer `--qt6` flag so it also builds and runs on Qt 6.4 (e.g.
  stock Ubuntu 24.04), in addition to newer Qt6. One `QRegularExpression`
  compatibility fix in `qmltermwidget` for the same reason.

### Push-to-talk needs a speech-to-text command

There's no bundled transcription engine — push-to-talk records a WAV clip
and hands it to a command you configure yourself, in **Settings →
Advanced → Push-to-talk**. Use `%f` in the command for the recorded file's
path (or leave it out and the path is appended). For example, with
[whisper.cpp](https://github.com/ggml-org/whisper.cpp):

```
whisper-cli -m /path/to/ggml-base.en.bin -f %f --no-timestamps -otxt -of -
```

Until that's set, the mic button still shows you when the chord is caught
(so you can confirm the shortcut works), but says so instead of recording.

## Requirements & building

Same as upstream: **Linux or macOS, Qt6** (this fork also runs on Qt 6.4).
Needs the `multimedia` Qt module additionally (for the mic).

```bash
git clone <this repo>
cd claude-retro-term
qmake6 cool-retro-term.pro   # or qmake, depending on your distro
make -j$(nproc)
./cool-retro-term
```

`-e <cmd>` still works exactly as in upstream, to launch something other
than `claude`:

```bash
./cool-retro-term -e zsh
```

## Everything else

This fork otherwise keeps all of cool-retro-term's own features (CRT
shader effects, color profiles, fonts, tabs, settings) — see below for
upstream's own documentation.

## License & attribution

This is a derivative work, and stays under the same license as the
project it's built on:

- **[cool-retro-term](https://github.com/Swordfish90/cool-retro-term)**,
  by Filippo Scognamiglio — GNU GPL v2/v3-or-later (`gpl-2.0.txt`,
  `gpl-3.0.txt`). Everything in this repo not called out below is
  upstream's, unmodified.
- **[qmltermwidget](https://github.com/Swordfish90/qmltermwidget)**
  (vendored in `qmltermwidget/`), also by Filippo Scognamiglio, itself
  built on KDE's Konsole (Robert Knight, Lars Doelle, and other Konsole
  contributors) — GPL/LGPL per file, see `qmltermwidget/LICENSE*`.
- **[KDSingleApplication](https://github.com/KDAB/KDSingleApplication)**
  (vendored in `KDSingleApplication/`), by Klarälvdalens Datakonsult AB
  (KDAB) — MIT, see `KDSingleApplication/LICENSE.txt`.
- **This fork's changes** — the tool-detected color scheme, the
  intercom-styled prompt bar (`app/qml/PromptBar.qml`), push-to-talk
  (`app/pushtotalk.cpp`/`.h`), the Qt 6.4 shader-baking fix, and the
  default-launch behavior — © 2026 **Future History Labs**, licensed
  under the same GPL as the rest of the program (GPL is copyleft: a
  derivative work can't be relicensed to something more permissive).
  Modified files carry a note saying so near their existing copyright
  header; the new files carry their own header.

---

|> Default Amber|C:\ IBM DOS|$ Default Green|
|---|---|---|
|![Default Amber Cool Retro Term](https://user-images.githubusercontent.com/121322/32070717-16708784-ba42-11e7-8572-a8fcc10d7f7d.gif)|![IBM DOS](https://user-images.githubusercontent.com/121322/32070716-16567e5c-ba42-11e7-9e64-ba96dfe9b64d.gif)|![Default Green Cool Retro Term](https://user-images.githubusercontent.com/121322/32070715-163a1c94-ba42-11e7-80bb-41fbf10fc634.gif)|

## Description
cool-retro-term is a terminal emulator which mimics the look and feel of the old cathode tube screens.
It has been designed to be eye-candy, customizable, and reasonably lightweight.

It uses the QML port of qtermwidget (Konsole): https://github.com/Swordfish90/qmltermwidget.

This terminal emulator works under Linux and macOS and requires Qt6.

Settings such as colors, fonts, and effects can be accessed via context menu.

## Screenshots
![Image](<https://i.imgur.com/TNumkDn.png>)
![Image](<https://i.imgur.com/hfjWOM4.png>)
![Image](<https://i.imgur.com/GYRDPzJ.jpg>)

## Install

If you want to get a hold of the latest version, just go to the Releases page and grab the latest AppImage (Linux) or dmg (macOS).

Alternatively, most distributions such as Ubuntu, Fedora or Arch already package cool-retro-term in their official repositories.

## Building

Check out the wiki and follow the instructions on how to build it on [Linux](https://github.com/Swordfish90/cool-retro-term/wiki/Build-Instructions-(Linux)) and [macOS](https://github.com/Swordfish90/cool-retro-term/wiki/Build-Instructions-(macOS)).
