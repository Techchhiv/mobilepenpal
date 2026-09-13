import React from 'react';
import { Icon } from '@iconify/react';

export default function AdminErrorState({
  title = 'Failed to Load Data',
  message = 'An unexpected error occurred while fetching information from the server.',
  onRetry,
}) {
  return (
    <div className="card border radius-12 p-32 text-center my-12 border-danger-200 bg-danger-50 shadow-none">
      <div className="w-56-px h-56-px bg-danger-focus radius-50 d-inline-flex align-items-center justify-content-center mx-auto mb-16">
        <Icon icon="mdi:alert-circle" className="text-danger-main text-2xl" />
      </div>
      <h6 className="fw-bold text-danger-main mb-8">{title}</h6>
      <p className="text-secondary-light text-sm max-w-450-px mx-auto mb-20">{message}</p>
      {onRetry && (
        <div>
          <button
            type="button"
            className="btn btn-primary btn-sm radius-8 d-inline-flex align-items-center gap-8"
            onClick={onRetry}
          >
            <Icon icon="mdi:refresh" />
            <span>Try Again</span>
          </button>
        </div>
      )}
    </div>
  );
}
