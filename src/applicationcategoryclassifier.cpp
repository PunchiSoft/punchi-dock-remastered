// SPDX-License-Identifier: GPL-3.0-or-later

#include "applicationcategoryclassifier.h"

#include <QHash>

namespace
{
const QHash<QString, QStringList> &categoryFamilies()
{
    static const QHash<QString, QStringList> families = {
        {QStringLiteral("AudioVideo"),
            {QStringLiteral("AudioVideo"), QStringLiteral("Audio"),
                QStringLiteral("Video"), QStringLiteral("Player"),
                QStringLiteral("Music"), QStringLiteral("Recorder"),
                QStringLiteral("TV"),
                QStringLiteral("AudioVideoEditing")}},
        {QStringLiteral("Network"),
            {QStringLiteral("Network"), QStringLiteral("WebBrowser"),
                QStringLiteral("Email"), QStringLiteral("IRCClient"),
                QStringLiteral("Feed"), QStringLiteral("FileTransfer"),
                QStringLiteral("RemoteAccess"),
                QStringLiteral("Internet")}},
        {QStringLiteral("Development"),
            {QStringLiteral("Development"), QStringLiteral("IDE"),
                QStringLiteral("Building"), QStringLiteral("Debugger"),
                QStringLiteral("TextEditor"),
                QStringLiteral("RevisionControl"),
                QStringLiteral("WebDevelopment")}},
        {QStringLiteral("Graphics"),
            {QStringLiteral("Graphics"), QStringLiteral("VectorGraphics"),
                QStringLiteral("RasterGraphics"),
                QStringLiteral("3DGraphics"),
                QStringLiteral("Photography"), QStringLiteral("Viewer"),
                QStringLiteral("Paint")}},
        {QStringLiteral("Office"),
            {QStringLiteral("Office"), QStringLiteral("WordProcessor"),
                QStringLiteral("Spreadsheet"),
                QStringLiteral("Presentation"),
                QStringLiteral("Publishing"), QStringLiteral("Finance"),
                QStringLiteral("Calendar"), QStringLiteral("Calculator")}},
        {QStringLiteral("System"),
            {QStringLiteral("System"), QStringLiteral("Monitor"),
                QStringLiteral("Security"), QStringLiteral("Settings"),
                QStringLiteral("PackageManager"),
                QStringLiteral("TerminalEmulator")}},
        {QStringLiteral("Utility"),
            {QStringLiteral("Utility"), QStringLiteral("Utilities"),
                QStringLiteral("FileTools"), QStringLiteral("Archiving"),
                QStringLiteral("Clock"), QStringLiteral("TextEditor")}},
        {QStringLiteral("Game"),
            {QStringLiteral("Game"), QStringLiteral("ActionGame"),
                QStringLiteral("AdventureGame"), QStringLiteral("ArcadeGame"),
                QStringLiteral("BoardGame"), QStringLiteral("CardGame"),
                QStringLiteral("BlocksGame"), QStringLiteral("Emulator")}},
        {QStringLiteral("Education"),
            {QStringLiteral("Education"), QStringLiteral("Science"),
                QStringLiteral("Math"), QStringLiteral("History"),
                QStringLiteral("Geography")}},
    };
    return families;
}
}

QStringList ApplicationCategoryClassifier::orderedGroups()
{
    return {
        QStringLiteral("Network"),
        QStringLiteral("Graphics"),
        QStringLiteral("AudioVideo"),
        QStringLiteral("Office"),
        QStringLiteral("Development"),
        QStringLiteral("System"),
        QStringLiteral("Utility"),
        QStringLiteral("Game"),
        QStringLiteral("Education"),
    };
}

bool ApplicationCategoryClassifier::matches(
    const QStringList &serviceCategories, const QString &requestedGroup)
{
    const QString trimmedRequested = requestedGroup.trimmed();
    if (trimmedRequested.isEmpty()
        || trimmedRequested.compare(
               QStringLiteral("All"), Qt::CaseInsensitive)
            == 0) {
        return true;
    }

    const QStringList targetCategories = categoryFamilies().value(
        trimmedRequested, QStringList{trimmedRequested});
    for (const QString &targetCategory : targetCategories) {
        for (const QString &serviceCategory : serviceCategories) {
            if (serviceCategory.compare(targetCategory, Qt::CaseInsensitive)
                == 0) {
                return true;
            }
        }
    }
    return false;
}

QString ApplicationCategoryClassifier::primaryGroup(
    const QStringList &serviceCategories)
{
    const QStringList groups = orderedGroups();
    for (const QString &group : groups) {
        for (const QString &serviceCategory : serviceCategories) {
            if (serviceCategory.compare(group, Qt::CaseInsensitive) == 0) {
                return group;
            }
        }
    }
    for (const QString &group : groups) {
        if (matches(serviceCategories, group)) {
            return group;
        }
    }
    return QStringLiteral("Other");
}
