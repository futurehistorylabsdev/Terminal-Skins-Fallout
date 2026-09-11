/*
 * This file is part of cool-retro-term (https://github.com/Swordfish90/cool-retro-term),
 * by Filippo Scognamiglio. Licensed under the GNU General Public License,
 * version 3 (or, at your option, any later version) — see gpl-3.0.txt.
 *
 * Modified 2026 by Future History Labs: default-launch `claude`/`codex`
 * when found on PATH and no -e is given, and expose "activeTool" plus
 * the PushToTalk object to QML.
 */
#include <QtQml/QQmlApplicationEngine>
#include <QtGui/QGuiApplication>

#include <QQmlContext>
#include <QStringList>

#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>

#include <QtWidgets/QApplication>
#include <QIcon>
#include <QQuickStyle>
#include <QtQml/qqml.h>

#include <kdsingleapplication.h>

#include <QDebug>
#include <stdlib.h>

#include <QLoggingCategory>

#include <fileio.h>
#include <fontlistmodel.h>
#include <fontmanager.h>
#include <pushtotalk.h>

#if defined(Q_OS_MAC)
#include <CoreFoundation/CoreFoundation.h>
#include <QStyleFactory>
#include <QMenu>
#endif

QString getNamedArgument(QStringList args, QString name, QString defaultName)
{
    int index = args.indexOf(name);
    return (index != -1) ? args[index + 1] : QString(defaultName);
}

QString getNamedArgument(QStringList args, QString name)
{
    return getNamedArgument(args, name, "");
}

int main(int argc, char *argv[])
{
    // Some environmental variable are necessary on certain platforms.
    // Disable Connections slot warnings
    QLoggingCategory::setFilterRules("qt.qml.connections.warning=false");
    QGuiApplication::setHighDpiScaleFactorRoundingPolicy(Qt::HighDpiScaleFactorRoundingPolicy::Round);

// #if defined (Q_OS_LINUX)
//     setenv("QSG_RENDER_LOOP", "threaded", 0);
// #endif

#if defined(Q_OS_MAC)
    // This allows UTF-8 characters usage in OSX.
    setenv("LC_CTYPE", "UTF-8", 1);

    // Ensure key repeat works for letter keys (disable macOS press-and-hold for this app).
    CFPreferencesSetAppValue(CFSTR("ApplePressAndHoldEnabled"), kCFBooleanFalse, kCFPreferencesCurrentApplication);
    CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);

    // Qt6 macOS default look is still lacking, so let's force Fusion for now
    QQuickStyle::setStyle(QStringLiteral("Fusion"));
#endif

    if (argc>1 && (!strcmp(argv[1],"-h") || !strcmp(argv[1],"--help"))) {
        QTextStream cout(stdout, QIODevice::WriteOnly);
        cout << "Usage: " << argv[0] << " [--default-settings] [--workdir <dir>] [--program <prog>] [-p|--profile <prof>] [--fullscreen] [-h|--help]" << Qt::endl;
        cout << "  --default-settings  Run cool-retro-term with the default settings" << Qt::endl;
        cout << "  --workdir <dir>     Change working directory to 'dir'" << Qt::endl;
        cout << "  -e <cmd>            Command to execute. This option will catch all following arguments, so use it as the last option." << Qt::endl;
        cout << "                      Defaults to `claude` when it's on PATH, else `codex`, if no -e is given." << Qt::endl;
        cout << "                      The color scheme follows whichever of those actually runs (orange for" << Qt::endl;
        cout << "                      claude, classic green for codex, white for anything else) unless -p/--profile" << Qt::endl;
        cout << "                      is given explicitly." << Qt::endl;
        cout << "  --fullscreen        Run cool-retro-term in fullscreen." << Qt::endl;
        cout << "  -p|--profile <prof> Run cool-retro-term with the given profile (overrides the tool-based color)." << Qt::endl;
        cout << "  -h|--help           Print this help." << Qt::endl;
        cout << "  --verbose           Print additional information such as profiles and settings." << Qt::endl;
        return 0;
    }

    QString appVersion(QStringLiteral(APP_VERSION));

    if (argc>1 && (!strcmp(argv[1],"-v") || !strcmp(argv[1],"--version"))) {
        QTextStream cout(stdout, QIODevice::WriteOnly);
        cout << "cool-retro-term " << appVersion << Qt::endl;
        return 0;
    }

    QApplication app(argc, argv);
    app.setAttribute(Qt::AA_MacDontSwapCtrlAndMeta, true);
    app.setApplicationName(QStringLiteral("cool-retro-term"));
    app.setOrganizationName(QStringLiteral("cool-retro-term"));
    app.setOrganizationDomain(QStringLiteral("cool-retro-term"));
    app.setApplicationVersion(appVersion);

    KDSingleApplication singleApp(QStringLiteral("cool-retro-term"));

    if (!singleApp.isPrimaryInstance()) {
        if (singleApp.sendMessage("new-window"))
            return 0;
        qWarning() << "KDSingleApplication: primary not reachable, continuing as independent instance.";
    }

    QQmlApplicationEngine engine;
    FileIO fileIO;

    qmlRegisterType<FontManager>("CoolRetroTerm", 1, 0, "FontManager");
    qmlRegisterUncreatableType<FontListModel>("CoolRetroTerm", 1, 0, "FontListModel", "FontListModel is created by FontManager");

#if !defined(Q_OS_MAC)
    app.setWindowIcon(QIcon::fromTheme("cool-retro-term", QIcon(":../icons/32x32/cool-retro-term.png")));
#if defined(Q_OS_LINUX)
    QGuiApplication::setDesktopFileName(QStringLiteral("cool-retro-term"));
#endif
#else
    app.setWindowIcon(QIcon(":../icons/32x32/cool-retro-term.png"));
#endif

    // Manage command line arguments from the cpp side
    QStringList args = app.arguments();

    // Manage default command
    QStringList cmdList;
    if (args.contains("-e")) {
        cmdList << args.mid(args.indexOf("-e") + 1);
    }
    QVariant command(cmdList.empty() ? QVariant() : cmdList[0]);
    // A plain QStringList (rather than an invalid QVariant) so that
    // ksession.setArgs() always gets a value it can convert, even for a
    // single-word command with no extra arguments (e.g. "-e claude", or the
    // implicit "claude" default below).
    QVariant commandArgs(cmdList.size() <= 1 ? QVariant(QStringList()) : QVariant(cmdList.mid(1)));

    // This is meant to be a dedicated skin for AI coding CLIs: with no
    // explicit "-e" override, launch `claude` if it's on PATH, else `codex`.
    // Falls back to the normal shell (cool-retro-term's original behavior)
    // if neither is found, so the app still works as a plain terminal.
    if (cmdList.empty()) {
        if (!QStandardPaths::findExecutable(QStringLiteral("claude")).isEmpty()) {
            command = QVariant(QStringLiteral("claude"));
        } else if (!QStandardPaths::findExecutable(QStringLiteral("codex")).isEmpty()) {
            command = QVariant(QStringLiteral("codex"));
        }
    }

    // Which CLI is actually running picks the color scheme: orange for
    // Claude, classic monochrome green for Codex, and a third color for
    // anything else (a plain shell, or whatever else -e launches) — same
    // CRT effect settings throughout, just a different phosphor color.
    const QString resolvedCommandName = command.isValid()
        ? QFileInfo(command.toString()).fileName()
        : QString();
    QString activeTool = QStringLiteral("other");
    if (resolvedCommandName.compare(QStringLiteral("claude"), Qt::CaseInsensitive) == 0) {
        activeTool = QStringLiteral("claude");
    } else if (resolvedCommandName.compare(QStringLiteral("codex"), Qt::CaseInsensitive) == 0) {
        activeTool = QStringLiteral("codex");
    }

    engine.rootContext()->setContextProperty("appVersion", appVersion);
    engine.rootContext()->setContextProperty("defaultCmd", command);
    engine.rootContext()->setContextProperty("defaultCmdArgs", commandArgs);
    engine.rootContext()->setContextProperty("activeTool", activeTool);

    engine.rootContext()->setContextProperty("workdir", getNamedArgument(args, "--workdir", QDir::currentPath()));
    engine.rootContext()->setContextProperty("fileIO", &fileIO);

    PushToTalk pushToTalk;
    engine.rootContext()->setContextProperty("pushToTalk", &pushToTalk);

    // Manage import paths for Linux and OSX.
    QStringList importPathList = engine.importPathList();
    importPathList.append(QCoreApplication::applicationDirPath() + "/qmltermwidget");
    importPathList.append(QCoreApplication::applicationDirPath() + "/../PlugIns");
    importPathList.append(QCoreApplication::applicationDirPath() + "/../../../qmltermwidget");
    engine.setImportPathList(importPathList);

    engine.load(QUrl(QStringLiteral ("qrc:/main.qml")));

    if (engine.rootObjects().isEmpty()) {
        qDebug() << "Cannot load QML interface";
        return EXIT_FAILURE;
    }

    // Quit the application when the engine closes.
    QObject::connect((QObject*) &engine, SIGNAL(quit()), (QObject*) &app, SLOT(quit()));

    auto requestNewWindow = [&engine]() {
        if (engine.rootObjects().isEmpty())
            return;

        QObject *rootObject = engine.rootObjects().constFirst();
        QMetaObject::invokeMethod(rootObject, "createWindow", Qt::QueuedConnection);
    };

    QObject::connect(&singleApp, &KDSingleApplication::messageReceived, &app,
                     [&requestNewWindow](const QByteArray &message) {
        if (message.isEmpty() || message == QByteArray("new-window"))
            requestNewWindow();
    });

#if defined(Q_OS_MAC)
    QMenu *dockMenu = new QMenu(nullptr);
    dockMenu->addAction(QObject::tr("New Window"), [&requestNewWindow]() { requestNewWindow(); });
    dockMenu->setAsDockMenu();
#endif

    return app.exec();
}
