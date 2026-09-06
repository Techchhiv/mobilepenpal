import React, { useState } from 'react';
import { Icon } from '@iconify/react';
import API from '../../../helper/api';

export default function CreateSchoolModal({ isOpen, onClose, onSuccess }) {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [schoolKey, setSchoolKey] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [generatingKey, setGeneratingKey] = useState(false);
  const [error, setError] = useState('');

  if (!isOpen) return null;

  const handleGenerateKey = async () => {
    setGeneratingKey(true);
    try {
      const res = await API.get('admin/schools/generate-key');
      if (res.data?.key) {
        setSchoolKey(res.data.key);
      }
    } catch {
      setError('Failed to generate school key.');
    } finally {
      setGeneratingKey(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSubmitting(true);
    try {
      await API.post('admin/schools', {
        name,
        email,
        password,
        school_key: schoolKey,
      });
      setName('');
      setEmail('');
      setPassword('');
      setSchoolKey('');
      setShowPassword(false);
      onSuccess('School created successfully.');
      onClose();
    } catch (err) {
      setError(err?.response?.data?.message || 'Failed to create school.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleClose = () => {
    if (submitting) return;
    setError('');
    setShowPassword(false);
    onClose();
  };

  return (
    <div className="client-modal-backdrop" onClick={handleClose} role="dialog" aria-modal="true">
      <div
        className="client-modal-content"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="client-modal-header">
          <div className="d-flex align-items-center gap-12">
            <div className="client-modal-icon-badge bg-primary-50 text-primary-600">
              <Icon icon="mdi:school" className="text-xl" />
            </div>
            <div>
              <h6 className="mb-2 fw-semibold text-primary-light">Create New School</h6>
              <p className="text-secondary-light text-xs mb-0">
                Register a new school client and assign its administrator.
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

        {/* Body */}
        <form onSubmit={handleSubmit}>
          <div className="client-modal-body d-flex flex-column gap-18">
            {error && (
              <div className="alert alert-danger py-10 px-16 text-sm radius-8 mb-0 d-flex align-items-center gap-8" role="alert">
                <Icon icon="mdi:alert-circle-outline" className="text-lg flex-shrink-0" />
                <span>{error}</span>
              </div>
            )}

            {/* School Name */}
            <div>
              <label className="form-label fw-semibold text-secondary-light text-xs mb-6">
                School Name <span className="text-danger">*</span>
              </label>
              <input
                type="text"
                className="form-control"
                placeholder="e.g. Angkor International School"
                value={name}
                onChange={(e) => setName(e.target.value)}
                required
              />
            </div>

            {/* Admin Email */}
            <div>
              <label className="form-label fw-semibold text-secondary-light text-xs mb-6">
                Admin Email <span className="text-danger">*</span>
              </label>
              <input
                type="email"
                className="form-control"
                placeholder="admin@school.edu"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>

            {/* Admin Password */}
            <div>
              <label className="form-label fw-semibold text-secondary-light text-xs mb-6">
                Admin Password <span className="text-danger">*</span>
              </label>
              <div className="input-group">
                <input
                  type={showPassword ? 'text' : 'password'}
                  className="form-control"
                  placeholder="Minimum 8 characters"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  minLength={8}
                  required
                />
                <button
                  type="button"
                  className="btn btn-outline-neutral text-secondary-light px-12"
                  onClick={() => setShowPassword(!showPassword)}
                  aria-label={showPassword ? 'Hide password' : 'Show password'}
                  title={showPassword ? 'Hide password' : 'Show password'}
                >
                  <Icon icon={showPassword ? 'mdi:eye-off-outline' : 'mdi:eye-outline'} className="text-md" />
                </button>
              </div>
              <span className="text-secondary-light text-xs mt-4 d-block">
                Must be at least 8 characters long.
              </span>
            </div>

            {/* School Key */}
            <div>
              <label className="form-label fw-semibold text-secondary-light text-xs mb-6">
                School Key <span className="text-danger">*</span>
              </label>
              <div className="input-group">
                <input
                  type="text"
                  className="form-control text-uppercase"
                  placeholder="e.g. SCH-00123"
                  value={schoolKey}
                  onChange={(e) => setSchoolKey(e.target.value.toUpperCase())}
                  required
                />
                <button
                  type="button"
                  className="btn btn-outline-primary d-inline-flex align-items-center gap-6 px-14"
                  onClick={handleGenerateKey}
                  disabled={generatingKey}
                  title="Generate a unique school key"
                >
                  {generatingKey ? (
                    <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true" />
                  ) : (
                    <Icon icon="mdi:refresh" />
                  )}
                  <span>Generate</span>
                </button>
              </div>
              <span className="text-secondary-light text-xs mt-4 d-block">
                Unique identifier used by school staff and students to sign in.
              </span>
            </div>
          </div>

          {/* Footer */}
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
                  <span>Creating...</span>
                </>
              ) : (
                <>
                  <Icon icon="lucide:plus" className="text-md" />
                  <span>Create School</span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
