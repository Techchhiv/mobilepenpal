import React from 'react';
import { Icon } from '@iconify/react';

const cards = [
  {
    gradient: 'bg-gradient-start-1',
    iconBg: 'bg-cyan',
    icon: 'mdi:school',
    label: 'Total Schools',
    key: 'totalSchools',
  },
  {
    gradient: 'bg-gradient-start-2',
    iconBg: 'bg-purple',
    icon: 'nrk:check-active',
    label: 'Active Schools',
    key: 'activeSchools',
  },
  {
    gradient: 'bg-gradient-start-3',
    iconBg: 'bg-info',
    icon: 'fluent:people-20-filled',
    label: 'Total Students',
    key: 'totalStudents',
  },
  {
    gradient: 'bg-gradient-start-4',
    iconBg: 'bg-success-main',
    icon: 'ph:chalkboard-teacher-fill',
    label: 'Total Teachers',
    key: 'totalTeachers',
  },
];

export default function ReportSummaryCards({ summary = {} }) {
  return (
    <div className="row row-cols-xxxl-4 row-cols-lg-4 row-cols-sm-2 row-cols-1 gy-4 mb-4">
      {cards.map(({ gradient, iconBg, icon, label, key }) => (
        <div className="col" key={key}>
          <div className={`card school-report-summary-card shadow-sm ${gradient} h-100`}>
            <div className="card-body p-20">
              <div className="d-flex flex-wrap align-items-center justify-content-between gap-3">
                <div>
                  <p className="fw-medium text-primary-light mb-1">{label}</p>
                  <h6 className="mb-0">{summary[key] ?? 0}</h6>
                </div>
                <div className={`w-50-px h-50-px ${iconBg} rounded-circle d-flex justify-content-center align-items-center`}>
                  <Icon icon={icon} className="text-white text-2xl mb-0" />
                </div>
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
