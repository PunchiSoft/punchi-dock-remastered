// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <qqmlregistration.h>

class KDirWatch;

class TrashIntegration : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool hasItems READ hasItems NOTIFY stateChanged)

public:
    explicit TrashIntegration(QObject *parent = nullptr);
    ~TrashIntegration() override;

    bool hasItems() const;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void openTrash();
    Q_INVOKABLE void emptyTrash();

Q_SIGNALS:
    void stateChanged(bool hasItems);
    void operationFailed(const QString &operation, const QString &message);

private:
    void setHasItems(bool hasItems);
    void watchPaths();

    bool m_hasItems = false;
    KDirWatch *m_watch = nullptr;
};
