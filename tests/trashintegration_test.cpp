// SPDX-License-Identifier: GPL-3.0-or-later

#include "trashintegration.h"

#include <KCoreDirLister>
#include <KIO/Job>

#include <QCoreApplication>
#include <QEventLoop>
#include <QTimer>

#include <cstdlib>
#include <iostream>
#include <memory>

namespace
{
enum class ListingOutcome {
    Completed,
    Unavailable,
    TimedOut,
};

ListingOutcome waitForListing(KCoreDirLister *lister, QString &errorMessage,
                              int timeoutMilliseconds = 5000)
{
    if (!lister || lister->isFinished()) {
        return lister ? ListingOutcome::Completed : ListingOutcome::Unavailable;
    }

    QEventLoop loop;
    QTimer timeout;
    timeout.setSingleShot(true);
    ListingOutcome outcome = ListingOutcome::TimedOut;

    QObject::connect(lister, &KCoreDirLister::completed, &loop, [&]() {
        outcome = ListingOutcome::Completed;
        loop.quit();
    });
    QObject::connect(lister, &KCoreDirLister::canceled, &loop, [&]() {
        outcome = ListingOutcome::Unavailable;
        loop.quit();
    });
    QObject::connect(lister, &KCoreDirLister::jobError, &loop,
                     [&](KIO::Job *job) {
        outcome = ListingOutcome::Unavailable;
        errorMessage = job ? job->errorString() : QString();
        loop.quit();
    });
    QObject::connect(&timeout, &QTimer::timeout, &loop, &QEventLoop::quit);

    timeout.start(timeoutMilliseconds);
    loop.exec();
    return outcome;
}

ListingOutcome waitForSettledListing(KCoreDirLister *lister,
                                     QString &errorMessage)
{
    constexpr int maximumRefreshPasses = 3;
    for (int pass = 0; pass < maximumRefreshPasses; ++pass) {
        QCoreApplication::processEvents();
        const ListingOutcome outcome = waitForListing(lister, errorMessage);
        if (outcome != ListingOutcome::Completed) {
            return outcome;
        }
        QCoreApplication::processEvents();
        if (lister->isFinished()) {
            return ListingOutcome::Completed;
        }
    }
    return ListingOutcome::TimedOut;
}

int validateAggregatedTrashState()
{
    TrashIntegration integration;
    auto *lister = integration.findChild<KCoreDirLister *>();
    if (!lister) {
        std::cerr << "TrashIntegration did not create its KIO directory lister.\n";
        return EXIT_FAILURE;
    }
    if (lister->url() != QUrl(QStringLiteral("trash:/"))
        || !lister->autoUpdate() || lister->autoErrorHandlingEnabled()) {
        std::cerr << "TrashIntegration did not configure the aggregate lister safely.\n";
        return EXIT_FAILURE;
    }

    QString errorMessage;
    const ListingOutcome outcome = waitForListing(lister, errorMessage);
    if (outcome == ListingOutcome::Unavailable) {
        std::cout << "SKIP: The aggregated trash worker is unavailable";
        if (!errorMessage.isEmpty()) {
            std::cout << ": " << errorMessage.toStdString();
        }
        std::cout << ".\n";
        return 77;
    }
    if (outcome == ListingOutcome::TimedOut) {
        std::cerr << "The aggregated trash listing timed out.\n";
        return EXIT_FAILURE;
    }

    const bool expectedHasItems
        = !lister->items(KCoreDirLister::AllItems).isEmpty();
    if (integration.hasItems() != expectedHasItems) {
        std::cerr << "TrashIntegration disagrees with the aggregated trash listing.\n";
        return EXIT_FAILURE;
    }

    for (int request = 0; request < 64; ++request) {
        integration.refresh();
    }

    errorMessage.clear();
    const ListingOutcome refreshOutcome
        = waitForSettledListing(lister, errorMessage);
    if (refreshOutcome != ListingOutcome::Completed) {
        std::cerr << "The coalesced trash refresh did not complete.\n";
        return EXIT_FAILURE;
    }

    if (!lister->isFinished()
        || integration.hasItems()
            != !lister->items(KCoreDirLister::AllItems).isEmpty()) {
        std::cerr << "The coalesced trash refresh did not preserve the aggregate state.\n";
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}

bool validateInterruptedTrashListings()
{
    constexpr int instanceCount = 16;
    for (int instance = 0; instance < instanceCount; ++instance) {
        auto integration = std::make_unique<TrashIntegration>();
        integration->refresh();
        integration->refresh();
    }

    QEventLoop settleLoop;
    QTimer::singleShot(500, &settleLoop, &QEventLoop::quit);
    settleLoop.exec();
    return true;
}
}

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    if (!validateInterruptedTrashListings()) {
        return EXIT_FAILURE;
    }
    return validateAggregatedTrashState();
}
