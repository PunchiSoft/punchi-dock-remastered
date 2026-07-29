// SPDX-License-Identifier: GPL-3.0-or-later

#include "dropurlpolicy.h"

#include <iostream>

namespace
{
QVariant localUrl(const QString &path)
{
    return QVariant::fromValue(QUrl::fromLocalFile(path));
}

bool expect(bool condition, const char *message)
{
    if (!condition) {
        std::cerr << "FAILED: " << message << '\n';
    }
    return condition;
}
}

int main()
{
    bool passed = true;

    const DropUrlPolicy::Result empty = DropUrlPolicy::validate({});
    passed &= expect(!empty.accepted() && empty.errorCode == QStringLiteral("noUrls"),
        "empty drops are rejected");

    const DropUrlPolicy::Result single = DropUrlPolicy::validate({localUrl(QStringLiteral("/tmp/document.md"))});
    passed &= expect(single.accepted() && single.urls.size() == 1,
        "one local file URL is accepted");

    const DropUrlPolicy::Result dashPrefixed = DropUrlPolicy::validate({localUrl(QStringLiteral("/tmp/--empty"))});
    passed &= expect(dashPrefixed.accepted() && dashPrefixed.urls.constFirst().toLocalFile() == QStringLiteral("/tmp/--empty"),
        "a dash-prefixed local file name remains a file URL");

    QVariantList maximumBatch;
    for (int index = 0; index < DropUrlPolicy::maximumUrlCount; ++index) {
        maximumBatch.append(localUrl(QStringLiteral("/tmp/document-%1.md").arg(index)));
    }
    passed &= expect(DropUrlPolicy::validate(maximumBatch).accepted(),
        "the maximum URL count is accepted");

    QVariantList oversizedCount = maximumBatch;
    oversizedCount.append(localUrl(QStringLiteral("/tmp/one-too-many.md")));
    const DropUrlPolicy::Result tooMany = DropUrlPolicy::validate(oversizedCount);
    passed &= expect(!tooMany.accepted() && tooMany.errorCode == QStringLiteral("tooManyUrls"),
        "a batch above the URL count limit is rejected");

    const DropUrlPolicy::Result duplicate = DropUrlPolicy::validate({
        localUrl(QStringLiteral("/tmp/repeated.md")),
        localUrl(QStringLiteral("/tmp/repeated.md")),
    });
    passed &= expect(duplicate.accepted() && duplicate.urls.size() == 1,
        "duplicate local URLs are delivered once");

    const DropUrlPolicy::Result remote = DropUrlPolicy::validate({QUrl(QStringLiteral("https://example.invalid/document.md"))});
    passed &= expect(!remote.accepted() && remote.errorCode == QStringLiteral("unsupportedScheme"),
        "remote URLs are rejected");

    const DropUrlPolicy::Result queried = DropUrlPolicy::validate({QUrl(QStringLiteral("file:///tmp/document.md?action=run"))});
    passed &= expect(!queried.accepted() && queried.errorCode == QStringLiteral("invalidUrl"),
        "local URLs with query data are rejected");

    const DropUrlPolicy::Result fragmented = DropUrlPolicy::validate({QUrl(QStringLiteral("file:///tmp/document.md#section"))});
    passed &= expect(!fragmented.accepted() && fragmented.errorCode == QStringLiteral("invalidUrl"),
        "local URLs with fragment data are rejected");

    const DropUrlPolicy::Result hosted = DropUrlPolicy::validate({QUrl(QStringLiteral("file://example.invalid/tmp/document.md"))});
    passed &= expect(!hosted.accepted() && hosted.errorCode == QStringLiteral("unsupportedScheme"),
        "file URLs with a host are rejected");

    const DropUrlPolicy::Result normalized = DropUrlPolicy::validate({localUrl(QStringLiteral("/tmp/folder/../document.md"))});
    passed &= expect(normalized.accepted()
            && normalized.urls.constFirst().toLocalFile() == QStringLiteral("/tmp/document.md"),
        "local URLs are normalized before delivery");

    const QString longPath = QStringLiteral("/tmp/")
        + QString(DropUrlPolicy::maximumUrlBytes, QLatin1Char('a'));
    const DropUrlPolicy::Result tooLong = DropUrlPolicy::validate({localUrl(longPath)});
    passed &= expect(!tooLong.accepted() && tooLong.errorCode == QStringLiteral("urlTooLong"),
        "an oversized individual URL is rejected");

    QVariantList oversizedBytes;
    const QString pathBody(5000, QLatin1Char('b'));
    for (int index = 0; index < DropUrlPolicy::maximumUrlCount; ++index) {
        oversizedBytes.append(localUrl(QStringLiteral("/tmp/%1-%2").arg(index).arg(pathBody)));
    }
    const DropUrlPolicy::Result tooLarge = DropUrlPolicy::validate(oversizedBytes);
    passed &= expect(!tooLarge.accepted() && tooLarge.errorCode == QStringLiteral("batchTooLarge"),
        "an oversized URL batch is rejected");

    return passed ? 0 : 1;
}
