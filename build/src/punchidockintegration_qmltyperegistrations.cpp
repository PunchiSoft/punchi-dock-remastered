/****************************************************************************
** Generated QML type registration code
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include <QtQml/qqml.h>
#include <QtQml/qqmlmoduleregistration.h>

#if __has_include(<systemdiscovery.h>)
#  include <systemdiscovery.h>
#endif
#if __has_include(<trashintegration.h>)
#  include <trashintegration.h>
#endif


#if !defined(QT_STATIC)
#define Q_QMLTYPE_EXPORT Q_DECL_EXPORT
#else
#define Q_QMLTYPE_EXPORT
#endif
Q_QMLTYPE_EXPORT void qml_register_types_org_punchi_dock()
{
    QT_WARNING_PUSH QT_WARNING_DISABLE_DEPRECATED
    qmlRegisterTypesAndRevisions<SystemDiscovery>("org.punchi.dock", 1);
    qmlRegisterTypesAndRevisions<TrashIntegration>("org.punchi.dock", 1);
    QT_WARNING_POP
    qmlRegisterModule("org.punchi.dock", 1, 0);
}

static const QQmlModuleRegistration orgpunchidockRegistration("org.punchi.dock", qml_register_types_org_punchi_dock);
