// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QPointer>
#include <QSet>
#include <QString>
#include <QUrl>
#include <QVariantList>
#include <qqmlregistration.h>

class KCoreDirLister;
class KJob;

class TrashIntegration : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool hasItems READ hasItems NOTIFY stateChanged)
    Q_PROPERTY(bool emptying READ emptying NOTIFY operationStateChanged)
    Q_PROPERTY(QString operationState READ operationState NOTIFY operationStateChanged)
    Q_PROPERTY(int progressPercent READ progressPercent NOTIFY progressChanged)
    Q_PROPERTY(bool progressDeterminate READ progressDeterminate NOTIFY progressChanged)
    Q_PROPERTY(int processedItems READ processedItems NOTIFY progressChanged)
    Q_PROPERTY(int totalItems READ totalItems NOTIFY progressChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY operationStateChanged)

public:
    explicit TrashIntegration(QObject *parent = nullptr);
    ~TrashIntegration() override;

    bool hasItems() const;
    bool emptying() const;
    QString operationState() const;
    int progressPercent() const;
    bool progressDeterminate() const;
    int processedItems() const;
    int totalItems() const;
    QString errorMessage() const;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void openTrash();
    Q_INVOKABLE void trashUrls(const QVariantList &urls);
    Q_INVOKABLE void emptyTrash();
    Q_INVOKABLE void resetOperationState();

Q_SIGNALS:
    void stateChanged(bool hasItems);
    void operationStateChanged();
    void progressChanged();
    void operationSucceeded(const QString &operation);
    void operationFailed(const QString &operation, const QString &message);

private:
    void setHasItems(bool hasItems);
    void setOperationState(const QString &state, const QString &errorMessage = {});
    void resetProgress();
    void syncProgress(KJob *job);
    void finishTrashListing();
    void cancelTrashListing();
    void schedulePendingRefresh();

    bool m_hasItems = false;
    QString m_operationState = QStringLiteral("idle");
    QString m_errorMessage;
    int m_progressPercent = -1;
    int m_processedItems = 0;
    int m_totalItems = 0;
    bool m_progressDeterminate = false;
    QPointer<KJob> m_emptyTrashJob;
    KCoreDirLister *m_trashLister = nullptr;
    QSet<QUrl> m_listedTrashItems;
    QSet<QUrl> m_pendingTrashItems;
    bool m_rebuildingTrashItems = false;
    bool m_refreshPending = false;
};
