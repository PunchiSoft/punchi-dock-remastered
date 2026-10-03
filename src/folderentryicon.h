// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <KFileItem>
#include <KIO/UDSEntry>
#include <QMimeDatabase>
#include <QUrl>

namespace FolderEntryIcon
{
inline QString resolve(const KIO::UDSEntry &entry, const QUrl &url)
{
    const QString explicitIcon = entry.stringValue(KIO::UDSEntry::UDS_ICON_NAME);
    if (!explicitIcon.isEmpty()) {
        return explicitIcon;
    }

    KIO::UDSEntry resolvedEntry(entry);
    if (!entry.isDir()) {
        // Listing metadata or the filename is sufficient for an icon. Never
        // inspect every file's contents while populating a container.
        const QMimeDatabase database;
        auto mime = database.mimeTypeForName(entry.stringValue(KIO::UDSEntry::UDS_MIME_TYPE));
        if (!mime.isValid()) {
            mime = database.mimeTypeForFile(url.path(), QMimeDatabase::MatchExtension);
        }
        resolvedEntry.replace(KIO::UDSEntry::UDS_MIME_TYPE, mime.name());
    }

    const QString icon = KFileItem(resolvedEntry, url).iconName();
    return icon.isEmpty()
        ? (entry.isDir() ? QStringLiteral("folder") : QStringLiteral("application-octet-stream"))
        : icon;
}
}
