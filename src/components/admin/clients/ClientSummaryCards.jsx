import React from 'react';
import { Icon } from '@iconify/react';

export default function ClientSummaryCards({ summary, loading }) {
  const cards = [
    {
      label: 'Total Clients',
      value: summary?.total ?? 0,
      icon: 'mdi:domain',
      iconBg: 'bg-primary-light',
      iconColor: 'text-primary-600',
      badgeBg: 'bg-primary-focus',
      badgeColor: 'text-primary-600',
    },
    {
      label: 'Active Clients',
      value: summary?.active ?? 0,
      icon: 'mdi:check-circle-outline',
      iconBg: 'bg-success-focus',
      iconColor: 'text-success-main',
      badgeBg: 'bg-success-focus',
      badgeColor: 'text-success-main',
    },
    {
      label: 'Inactive Clients',
      value: summary?.inactive ?? 0,
      icon: 'mdi:close-circle-outline',
      iconBg: 'bg-danger-focus',
      iconColor: 'text-danger-main',
      badgeBg: 'bg-danger-focus',
      badgeColor: 'text-danger-main',
    },
  ];

  return (
    <div className="row g-3 mb-24">
      {cards.map((card) => (
        <div key={card.label} className="col-12 col-sm-4">
          <div className="card client-summary-card h-100">
            <div className="card-body p-20 d-flex align-items-center justify-content-between">
              <div>
                <p className="text-secondary-light text-sm fw-medium mb-4">
                  {card.label}
                </p>
                <h4 className="fw-bold mb-0">
                  {loading ? (
                    <span
                      className="placeholder col-6 d-inline-block"
                      style={{ height: '28px', minWidth: '40px' }}
                    />
                  ) : (
                    Number(card.value).toLocaleString()
                  )}
                </h4>
              </div>
              <div
                className={`client-summary-icon ${card.iconBg} ${card.iconColor}`}
              >
                <Icon icon={card.icon} />
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
