// SPDX-License-Identifier: GPL-3.0-or-later

#include "dropurlpolicy.h"

#include <QDir>
#include <QSet>

namespace DropUrlPolicy
{
Result validate(const QVariantList &values)
{
    if (values.isEmpty()) {
        return {{}, QStringLiteral("noUrls")};
    }
    if (values.size() > maximumUrlCount) {
        return {{}, QStringLiteral("tooManyUrls")};
    }

    QList<QUrl> normalizedUrls;
    normalizedUrls.reserve(values.size());
    QSet<QByteArray> seenUrls;
    qsizetype batchBytes = 0;

    for (const QVariant &value : values) {
        const QUrl candidate = value.toUrl();
        if (!candidate.isValid() || candidate.isEmpty()
            || candidate.path().isEmpty() || candidate.hasQuery()
            || candidate.hasFragment()) {
            return {{}, QStringLiteral("invalidUrl")};
        }
        if (candidate.scheme().compare(QStringLiteral("file"), Qt::CaseInsensitive) != 0
            || !candidate.isLocalFile() || !candidate.host().isEmpty()) {
            return {{}, QStringLiteral("unsupportedScheme")};
        }

        const QByteArray encodedCandidate = candidate.toEncoded(QUrl::FullyEncoded);
        if (encodedCandidate.size() > maximumUrlBytes) {
            return {{}, QStringLiteral("urlTooLong")};
        }
        batchBytes += encodedCandidate.size();
        if (batchBytes > maximumBatchBytes) {
            return {{}, QStringLiteral("batchTooLarge")};
        }

        const QString localPath = QDir::cleanPath(candidate.toLocalFile());
        if (localPath.isEmpty()) {
            return {{}, QStringLiteral("invalidUrl")};
        }
        const QUrl normalizedUrl = QUrl::fromLocalFile(localPath);
        const QByteArray key = normalizedUrl.toEncoded(QUrl::FullyEncoded);
        if (seenUrls.contains(key)) {
            continue;
        }
        seenUrls.insert(key);
        normalizedUrls.append(normalizedUrl);
    }

    if (normalizedUrls.isEmpty()) {
        return {{}, QStringLiteral("noUrls")};
    }
    return {normalizedUrls, {}};
}
}
