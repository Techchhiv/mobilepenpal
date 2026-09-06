import React, { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Icon } from '@iconify/react';
import { useAuth } from '../../../context/AuthContext';

export default function ClientActionMenu({
  school,
  onToggleStatus,
  onEditSchool,
  onDeleteSchool,
}) {
  const [open, setOpen] = useState(false);
  const [coords, setCoords] = useState({ top: null, bottom: null, right: 16 });
  const menuRef = useRef(null);
  const buttonRef = useRef(null);
  const navigate = useNavigate();
  const { isSuperAdmin, hasPermission } = useAuth();

  const canViewReports =
    isSuperAdmin || hasPermission('menu.reports') || hasPermission('reports.view');
  const canViewPayments = isSuperAdmin || hasPermission('menu.payments');
  const canViewInvoices =
    isSuperAdmin || hasPermission('billing.view') || hasPermission('menu.payments');
  const canViewSubscriptions = isSuperAdmin || hasPermission('menu.payments');
  const canManageClients = isSuperAdmin || hasPermission('menu.manage_clients');

  const updatePosition = () => {
    if (!buttonRef.current) return;
    const rect = buttonRef.current.getBoundingClientRect();
    const menuHeight = 280;
    const spaceBelow = window.innerHeight - rect.bottom;
    const spaceAbove = rect.top;

    // Open downwards if space below >= menuHeight, otherwise upwards
    const openUp = spaceBelow < menuHeight && spaceAbove > spaceBelow;

    setCoords({
      top: openUp ? null : rect.bottom + 4,
      bottom: openUp ? window.innerHeight - rect.top + 4 : null,
      right: Math.max(16, window.innerWidth - rect.right),
    });
  };

  const handleToggle = (e) => {
    e.stopPropagation();
    if (!open) {
      updatePosition();
      setOpen(true);
    } else {
      setOpen(false);
    }
  };

  useEffect(() => {
    if (!open) return;

    function handleClickOutside(e) {
      if (
        menuRef.current &&
        !menuRef.current.contains(e.target) &&
        buttonRef.current &&
        !buttonRef.current.contains(e.target)
      ) {
        setOpen(false);
      }
    }

    function handleScrollOrResize(e) {
      if (menuRef.current && !menuRef.current.contains(e.target)) {
        setOpen(false);
      }
    }

    document.addEventListener('mousedown', handleClickOutside);
    window.addEventListener('scroll', handleScrollOrResize, true);
    window.addEventListener('resize', handleScrollOrResize);

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
      window.removeEventListener('scroll', handleScrollOrResize, true);
      window.removeEventListener('resize', handleScrollOrResize);
    };
  }, [open]);

  const isCurrentlyActive = Boolean(
    school.is_active || school.status === 'active'
  );

  return (
    <div className="client-action-wrapper position-relative d-inline-block">
      <button
        ref={buttonRef}
        type="button"
        className="action-dropdown-btn"
        onClick={handleToggle}
        aria-label="Client actions"
        aria-expanded={open}
        title="More actions"
      >
        <Icon icon="mdi:dots-vertical" className="text-lg" />
      </button>

      {open && (
        <div
          ref={menuRef}
          className="client-action-menu client-action-menu-floating"
          style={{
            position: 'fixed',
            top: coords.top !== null ? `${coords.top}px` : 'auto',
            bottom: coords.bottom !== null ? `${coords.bottom}px` : 'auto',
            right: `${coords.right}px`,
            zIndex: 1070,
          }}
          role="menu"
          onClick={(e) => e.stopPropagation()}
        >
          {/* 1. View Details */}
          {canViewReports && (
            <button
              type="button"
              className="client-action-item"
              onClick={() => {
                setOpen(false);
                navigate(`/admin/reports/schools/${school.id}`);
              }}
            >
              <Icon icon="mdi:eye-outline" className="text-primary-600" />
              <span>View Details</span>
            </button>
          )}

          {/* 2. View Subscription */}
          {canViewSubscriptions && (
            <button
              type="button"
              className="client-action-item"
              onClick={() => {
                setOpen(false);
                navigate('/admin/subscriptions/schools');
              }}
            >
              <Icon icon="mdi:card-account-details-outline" className="text-info-main" />
              <span>View Subscription</span>
            </button>
          )}

          {/* 3. View Payments */}
          {canViewPayments && (
            <button
              type="button"
              className="client-action-item"
              onClick={() => {
                setOpen(false);
                navigate(`/admin/schools/${school.id}/payments`);
              }}
            >
              <Icon icon="mdi:cash-multiple" className="text-success-main" />
              <span>View Payments</span>
            </button>
          )}

          {/* 4. View Invoices */}
          {canViewInvoices && (
            <button
              type="button"
              className="client-action-item"
              onClick={() => {
                setOpen(false);
                navigate('/admin/invoices');
              }}
            >
              <Icon icon="mdi:file-document-outline" className="text-secondary" />
              <span>View Invoices</span>
            </button>
          )}

          {/* Divider */}
          {(canViewReports || canViewPayments || canViewInvoices || canViewSubscriptions) && (
            <div className="client-action-divider" />
          )}

          {/* 5. Activate / Deactivate */}
          {canManageClients && (
            <button
              type="button"
              className={`client-action-item ${
                isCurrentlyActive ? 'text-danger' : 'text-success'
              }`}
              onClick={() => {
                setOpen(false);
                onToggleStatus(school);
              }}
            >
              <Icon
                icon={
                  isCurrentlyActive
                    ? 'mdi:account-cancel-outline'
                    : 'mdi:account-check-outline'
                }
              />
              <span>{isCurrentlyActive ? 'Deactivate School' : 'Activate School'}</span>
            </button>
          )}

          {/* 6. Edit School */}
          {canManageClients && (
            <button
              type="button"
              className="client-action-item"
              onClick={() => {
                setOpen(false);
                onEditSchool(school);
              }}
            >
              <Icon icon="lucide:edit" className="text-warning-main" />
              <span>Edit School</span>
            </button>
          )}

          {/* 7. Delete School */}
          {canManageClients && (
            <button
              type="button"
              className="client-action-item text-danger"
              onClick={() => {
                setOpen(false);
                onDeleteSchool(school);
              }}
            >
              <Icon icon="mingcute:delete-2-line" />
              <span>Delete School</span>
            </button>
          )}
        </div>
      )}
    </div>
  );
}
