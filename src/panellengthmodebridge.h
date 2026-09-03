// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <qqmlregistration.h>

class PanelLengthModeBridge : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(uint containmentId READ containmentId WRITE setContainmentId NOTIFY containmentIdChanged)
    Q_PROPERTY(int panelLengthMode READ panelLengthMode NOTIFY panelLengthModeChanged)
    Q_PROPERTY(bool fillAvailable READ fillAvailable NOTIFY panelLengthModeChanged)
    Q_PROPERTY(int reportedPanelLengthMode READ reportedPanelLengthMode WRITE setReportedPanelLengthMode)
    Q_PROPERTY(int panelFloatingMode READ panelFloatingMode NOTIFY panelFloatingModeChanged)
    Q_PROPERTY(int reportedPanelFloatingMode READ reportedPanelFloatingMode WRITE setReportedPanelFloatingMode)
    Q_PROPERTY(int panelVisibilityMode READ panelVisibilityMode NOTIFY panelVisibilityModeChanged)
    Q_PROPERTY(int reportedPanelVisibilityMode READ reportedPanelVisibilityMode WRITE setReportedPanelVisibilityMode)
    Q_PROPERTY(int panelAlignment READ panelAlignment NOTIFY panelAlignmentChanged)
    Q_PROPERTY(int reportedPanelAlignment READ reportedPanelAlignment WRITE setReportedPanelAlignment)
    Q_PROPERTY(int panelThickness READ panelThickness NOTIFY panelThicknessChanged)
    Q_PROPERTY(int reportedPanelThickness READ reportedPanelThickness WRITE setReportedPanelThickness)

public:
    explicit PanelLengthModeBridge(QObject *parent = nullptr);
    ~PanelLengthModeBridge() override;

    uint containmentId() const;
    void setContainmentId(uint containmentId);
    int panelLengthMode() const;
    bool fillAvailable() const;
    int reportedPanelLengthMode() const;
    void setReportedPanelLengthMode(int panelLengthMode);
    int panelFloatingMode() const;
    int reportedPanelFloatingMode() const;
    void setReportedPanelFloatingMode(int floatingMode);
    int panelVisibilityMode() const;
    int reportedPanelVisibilityMode() const;
    void setReportedPanelVisibilityMode(int visibilityMode);
    int panelAlignment() const;
    int reportedPanelAlignment() const;
    void setReportedPanelAlignment(int alignment);
    int panelThickness() const;
    int reportedPanelThickness() const;
    void setReportedPanelThickness(int thickness);
    void notifyPanelLengthModeChanged();
    void notifyPanelFloatingModeChanged();
    void notifyPanelVisibilityModeChanged();
    void notifyPanelAlignmentChanged();
    void notifyPanelThicknessChanged();

Q_SIGNALS:
    void containmentIdChanged();
    void panelLengthModeChanged();
    void panelFloatingModeChanged();
    void panelVisibilityModeChanged();
    void panelAlignmentChanged();
    void panelThicknessChanged();

private:
    uint m_containmentId = 0;
    int m_reportedPanelLengthMode = -1;
    int m_reportedPanelFloatingMode = -1;
    int m_reportedPanelVisibilityMode = -1;
    int m_reportedPanelAlignment = -1;
    int m_reportedPanelThickness = 0;
};
