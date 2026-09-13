import React, { useEffect, useState } from 'react';
import { Icon } from '@iconify/react';
import API from '../../../helper/api';

export default function EditSchoolModal({ isOpen, school, onClose, onSuccess }) {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [schoolKey, setSchoolKey] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (school) {
      setName(school.name || '');
      setEmail(school.admin_email || school.admin?.email || '');
      setSchoolKey(school.school_key || '');
      setError('');
    }
  }, [school]);

  if (!isOpen || !school) return null;

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSubmitting(true);
    try {
      await API.put(`admin/schools/${school.id}`, {
        name,
        admin_email: email,
        school_key: schoolKey,
      });
      onSuccess(`School "${name}" updated successfully.`);
      onClose();
    } catch (err) {
      setError(err?.response?.data?.message || 'Failed to update school.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleClose = () => {
    if (submitting) return;
    setError('');
    onClose();
  };

  return (
    <div className="client-modal-backdrop" onClick={handleClose} role="dialog" aria-modal="true">
      <div
        className="client-modal-content"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="client-modal-header">
          <div className="d-flex align-items-center gap-12">
            <div className="client-modal-icon-badge bg-warning-50 text-warning-600">
              <Icon icon="lucide:edit" className="text-xl" />
            </div>
            <div>
              <h6 className="mb-2 fw-semibold text-primary-light">Edit School</h6>
              <p className="text-secondary-light text-xs mb-0">
                Update school information, school key, or admin email.
              </p>
            </div>
          </div>
          <button
            type="button"
            className="client-modal-close-btn"
            onClick={handleClose}
            disabled={submitting}
            aria-label="Close modal"
          >
            <Icon icon="mdi:close" className="text-lg" />
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="client-modal-body d-flex flex-column gap-18">
            {error && (
              <div className="alert alert-danger py-10 px-16 text-sm radius-8 mb-0 d-flex align-items-center gap-8" role="alert">
                <Icon icon="mdi:alert-circle-outline" className="text-lg flex-shrink-0" />
                <span>{error}</span>
              </div>
            )}

            <div>
              <label className="form-label fw-semibold text-secondary-light text-xs mb-6">
                School Name <span className="text-danger">*</span>
              </label>
              <input
                type="text"
                className="form-control"
                value={name}
                onChange={(e) => setName(e.target.value)}
                required
              />
            </div>

            <div>
              <label className="form-label fw-semibold text-secondary-light text-xs mb-6">
                Admin Email <span className="text-danger">*</span>
              </label>
              <input
                type="email"
                className="form-control"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>

            <div>
              <label className="form-label fw-semibold text-secondary-light text-xs mb-6">
                School Key <span className="text-danger">*</span>
              </label>
              <input
                type="text"
                className="form-control text-uppercase"
                value={schoolKey}
                onChange={(e) => setSchoolKey(e.target.value.toUpperCase())}
                required
              />
              <span className="text-secondary-light text-xs mt-4 d-block">
                Unique identifier used by school staff and students to sign in.
              </span>
            </div>
          </div>

          <div className="client-modal-footer">
            <button
              type="button"
              className="btn btn-outline-neutral text-secondary-light radius-8 px-18 py-9"
              onClick={handleClose}
              disabled={submitting}
            >
              Cancel
            </button>
            <button
              type="submit"
              className="btn btn-primary radius-8 px-20 py-9 d-inline-flex align-items-center gap-8 fw-semibold"
              disabled={submitting}
            >
              {submitting ? (
                <>
                  <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true" />
                  <span>Saving...</span>
                </>
              ) : (
                <>
                  <Icon icon="mdi:check" className="text-md" />
                  <span>Save Changes</span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
