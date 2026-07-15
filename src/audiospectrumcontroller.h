// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QVariantList>
#include <qqmlregistration.h>

class AudioSpectrumManager;

class AudioSpectrumController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)
    Q_PROPERTY(bool active READ active NOTIFY activeChanged)
    Q_PROPERTY(QVariantList levels READ levels NOTIFY levelsChanged)

public:
    explicit AudioSpectrumController(QObject *parent = nullptr);
    ~AudioSpectrumController() override;

    bool enabled() const;
    void setEnabled(bool enabled);

    bool available() const;
    bool active() const;
    QVariantList levels() const;

Q_SIGNALS:
    void enabledChanged();
    void availableChanged();
    void activeChanged();
    void levelsChanged();

private:
    friend class AudioSpectrumManager;
    void applySnapshot(const QVariantList &levels, bool available, bool active);
    void clearSnapshot();

    bool m_enabled = false;
    bool m_available = false;
    bool m_active = false;
    QVariantList m_levels;
};
