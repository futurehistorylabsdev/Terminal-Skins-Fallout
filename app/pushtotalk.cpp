#include "pushtotalk.h"

#include <QCoreApplication>
#include <QKeyEvent>
#include <QStandardPaths>
#include <QDir>
#include <QDateTime>
#include <QUrl>
#include <QFile>
#include <QProcess>
#include <QMediaFormat>

PushToTalk::PushToTalk(QObject *parent)
    : QObject(parent)
{
    m_captureSession.setAudioInput(&m_audioInput);
    m_captureSession.setRecorder(&m_recorder);

    QMediaFormat format(QMediaFormat::Wave);
    m_recorder.setMediaFormat(format);

    // Application-wide, so the chord works no matter which item has focus.
    qApp->installEventFilter(this);
}

bool PushToTalk::isAvailable() const
{
    return !m_transcribeCommand.trimmed().isEmpty();
}

void PushToTalk::setTranscribeCommand(const QString &command)
{
    if (m_transcribeCommand == command)
        return;
    m_transcribeCommand = command;
    emit transcribeCommandChanged();
    emit availableChanged();
}

void PushToTalk::setStatusMessage(const QString &message)
{
    if (m_statusMessage == message)
        return;
    m_statusMessage = message;
    emit statusMessageChanged();
}

bool PushToTalk::eventFilter(QObject *watched, QEvent *event)
{
    const QEvent::Type type = event->type();
    if (type == QEvent::KeyPress || type == QEvent::KeyRelease) {
        auto *keyEvent = static_cast<QKeyEvent *>(event);

        if (!keyEvent->isAutoRepeat()) {
            if (keyEvent->key() == Qt::Key_Control) {
                m_ctrlDown = (type == QEvent::KeyPress);
            } else if (keyEvent->key() == Qt::Key_Space) {
                m_spaceDown = (type == QEvent::KeyPress);
            }

            const bool comboActive = m_spaceDown && m_ctrlDown;
            if (comboActive && !m_active) {
                startPushToTalk();
            } else if (!comboActive && m_active) {
                stopPushToTalk();
            }
        }

        // Swallow Space while Ctrl is held so the chord never reaches the
        // terminal (or any text field) as a literal space character. A bare
        // space, or Ctrl on its own, still behaves completely normally.
        if (keyEvent->key() == Qt::Key_Space && m_ctrlDown) {
            return true;
        }
    }
    return QObject::eventFilter(watched, event);
}

void PushToTalk::startPushToTalk()
{
    if (m_active)
        return;
    m_active = true;
    emit activeChanged();
    beginRecording();
}

void PushToTalk::stopPushToTalk()
{
    if (!m_active)
        return;
    m_active = false;
    emit activeChanged();
    endRecordingAndTranscribe();
}

void PushToTalk::beginRecording()
{
    if (!isAvailable()) {
        setStatusMessage(tr("Set a speech-to-text command in Settings → Advanced to use push-to-talk."));
        return;
    }

    const QString tempDir = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    m_currentRecordingPath = QDir(tempDir).filePath(
        QStringLiteral("crt-ptt-%1.wav").arg(QDateTime::currentMSecsSinceEpoch()));

    m_recorder.setOutputLocation(QUrl::fromLocalFile(m_currentRecordingPath));
    setStatusMessage(tr("Listening…"));
    m_recorder.record();
}

void PushToTalk::endRecordingAndTranscribe()
{
    if (!isAvailable())
        return;

    m_recorder.stop();
    setStatusMessage(tr("Transcribing…"));

    if (m_transcribeProcess) {
        m_transcribeProcess->kill();
        m_transcribeProcess->deleteLater();
        m_transcribeProcess = nullptr;
    }

    const QString path = m_currentRecordingPath;
    QString resolvedCommand = m_transcribeCommand;
    const QString quotedPath = QStringLiteral("\"%1\"").arg(path);
    if (resolvedCommand.contains(QStringLiteral("%f"))) {
        resolvedCommand.replace(QStringLiteral("%f"), quotedPath);
    } else {
        resolvedCommand += QStringLiteral(" ") + quotedPath;
    }

    m_transcribeProcess = new QProcess(this);
    connect(m_transcribeProcess, &QProcess::finished, this,
            [this, path](int exitCode, QProcess::ExitStatus status) {
        Q_UNUSED(status)
        const QString output = QString::fromUtf8(m_transcribeProcess->readAllStandardOutput()).trimmed();
        if (exitCode == 0 && !output.isEmpty()) {
            emit transcriptReady(output);
            setStatusMessage(QString());
        } else {
            setStatusMessage(tr("Speech-to-text command failed."));
        }
        QFile::remove(path);
        m_transcribeProcess->deleteLater();
        m_transcribeProcess = nullptr;
    });

    m_transcribeProcess->start(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), resolvedCommand});
}
