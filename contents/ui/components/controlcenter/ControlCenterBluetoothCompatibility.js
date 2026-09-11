// SPDX-License-Identifier: GPL-2.0-or-later

.pragma library

function optionalBooleanProperty(object, propertyName) {
    return object && propertyName in object
        ? Boolean(object[propertyName]) : false
}

function registerPendingCall(proxy, call, ubi, disconnecting) {
    if (!proxy) {
        return false
    }

    const methodName = disconnecting
        ? "registerDisconnectingCallForDeviceUbi"
        : "registerConnectingCallForDeviceUbi"
    if (typeof proxy[methodName] === "function") {
        proxy[methodName](call, String(ubi || ""))
        return true
    }
    if (typeof proxy["registerPendingCallForDeviceUbi"] === "function") {
        proxy["registerPendingCallForDeviceUbi"](call, String(ubi || ""))
        return true
    }
    return false
}
