// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QMargins>
#include <QObject>
#include <QPoint>
#include <QPointer>
#include <QRegion>
#include <QWindow>
#include <qqmlintegration.h>

class BlurBehindController : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QObject *window READ window WRITE setWindow NOTIFY windowChanged)
    Q_PROPERTY(QObject *maskSource READ maskSource WRITE setMaskSource NOTIFY maskSourceChanged)
    Q_PROPERTY(QPoint maskOffset READ maskOffset WRITE setMaskOffset NOTIFY maskOffsetChanged)
    Q_PROPERTY(bool useMaskSourceInsets READ useMaskSourceInsets WRITE setUseMaskSourceInsets NOTIFY useMaskSourceInsetsChanged)
    Q_PROPERTY(bool fullWindow READ fullWindow WRITE setFullWindow NOTIFY fullWindowChanged)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)
    Q_PROPERTY(bool active READ active NOTIFY activeChanged)

public:
    explicit BlurBehindController(QObject *parent = nullptr);
    ~BlurBehindController() override;

    QObject *window() const;
    void setWindow(QObject *window);
    QObject *maskSource() const;
    void setMaskSource(QObject *maskSource);
    QPoint maskOffset() const;
    void setMaskOffset(const QPoint &maskOffset);
    bool useMaskSourceInsets() const;
    void setUseMaskSourceInsets(bool useMaskSourceInsets);
    bool fullWindow() const;
    void setFullWindow(bool fullWindow);
    bool enabled() const;
    void setEnabled(bool enabled);
    bool available() const;
    bool active() const;

    static QRegion contractMaskToInsets(const QRegion &sourceMask, const QMargins &insets);

public Q_SLOTS:
    void reapply();

Q_SIGNALS:
    void windowChanged();
    void maskSourceChanged();
    void maskOffsetChanged();
    void useMaskSourceInsetsChanged();
    void fullWindowChanged();
    void enabledChanged();
    void availableChanged();
    void activeChanged();

private:
    bool eventFilter(QObject *watched, QEvent *event) override;
    void invalidateMaskCache();
    void refreshAvailability();
    void apply();
    void disableOnCurrentWindow();
    void updateActive(bool active);

    QPointer<QWindow> m_window;
    QPointer<QObject> m_maskSource;
    QPointer<QObject> m_maskInsetSource;
    QPoint m_maskOffset;
    QRegion m_cachedSourceMask;
    QRegion m_cachedContractedMask;
    QMargins m_cachedInsets;
    bool m_maskCacheValid = false;
    bool m_reapplyScheduled = false;
    bool m_useMaskSourceInsets = false;
    bool m_fullWindow = false;
    bool m_enabled = false;
    bool m_available = false;
    bool m_active = false;
};
