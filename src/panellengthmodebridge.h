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

public:
    explicit PanelLengthModeBridge(QObject *parent = nullptr);
    ~PanelLengthModeBridge() override;

    uint containmentId() const;
    void setContainmentId(uint containmentId);
    int panelLengthMode() const;
    bool fillAvailable() const;
    int reportedPanelLengthMode() const;
    void setReportedPanelLengthMode(int panelLengthMode);
    void notifyPanelLengthModeChanged();

Q_SIGNALS:
    void containmentIdChanged();
    void panelLengthModeChanged();

private:
    uint m_containmentId = 0;
    int m_reportedPanelLengthMode = -1;
};
