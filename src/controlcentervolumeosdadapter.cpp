// SPDX-License-Identifier: GPL-2.0-or-later

#include "controlcentervolumeosdadapter.h"

#include <KConfigGroup>

#include <QDir>

namespace
{
constexpr auto s_configGroup = "General";
constexpr auto s_volumeOsdKey = "VolumeOsd";
}

ControlCenterVolumeOsdAdapter::ControlCenterVolumeOsdAdapter(QObject *parent)
    : ControlCenterVolumeOsdAdapter(KSharedConfig::openConfig(QStringLiteral("plasmaparc")), parent)
{
}

ControlCenterVolumeOsdAdapter::ControlCenterVolumeOsdAdapter(const KSharedConfig::Ptr &config, QObject *parent)
    : QObject(parent)
    , m_config(config)
{
    if (!QDir::isAbsolutePath(m_config->name())) {
        m_configWatcher = KConfigWatcher::create(m_config);
        connect(m_configWatcher.data(), &KConfigWatcher::configChanged, this, [this](const KConfigGroup &group, const QByteArrayList &keys) {
            if (group.name() == QLatin1String(s_configGroup)
                && (keys.isEmpty() || keys.contains(QByteArrayLiteral("VolumeOsd")))) {
                refresh();
            }
        });
    }
    refresh();
}

bool ControlCenterVolumeOsdAdapter::osdVisible() const
{
    return m_osdVisible;
}

bool ControlCenterVolumeOsdAdapter::writable() const
{
    return m_writable;
}

bool ControlCenterVolumeOsdAdapter::toggleOsd()
{
    KConfigGroup group(m_config, QString::fromLatin1(s_configGroup));
    if (group.accessMode() != KConfigBase::ReadWrite
        || group.isEntryImmutable(s_volumeOsdKey)) {
        refresh();
        return false;
    }

    const bool updatedVisibility = !m_osdVisible;
    group.writeEntry(s_volumeOsdKey, updatedVisibility, KConfig::Notify);
    if (!group.sync()) {
        refresh();
        return false;
    }

    updateState(updatedVisibility, true);
    return true;
}

void ControlCenterVolumeOsdAdapter::refresh()
{
    m_config->reparseConfiguration();
    const KConfigGroup group(m_config, QString::fromLatin1(s_configGroup));
    updateState(group.readEntry(s_volumeOsdKey, true),
                group.accessMode() == KConfigBase::ReadWrite
                    && !group.isEntryImmutable(s_volumeOsdKey));
}

void ControlCenterVolumeOsdAdapter::updateState(bool osdVisible, bool writable)
{
    if (m_osdVisible == osdVisible && m_writable == writable) {
        return;
    }
    m_osdVisible = osdVisible;
    m_writable = writable;
    Q_EMIT stateChanged();
}
