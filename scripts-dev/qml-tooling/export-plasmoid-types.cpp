// SPDX-License-Identifier: GPL-3.0-or-later
#include <QApplication>
#include <QDir>
#include <Plasma/Applet>
#include <Plasma/Corona>
#include <Plasma/Containment>
#include <PlasmaQuick/AppletQuickItem>
#include <KPluginMetaData>
#include <KPackage/PackageLoader>
#include <KPackage/Package>
#include <private/qqmlmetatype_p.h>
#include <private/qqmltype_p.h>
#include <QQmlEngine>
#include <QDebug>
#include <QMetaProperty>
#include <QMetaMethod>
#include <QMetaEnum>
#include <QTextStream>
#include <QJsonDocument>
#include <QJsonArray>
#include <QMap>
#include <private/qqmlengine_p.h>
class ProbeCorona : public Plasma::Corona { public: QRect screenGeometry(int) const override { return QRect(0,0,800,600); } };
int main(int argc, char **argv) {
 const QString root=QString::fromLocal8Bit(qgetenv("PUNCHI_TOOLING_ENVIRONMENT_ROOT"));
 if(root.isEmpty() || !QDir(root).exists()) { qCritical("An isolated tooling environment is required"); return 2; }
 for(auto variable: {"XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME", "XDG_RUNTIME_DIR"}) {
  const QString path=QString::fromLocal8Bit(qgetenv(variable));
  if(!path.startsWith(root+QLatin1Char('/')) || !QDir(path).exists()) { qCritical("Tooling XDG directories must stay in the isolated environment"); return 2; }
 }
 QApplication app(argc,argv);
 if(argc != 1) { qCritical("This exporter accepts no arguments"); return 2; }
 // Plasma 6.3 registers the module in itemForApplet, not in a QML plugin.
 // A disposable destroyed applet triggers registration without loading UI.
 ProbeCorona corona;
 auto shell=KPackage::PackageLoader::self()->loadPackage(QStringLiteral("Plasma/Shell"));
 shell.setPath(QStringLiteral("org.kde.plasma.desktop"));
 corona.setKPackage(shell);
 auto *containment=corona.createContainment(QStringLiteral("null"));
 auto *applet=new Plasma::Applet(nullptr,KPluginMetaData(),{});
 containment->addApplet(applet);
 applet->destroy();
 PlasmaQuick::AppletQuickItem::itemForApplet(applet);
 QQmlEngine engine;
 QTextStream out(stdout);
 out << "import QtQuick.tooling 1.2\nModule {\n";
 auto quote=[](const QByteArray &s) { return QString::fromUtf8(QJsonDocument(QJsonArray{QString::fromUtf8(s)}).toJson(QJsonDocument::Compact)).mid(1).chopped(1); };
 QMap<QString,QQmlType> types;
 QMap<QByteArray,const QMetaObject *> attachedObjects;
 for(const auto &t: QQmlMetaType::qmlTypes()) if(t.module()==QStringLiteral("org.kde.plasma.plasmoid")) types.insert(t.qmlTypeName(),t);
 for(const auto &t: types) {
  const auto *mo=t.metaObject();
  out << " Component {\n  accessSemantics: \"reference\"\n  name: " << quote(mo->className()) << "\n  prototype: " << quote(mo->inherits(&QQuickItem::staticMetaObject) ? "QQuickItem" : "QObject") << "\n  exports: [" << quote((t.qmlTypeName()+QStringLiteral(" 2.0")).toUtf8()) << "]\n  exportMetaObjectRevisions: [512]\n";
  if(!t.isCreatable()) out << "  isCreatable: false\n";
  if(t.isSingleton()) out << "  isSingleton: true\n";
  if(t.attachedPropertiesType(QQmlEnginePrivate::get(&engine))) out << "  attachedType: " << quote(t.attachedPropertiesType(QQmlEnginePrivate::get(&engine))->className()) << "\n";
  for(int i=0;i<mo->classInfoCount();++i) if(QByteArray(mo->classInfo(i).name())=="DefaultProperty") out << "  defaultProperty: " << quote(mo->classInfo(i).value()) << "\n";
  for(int i=mo->inherits(&QQuickItem::staticMetaObject) ? QQuickItem::staticMetaObject.propertyCount() : 0;i<mo->propertyCount();++i) {
   auto p=mo->property(i); QByteArray type=p.isEnumType() ? p.enumerator().name() : p.typeName(); bool pointer=type.endsWith('*'), list=type.startsWith("QQmlListProperty<");
   if(pointer) type.chop(1);
   if(list) type=type.mid(17).chopped(1);
   out << "  Property { name: " << quote(p.name()) << "; type: " << quote(type);
   if(pointer) out << "; isPointer: true";
   if(list) out << "; isList: true";
   if(!p.isWritable()) out << "; isReadonly: true";
   out << " }\n";
  }
  for(int i=mo->inherits(&QQuickItem::staticMetaObject) ? QQuickItem::staticMetaObject.methodCount() : 0;i<mo->methodCount();++i) {
   auto m=mo->method(i); if(m.access()==QMetaMethod::Private) continue;
   out << (m.methodType()==QMetaMethod::Signal ? "  Signal { name: " : "  Method { name: ") << quote(m.name()) << "\n";
   if(QByteArray(m.typeName())!="void") out << "   type: " << quote(m.typeName()) << "\n";
   auto names=m.parameterNames(), params=m.parameterTypes();
   for(int k=0;k<params.size();++k) out << "   Parameter { name: " << quote(names[k]) << "; type: " << quote(params[k]) << " }\n";
   out << "  }\n";
  }
  QMap<QByteArray,QMetaEnum> enums;
  for(int i=0;i<mo->enumeratorCount();++i) { auto e=mo->enumerator(i); enums.insert(e.name(),e); }
  for(int i=0;i<mo->propertyCount();++i) { auto p=mo->property(i); if(p.isEnumType()) { auto e=p.enumerator(); enums.insert(e.name(),e); } }
  for(auto e: enums) {
   out << "  Enum { name: " << quote(e.name()) << "; values: {";
   for(int k=0;k<e.keyCount();++k) {if(k) out << ",";out << quote(e.key(k)) << ": " << e.value(k);}
   out << "} }\n";
  }
  out << " }\n";
  if(auto a=t.attachedPropertiesType(QQmlEnginePrivate::get(&engine))) attachedObjects.insert(a->className(),mo);
 }
 for(auto it=attachedObjects.cbegin(); it!=attachedObjects.cend(); ++it) {
  auto mo=it.value();
  out << " Component { name: " << quote(it.key()) << "; accessSemantics: \"reference\"; prototype: \"QObject\"\n";
  for(int i=mo->inherits(&QQuickItem::staticMetaObject) ? QQuickItem::staticMetaObject.propertyCount() : 0;i<mo->propertyCount();++i) {auto p=mo->property(i); QByteArray type=p.isEnumType() ? p.enumerator().name() : p.typeName(); bool pointer=type.endsWith('*'); if(pointer)type.chop(1); out << " Property { name: " << quote(p.name()) << "; type: " << quote(type);if(pointer)out << "; isPointer: true"; if(!p.isWritable())out << "; isReadonly: true";out << " }\n";}
  for(int i=mo->inherits(&QQuickItem::staticMetaObject) ? QQuickItem::staticMetaObject.methodCount() : 0;i<mo->methodCount();++i) {
   auto m=mo->method(i); if(m.access()==QMetaMethod::Private) continue;
   out << (m.methodType()==QMetaMethod::Signal ? "  Signal { name: " : "  Method { name: ") << quote(m.name()) << "\n";
   if(QByteArray(m.typeName())!="void") out << "   type: " << quote(m.typeName()) << "\n";
   auto names=m.parameterNames(), params=m.parameterTypes();
   for(int k=0;k<params.size();++k) out << "   Parameter { name: " << quote(names[k]) << "; type: " << quote(params[k]) << " }\n";
   out << "  }\n";
  }
  QMap<QByteArray,QMetaEnum> enums;
  for(int i=0;i<mo->enumeratorCount();++i) { auto e=mo->enumerator(i); enums.insert(e.name(),e); }
  for(int i=0;i<mo->propertyCount();++i) { auto p=mo->property(i); if(p.isEnumType()) { auto e=p.enumerator(); enums.insert(e.name(),e); } }
  for(auto e: enums) {
   out << "  Enum { name: " << quote(e.name()) << "; values: {";
   for(int k=0;k<e.keyCount();++k) {if(k) out << ",";out << quote(e.key(k)) << ": " << e.value(k);}
   out << "} }\n";
  }
  out << " }\n";
 }
 out << "}\n";
 if(types.size() != 5) { qCritical("Unexpected Plasma 6.3 type registry"); return 1; }
 QCoreApplication::sendPostedEvents(nullptr,QEvent::DeferredDelete);
}
