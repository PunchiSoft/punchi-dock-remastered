// SPDX-License-Identifier: GPL-3.0-or-later

#include "applicationcategoryclassifier.h"

#include <iostream>

namespace
{
bool expect(bool condition, const char *message)
{
    if (!condition) {
        std::cerr << message << '\n';
    }
    return condition;
}
}

int main()
{
    bool passed = true;
    passed &= expect(ApplicationCategoryClassifier::primaryGroup(
                         {QStringLiteral("Network"),
                             QStringLiteral("WebBrowser")})
            == QStringLiteral("Network"),
        "a KDE network desktop category maps to Network");
    passed &= expect(ApplicationCategoryClassifier::primaryGroup(
                         {QStringLiteral("Audio"),
                             QStringLiteral("Player")})
            == QStringLiteral("AudioVideo"),
        "a multimedia subcategory maps to AudioVideo");
    passed &= expect(ApplicationCategoryClassifier::primaryGroup(
                         {QStringLiteral("Utility"),
                             QStringLiteral("TextEditor")})
            == QStringLiteral("Utility"),
        "a utility application maps to Utility");
    passed &= expect(ApplicationCategoryClassifier::primaryGroup(
                         {QStringLiteral("X-Flatpak"),
                             QStringLiteral("Graphics")})
            == QStringLiteral("Graphics"),
        "package-specific metadata does not prevent KDE category matching");
    passed &= expect(ApplicationCategoryClassifier::primaryGroup(
                         {QStringLiteral("X-Custom")})
            == QStringLiteral("Other"),
        "unknown desktop categories use the safe Other group");
    passed &= expect(ApplicationCategoryClassifier::orderedGroups().size()
            == 9,
        "the public category order remains bounded and deterministic");
    return passed ? 0 : 1;
}
