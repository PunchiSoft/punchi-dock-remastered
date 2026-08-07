#!/usr/bin/env python3

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def require(source: str, fragment: str, message: str) -> None:
    if fragment not in source:
        raise AssertionError(message)


def main() -> None:
    controller_source = (
        ROOT / "contents/ui/components/DockItemsController.qml"
    ).read_text(encoding="utf-8")
    main_source = (ROOT / "contents/ui/main.qml").read_text(encoding="utf-8")
    normal_source = (
        ROOT / "contents/ui/components/punchimenu/PunchiMenuNormal.qml"
    ).read_text(encoding="utf-8")
    fullscreen_source = (
        ROOT / "contents/ui/components/punchimenu/PunchiMenuOverlay.qml"
    ).read_text(encoding="utf-8")

    require(
        controller_source,
        "property var persistenceAdapter: null",
        "DockItemsController must receive persistence through an adapter.",
    )
    start = controller_source.index(
        "function commitPunchiMenuApplicationLayout(expectedDocument, nextDocument)"
    )
    end = controller_source.index(
        "function normalizedPunchiMenuHiddenApplicationId", start
    )
    transaction = controller_source[start:end]
    require(
        transaction,
        "persistenceAdapter.commitDockItemsJson(",
        "The layout transaction must use the native compare-and-swap adapter.",
    )
    if "root.dockItems =" in transaction:
        raise AssertionError(
            "The layout transaction must not mutate QML state before persistence."
        )
    if "Plasmoid.configuration.dockItemsJson =" in transaction:
        raise AssertionError(
            "The layout transaction must not write KConfig through the void QML API."
        )

    require(
        main_source,
        "Punchi.DockItemsPersistenceAdapter {",
        "The native persistence adapter must be reachable from the runtime graph.",
    )
    require(
        main_source,
        "applet: root.plasmoid",
        "The adapter must target the current Plasma applet configuration.",
    )
    require(
        main_source,
        "persistenceAdapter: dockItemsPersistenceAdapter",
        "DockItemsController must receive the configured native adapter.",
    )
    require(
        main_source,
        "punchiMenuLayoutController.applicationStorageIds = storageIds",
        "The layout controller must receive the complete catalog identities.",
    )
    require(
        main_source,
        "onPersistenceRequested: function(transactionId, document, operation, subjectId)",
        "The layout controller must wait for the persistence acknowledgement.",
    )
    require(
        main_source,
        "dockItemsPersistenceAdapter.reconcileDockItemsJson(",
        "Persistence conflicts must reconcile the durable validated value.",
    )
    rejection_index = main_source.index(
        "punchiMenuLayoutController.rejectPersistence("
    )
    reconciliation_index = main_source.index(
        "dockItemsPersistenceAdapter.reconcileDockItemsJson("
    )
    if rejection_index > reconciliation_index:
        raise AssertionError(
            "The pending transaction must be rejected before durable reconciliation."
        )

    require(
        main_source,
        "systemDiscovery.requestApplicationCatalog()",
        "The controller catalog must be requested outside the visible views.",
    )
    for source, mode in (
        (normal_source, "Normal"),
        (fullscreen_source, "Fullscreen"),
    ):
        require(
            source,
            "systemDiscovery.requestApplications(",
            f"PunchiMenu {mode} must preserve its existing visible query.",
        )
        if "function onApplicationCatalogReady(applications)" in source:
            raise AssertionError(
                f"PunchiMenu {mode} must not render the controller catalog yet."
            )


if __name__ == "__main__":
    main()
