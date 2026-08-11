// SPDX-License-Identifier: GPL-3.0-or-later

#include "mprisplayerselection.h"

#include <QRegularExpression>
#include <QSet>

#include <algorithm>

namespace
{
QString normalizedIdentity(QString value)
{
    value = value.trimmed().toLower();
    if (value.endsWith(QLatin1String(".desktop"))) {
        value.chop(8);
    }
    value.remove(QRegularExpression(QStringLiteral("[^a-z0-9]+")));
    return value;
}

QStringList meaningfulIdentityTokens(QString value)
{
    value = value.trimmed().toLower();
    if (value.endsWith(QLatin1String(".desktop"))) {
        value.chop(8);
    }

    static const QSet<QString> namespaceTokens{
        QStringLiteral("app"),
        QStringLiteral("com"),
        QStringLiteral("dev"),
        QStringLiteral("io"),
        QStringLiteral("kde"),
        QStringLiteral("net"),
        QStringLiteral("org"),
    };
    QStringList result;
    const QStringList tokens = value.split(
        QRegularExpression(QStringLiteral("[^a-z0-9]+")), Qt::SkipEmptyParts);
    for (const QString &token : tokens) {
        if (token.size() >= 3 && !namespaceTokens.contains(token)) {
            result.append(token);
        }
    }
    return result;
}

int identityScore(const QString &applicationId, const QString &candidate)
{
    const QString target = normalizedIdentity(applicationId);
    const QString source = normalizedIdentity(candidate);
    if (target.isEmpty() || source.isEmpty()) {
        return 0;
    }
    if (target == source) {
        return 100;
    }
    const QStringList targetTokens = meaningfulIdentityTokens(applicationId);
    const QStringList sourceTokens = meaningfulIdentityTokens(candidate);
    for (const QString &sourceToken : sourceTokens) {
        if (targetTokens.contains(sourceToken)) {
            return 85;
        }
    }
    if (source.size() >= 4 && target.contains(source)) {
        return 75;
    }
    if (target.size() >= 4 && source.contains(target)) {
        return 65;
    }
    return 0;
}

int playbackScore(const QString &status)
{
    if (status == QLatin1String("Playing")) {
        return 300;
    }
    if (status == QLatin1String("Paused")) {
        return 200;
    }
    return 100;
}
}

QString MprisPlayerSelection::selectService(const QList<Candidate> &candidates,
                                            Mode mode,
                                            const QString &applicationId,
                                            const QString &currentService)
{
    QString selectedService;
    int selectedScore = 0;

    for (const Candidate &candidate : candidates) {
        if (candidate.service.isEmpty()) {
            continue;
        }

        int score = 0;
        if (mode == Mode::Application) {
            score = std::max(identityScore(applicationId, candidate.desktopEntry),
                             identityScore(applicationId, candidate.identity));
            if (score == 0) {
                continue;
            }
            if (candidate.playbackStatus == QLatin1String("Playing")) {
                score += 20;
            } else if (candidate.playbackStatus == QLatin1String("Paused")) {
                score += 10;
            }
        } else {
            score = playbackScore(candidate.playbackStatus);
            if (candidate.canControl) {
                score += 20;
            }
        }

        if (candidate.service == currentService) {
            score += 5;
        }

        if (score > selectedScore
            || (score == selectedScore
                && (selectedService.isEmpty() || candidate.service < selectedService))) {
            selectedScore = score;
            selectedService = candidate.service;
        }
    }

    return selectedService;
}
