/*
 * Copyright (c) 2026 Future History Labs
 *
 * New file added to this fork of cool-retro-term
 * (https://github.com/Swordfish90/cool-retro-term). Licensed under the
 * GNU General Public License, version 3 (or, at your option, any later
 * version), same as the rest of this program — see gpl-3.0.txt.
 */
#ifndef PUSHTOTALK_H
#define PUSHTOTALK_H

#include <QObject>
#include <QString>
#include <QAudioInput>
#include <QMediaCaptureSession>
#include <QMediaRecorder>

class QProcess;

/**
 * Push-to-talk: hold Command+Option anywhere in the app (or press-and-hold
 * the mic button) to record from the microphone, then run it through a
 * user-configured speech-to-text command and drop the transcript into the
 * prompt bar.
 *
 * The Command+Option chord is caught with an application-wide event filter
 * rather than a QML Shortcut, because the terminal widget consumes almost
 * every keystroke itself (it has to, to support control sequences) and
 * would otherwise never let the chord reach a QML-level shortcut. Both keys
 * of the chord are pure modifiers (Qt::Key_Meta/Qt::Key_Alt), so unlike the
 * old Ctrl+Space combo there's no printable key to swallow — holding either
 * modifier alone never sends a character into the terminal.
 */
class PushToTalk : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool active READ isActive NOTIFY activeChanged)
    Q_PROPERTY(bool available READ isAvailable NOTIFY availableChanged)
    Q_PROPERTY(QString transcribeCommand READ transcribeCommand WRITE setTranscribeCommand NOTIFY transcribeCommandChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)

public:
    explicit PushToTalk(QObject *parent = nullptr);

    bool isActive() const { return m_active; }
    bool isAvailable() const;

    QString transcribeCommand() const { return m_transcribeCommand; }
    void setTranscribeCommand(const QString &command);

    QString statusMessage() const { return m_statusMessage; }

    Q_INVOKABLE void startPushToTalk();
    Q_INVOKABLE void stopPushToTalk();

    bool eventFilter(QObject *watched, QEvent *event) override;

signals:
    void activeChanged();
    void availableChanged();
    void transcribeCommandChanged();
    void statusMessageChanged();
    void transcriptReady(const QString &text);

private:
    void beginRecording();
    void endRecordingAndTranscribe();
    void setStatusMessage(const QString &message);

    bool m_active = false;
    bool m_metaDown = false;
    bool m_altDown = false;

    QString m_transcribeCommand;
    QString m_statusMessage;

    QAudioInput m_audioInput;
    QMediaCaptureSession m_captureSession;
    QMediaRecorder m_recorder;
    QString m_currentRecordingPath;
    QProcess *m_transcribeProcess = nullptr;
};

#endif // PUSHTOTALK_H
