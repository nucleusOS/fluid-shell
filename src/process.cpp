#include "process.h"

Process::Process(QObject *parent) : QProcess(parent) {

}

void Process::start(const QString &program, const QVariantList &arguments) {
    QStringList args;

    qDebug() << "Running" << program;
    // convert QVariantList from QML to QStringList for QProcess

    for (int i = 0; i < arguments.length(); i++)
        args << arguments[i].toString();

    QProcess proc;
    proc.setProgram(program);
    proc.startDetached();

}

QByteArray Process::readAll() {
    return QProcess::readAll();
}
