// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QPointer>
#include <QRect>
#include <QWindow>
#include <qqmlintegration.h>

class BlurBehindController : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QObject *window READ window WRITE setWindow NOTIFY windowChanged)
    Q_PROPERTY(QRect region READ region WRITE setRegion NOTIFY regionChanged)
    Q_PROPERTY(bool fullWindow READ fullWindow WRITE setFullWindow NOTIFY fullWindowChanged)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)
    Q_PROPERTY(bool active READ active NOTIFY activeChanged)

public:
    explicit BlurBehindController(QObject *parent = nullptr);
    ~BlurBehindController() override;

    QObject *window() const;
    void setWindow(QObject *window);
    QRect region() const;
    void setRegion(const QRect &region);
    bool fullWindow() const;
    void setFullWindow(bool fullWindow);
    bool enabled() const;
    void setEnabled(bool enabled);
    bool available() const;
    bool active() const;

    Q_INVOKABLE void reapply();

Q_SIGNALS:
    void windowChanged();
    void regionChanged();
    void fullWindowChanged();
    void enabledChanged();
    void availableChanged();
    void activeChanged();

private:
    bool eventFilter(QObject *watched, QEvent *event) override;
    void refreshAvailability();
    void apply();
    void disableOnCurrentWindow();
    void updateActive(bool active);

    QPointer<QWindow> m_window;
    QRect m_region;
    bool m_fullWindow = false;
    bool m_enabled = false;
    bool m_available = false;
    bool m_active = false;
};
