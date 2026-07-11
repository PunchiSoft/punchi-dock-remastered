/****************************************************************************
** Meta object code from reading C++ file 'systemdiscovery.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.11.1)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../../src/systemdiscovery.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'systemdiscovery.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 69
#error "This file was generated using the moc from 6.11.1. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {
struct qt_meta_tag_ZN15SystemDiscoveryE_t {};
} // unnamed namespace

template <> constexpr inline auto SystemDiscovery::qt_create_metaobjectdata<qt_meta_tag_ZN15SystemDiscoveryE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "SystemDiscovery",
        "QML.Element",
        "auto",
        "folderEntriesReady",
        "",
        "QVariantList",
        "entries",
        "applicationsReady",
        "applications",
        "applicationReady",
        "QVariantMap",
        "application",
        "operationFailed",
        "operation",
        "message",
        "requestFolderEntries",
        "path",
        "requestApplications",
        "category",
        "requestApplication",
        "query",
        "iconForApplication",
        "applicationId",
        "applicationIdForCommand",
        "command",
        "launchApplication",
        "storageId",
        "launchApplicationByCommand",
        "openUrl",
        "url"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'folderEntriesReady'
        QtMocHelpers::SignalData<void(const QVariantList &)>(3, 4, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 5, 6 },
        }}),
        // Signal 'applicationsReady'
        QtMocHelpers::SignalData<void(const QVariantList &)>(7, 4, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 5, 8 },
        }}),
        // Signal 'applicationReady'
        QtMocHelpers::SignalData<void(const QVariantMap &)>(9, 4, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 10, 11 },
        }}),
        // Signal 'operationFailed'
        QtMocHelpers::SignalData<void(const QString &, const QString &)>(12, 4, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 13 }, { QMetaType::QString, 14 },
        }}),
        // Method 'requestFolderEntries'
        QtMocHelpers::MethodData<void(const QString &)>(15, 4, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 16 },
        }}),
        // Method 'requestApplications'
        QtMocHelpers::MethodData<void(const QString &)>(17, 4, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 18 },
        }}),
        // Method 'requestApplications'
        QtMocHelpers::MethodData<void()>(17, 4, QMC::AccessPublic | QMC::MethodCloned, QMetaType::Void),
        // Method 'requestApplication'
        QtMocHelpers::MethodData<void(const QString &)>(19, 4, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 20 },
        }}),
        // Method 'iconForApplication'
        QtMocHelpers::MethodData<QString(const QString &) const>(21, 4, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::QString, 22 },
        }}),
        // Method 'applicationIdForCommand'
        QtMocHelpers::MethodData<QString(const QString &) const>(23, 4, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::QString, 24 },
        }}),
        // Method 'launchApplication'
        QtMocHelpers::MethodData<void(const QString &)>(25, 4, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 26 },
        }}),
        // Method 'launchApplicationByCommand'
        QtMocHelpers::MethodData<bool(const QString &)>(27, 4, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 24 },
        }}),
        // Method 'openUrl'
        QtMocHelpers::MethodData<void(const QString &)>(28, 4, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 29 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
    };
    QtMocHelpers::UintData qt_enums {
    };
    QtMocHelpers::UintData qt_constructors {};
    QtMocHelpers::ClassInfos qt_classinfo({
            {    1,    2 },
    });
    return QtMocHelpers::metaObjectData<SystemDiscovery, void>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums, qt_constructors, qt_classinfo);
}
Q_CONSTINIT const QMetaObject SystemDiscovery::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN15SystemDiscoveryE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN15SystemDiscoveryE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN15SystemDiscoveryE_t>.metaTypes,
    nullptr
} };

void SystemDiscovery::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<SystemDiscovery *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->folderEntriesReady((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1]))); break;
        case 1: _t->applicationsReady((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1]))); break;
        case 2: _t->applicationReady((*reinterpret_cast<std::add_pointer_t<QVariantMap>>(_a[1]))); break;
        case 3: _t->operationFailed((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 4: _t->requestFolderEntries((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 5: _t->requestApplications((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 6: _t->requestApplications(); break;
        case 7: _t->requestApplication((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 8: { QString _r = _t->iconForApplication((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 9: { QString _r = _t->applicationIdForCommand((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 10: _t->launchApplication((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 11: { bool _r = _t->launchApplicationByCommand((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 12: _t->openUrl((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (SystemDiscovery::*)(const QVariantList & )>(_a, &SystemDiscovery::folderEntriesReady, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (SystemDiscovery::*)(const QVariantList & )>(_a, &SystemDiscovery::applicationsReady, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (SystemDiscovery::*)(const QVariantMap & )>(_a, &SystemDiscovery::applicationReady, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (SystemDiscovery::*)(const QString & , const QString & )>(_a, &SystemDiscovery::operationFailed, 3))
            return;
    }
}

const QMetaObject *SystemDiscovery::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *SystemDiscovery::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN15SystemDiscoveryE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int SystemDiscovery::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 13)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 13;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 13)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 13;
    }
    return _id;
}

// SIGNAL 0
void SystemDiscovery::folderEntriesReady(const QVariantList & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 0, nullptr, _t1);
}

// SIGNAL 1
void SystemDiscovery::applicationsReady(const QVariantList & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 1, nullptr, _t1);
}

// SIGNAL 2
void SystemDiscovery::applicationReady(const QVariantMap & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 2, nullptr, _t1);
}

// SIGNAL 3
void SystemDiscovery::operationFailed(const QString & _t1, const QString & _t2)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 3, nullptr, _t1, _t2);
}
QT_WARNING_POP
