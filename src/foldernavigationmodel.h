// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QAbstractListModel>
#include <QDateTime>
#include <QList>
#include <QPointer>
#include <QVariantMap>
#include <qqmlregistration.h>

namespace KIO { class ListJob; }

// A bounded, cancellable directory listing. Navigation and focus belong to
// the QML controller; this model never changes persistent container contents.
// Qt derives an instantiable QML wrapper from this registered type.
class FolderNavigationModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString rootPath READ rootPath WRITE setRootPath NOTIFY rootPathChanged)
    Q_PROPERTY(QString location READ location WRITE setLocation NOTIFY locationChanged)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(QString sortMode READ sortMode WRITE setSortMode NOTIFY sortModeChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY stateChanged)
    Q_PROPERTY(QString error READ error NOTIFY stateChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int depth READ depth NOTIFY locationChanged)
    Q_PROPERTY(int maximumDepth READ maximumDepth CONSTANT)
public:
    explicit FolderNavigationModel(QObject *parent = nullptr);
    ~FolderNavigationModel() override;
    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    QString rootPath() const { return m_rootPath; }
    QString location() const { return m_location; }
    bool enabled() const { return m_enabled; }
    QString sortMode() const { return m_sortMode; }
    bool loading() const { return m_loading; }
    QString error() const { return m_error; }
    int count() const { return m_entries.size(); }
    int depth() const;
    int maximumDepth() const { return 3; }
    void setRootPath(const QString &path);
    void setLocation(const QString &location);
    void setEnabled(bool enabled);
    void setSortMode(const QString &mode);
    Q_INVOKABLE QVariantMap get(int row) const;
    Q_INVOKABLE QString directoryTarget(const QVariantMap &entry) const;
    Q_INVOKABLE void reload();
Q_SIGNALS:
    void rootPathChanged();
    void locationChanged();
    void enabledChanged();
    void sortModeChanged();
    void stateChanged();
    void countChanged();
private:
    struct Entry {
        QVariantMap row;
        QString name;
        qint64 size = 0;
        QDateTime modified;
        QDateTime created;
        QString mimeType;
    };
    QString boundedDirectory(const QString &path) const;
    void cancel();
    void clear();
    void sortEntries(QList<Entry> &entries);
    QString m_rootPath;
    QString m_rootDirectory;
    QString m_location;
    QString m_sortMode = QStringLiteral("modified");
    bool m_enabled = false;
    bool m_loading = false;
    QString m_error;
    QList<Entry> m_entries;
    QList<Entry> m_pendingEntries;
    QPointer<KIO::ListJob> m_job;
    quint64 m_generation = 0;
};
