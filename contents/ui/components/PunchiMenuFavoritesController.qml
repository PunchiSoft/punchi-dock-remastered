import QtQuick
import org.kde.plasma.plasmoid

Item {
    id: root

    required property var systemDiscovery

    readonly property int maximumFavoriteCount: 64
    readonly property bool limitReached: favorites.length >= maximumFavoriteCount
    property var favorites: []

    function normalizeStorageId(value) {
        const storageId = String(value || "").trim()
        if (storageId.length === 0 || storageId.length > 512
                || /[\u0000-\u001F\u007F]/.test(storageId)) {
            return ""
        }
        return storageId
    }

    function configuredStorageIds() {
        const configured = Plasmoid.configuration.punchiMenuFavoriteStorageIds
        if (configured === undefined || configured === null) {
            return []
        }
        if (typeof configured === "string") {
            return configured.trim().length > 0 ? [configured] : []
        }

        const result = []
        const count = Number(configured.length)
        if (!Number.isFinite(count) || count < 0) {
            return result
        }
        for (let index = 0; index < Math.min(count, maximumFavoriteCount); index++) {
            result.push(configured[index])
        }
        return result
    }

    function resolveFavorite(storageId) {
        const normalizedId = normalizeStorageId(storageId)
        if (normalizedId.length === 0 || !systemDiscovery) {
            return null
        }

        const application = systemDiscovery.applicationForLauncher(normalizedId, "")
        const resolvedId = normalizeStorageId(application && application.storageId)
        const name = String(application && application.name || "").trim()
        if (resolvedId.length === 0 || name.length === 0) {
            return null
        }

        return {
            appName: name.substring(0, 256),
            appIcon: String(application.icon || "application-x-executable").substring(0, 512),
            appStorageId: resolvedId,
            appCommand: ""
        }
    }

    function persistFavorites() {
        const storageIds = []
        for (let index = 0; index < favorites.length; index++) {
            storageIds.push(String(favorites[index].appStorageId || ""))
        }
        Plasmoid.configuration.punchiMenuFavoriteStorageIds = storageIds
    }

    function refresh() {
        const configuredIds = configuredStorageIds()
        const resolvedFavorites = []
        const seen = Object.create(null)

        for (let index = 0;
                index < configuredIds.length && resolvedFavorites.length < maximumFavoriteCount;
                index++) {
            const favorite = resolveFavorite(configuredIds[index])
            if (!favorite) {
                continue
            }
            const identity = favorite.appStorageId.toLocaleLowerCase()
            if (seen[identity]) {
                continue
            }
            seen[identity] = true
            resolvedFavorites.push(favorite)
        }

        favorites = resolvedFavorites

        const normalizedIds = resolvedFavorites.map(function(favorite) {
            return favorite.appStorageId
        })
        const originalIds = configuredIds.map(function(storageId) {
            return root.normalizeStorageId(storageId)
        }).filter(function(storageId) {
            return storageId.length > 0
        })
        if (JSON.stringify(normalizedIds) !== JSON.stringify(originalIds)) {
            persistFavorites()
        }
    }

    function containsFavorite(storageId) {
        const requestedId = normalizeStorageId(storageId).toLocaleLowerCase()
        if (requestedId.length === 0) {
            return false
        }
        for (let index = 0; index < favorites.length; index++) {
            if (String(favorites[index].appStorageId || "").toLocaleLowerCase()
                    === requestedId) {
                return true
            }
        }
        return false
    }

    function addFavorite(storageId) {
        if (limitReached || containsFavorite(storageId)) {
            return false
        }
        const favorite = resolveFavorite(storageId)
        if (!favorite || containsFavorite(favorite.appStorageId)) {
            return false
        }
        favorites = favorites.concat([favorite])
        persistFavorites()
        return true
    }

    function removeFavorite(storageId) {
        const requestedId = normalizeStorageId(storageId).toLocaleLowerCase()
        if (requestedId.length === 0) {
            return false
        }

        const remaining = []
        let removed = false
        for (let index = 0; index < favorites.length; index++) {
            const favorite = favorites[index]
            if (String(favorite.appStorageId || "").toLocaleLowerCase()
                    === requestedId) {
                removed = true
            } else {
                remaining.push(favorite)
            }
        }
        if (!removed) {
            return false
        }
        favorites = remaining
        persistFavorites()
        return true
    }

    Component.onCompleted: refresh()
}
