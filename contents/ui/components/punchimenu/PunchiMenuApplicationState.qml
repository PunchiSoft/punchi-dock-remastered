// SPDX-License-Identifier: GPL-2.0-or-later

import QtQml

QtObject {
    id: root

    property var favorites: []
    property var hiddenApplicationIds: []
    property var applicationCatalog: []

    readonly property var hiddenApplicationLookup: {
        const source = Array.isArray(root.hiddenApplicationIds)
            ? root.hiddenApplicationIds
            : []
        const lookup = {}
        for (let index = 0; index < source.length && index < 512; index++) {
            const storageId = root.normalizedStorageId(source[index])
            if (storageId.length === 0) {
                continue
            }
            lookup["#" + storageId] = true
        }
        return lookup
    }
    readonly property int hiddenIdCount:
        Object.keys(root.hiddenApplicationLookup).length
    readonly property int hiddenCatalogApplicationCount: {
        let count = 0
        const source = Array.isArray(root.applicationCatalog)
            ? root.applicationCatalog
            : []
        for (let index = 0; index < source.length; index++) {
            const application = source[index]
            const storageId = root.normalizedStorageId(application
                ? application.storageId || application.appStorageId
                : "")
            if (storageId.length > 0
                    && root.hiddenApplicationLookup["#" + storageId]) {
                count++
            }
        }
        return count
    }

    function normalizedStorageId(value) {
        const storageId = String(value || "").trim()
        if (storageId.length === 0 || storageId.length > 512
                || /[\u0000-\u001f\u007f]/.test(storageId)) {
            return ""
        }
        return storageId
    }

    function favoriteStorageId(favorite) {
        if (typeof favorite === "string") {
            return root.normalizedStorageId(favorite)
        }
        return root.normalizedStorageId(favorite
            ? favorite.appStorageId || favorite.storageId || favorite.id
            : "")
    }

    function isFavorite(storageId) {
        const requestedId = root.normalizedStorageId(storageId)
        if (requestedId.length === 0) {
            return false
        }
        const source = Array.isArray(root.favorites) ? root.favorites : []
        for (let index = 0; index < source.length; index++) {
            if (root.favoriteStorageId(source[index]) === requestedId) {
                return true
            }
        }
        return false
    }

    function isApplicationHidden(storageId) {
        const requestedId = root.normalizedStorageId(storageId)
        return requestedId.length > 0
            && !!root.hiddenApplicationLookup["#" + requestedId]
    }
}
