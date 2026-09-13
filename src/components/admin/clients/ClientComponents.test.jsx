import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom';
import ClientSummaryCards from './ClientSummaryCards';
import ClientFilters from './ClientFilters';
import ClientTable from './ClientTable';
import StatusConfirmModal from './StatusConfirmModal';
import CreateSchoolModal from './CreateSchoolModal';

// Mock Iconify icon
jest.mock('@iconify/react', () => ({
  Icon: ({ icon, className, ...props }) => (
    <span data-testid="mock-icon" data-icon={icon} className={className} {...props} />
  ),
}));

// Mock API helper
jest.mock('../../../helper/api', () => ({
  __esModule: true,
  default: {
    get: jest.fn().mockResolvedValue({ data: {} }),
    post: jest.fn().mockResolvedValue({ data: {} }),
    put: jest.fn().mockResolvedValue({ data: {} }),
    delete: jest.fn().mockResolvedValue({ data: {} }),
  },
}));

// Mock AuthContext for ClientActionMenu
jest.mock('../../../context/AuthContext', () => ({
  useAuth: () => ({
    isSuperAdmin: true,
    hasPermission: () => true,
  }),
}));

// Mock react-router-dom useNavigate
const mockNavigate = jest.fn();
jest.mock('react-router-dom', () => ({
  useNavigate: () => mockNavigate,
}));

describe('Manage Clients Components', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('ClientSummaryCards', () => {
    it('renders total, active, and inactive counts', () => {
      render(
        <ClientSummaryCards
          summary={{ total: 50, active: 46, inactive: 4 }}
          loading={false}
        />
      );

      expect(screen.getByText('Total Clients')).toBeInTheDocument();
      expect(screen.getByText('50')).toBeInTheDocument();
      expect(screen.getByText('Active Clients')).toBeInTheDocument();
      expect(screen.getByText('46')).toBeInTheDocument();
      expect(screen.getByText('Inactive Clients')).toBeInTheDocument();
      expect(screen.getByText('4')).toBeInTheDocument();
    });

    it('renders skeleton placeholders while loading', () => {
      const { container } = render(
        <ClientSummaryCards summary={{}} loading={true} />
      );
      expect(container.querySelectorAll('.placeholder').length).toBe(3);
    });
  });

  describe('ClientFilters', () => {
    it('renders search and filter dropdowns', () => {
      render(
        <ClientFilters
          filters={{ search: '', schoolStatus: '', subscriptionStatus: '', plan: '' }}
          onChange={jest.fn()}
          onClear={jest.fn()}
        />
      );

      expect(screen.getByPlaceholderText('Name, school key, email...')).toBeInTheDocument();
      expect(screen.getByLabelText('Filter by school status')).toBeInTheDocument();
      expect(screen.getByLabelText('Filter by subscription status')).toBeInTheDocument();
      expect(screen.getByLabelText('Filter by plan')).toBeInTheDocument();
    });

    it('displays Clear Filters button when a filter is set and calls onClear', () => {
      const handleClear = jest.fn();
      render(
        <ClientFilters
          filters={{ search: 'Angkor', schoolStatus: '', subscriptionStatus: '', plan: '' }}
          onChange={jest.fn()}
          onClear={handleClear}
        />
      );

      const clearBtn = screen.getByText('Clear Filters');
      expect(clearBtn).toBeInTheDocument();
      fireEvent.click(clearBtn);
      expect(handleClear).toHaveBeenCalledTimes(1);
    });

    it('calls onChange when school status or plan changes', () => {
      const handleChange = jest.fn();
      render(
        <ClientFilters
          filters={{ search: '', schoolStatus: '', subscriptionStatus: '', plan: '' }}
          onChange={handleChange}
          onClear={jest.fn()}
        />
      );

      const statusSelect = screen.getByLabelText('Filter by school status');
      fireEvent.change(statusSelect, { target: { value: 'active' } });
      expect(handleChange).toHaveBeenCalledWith({ schoolStatus: 'active' });

      const planSelect = screen.getByLabelText('Filter by plan');
      fireEvent.change(planSelect, { target: { value: 'yearly' } });
      expect(handleChange).toHaveBeenCalledWith({ plan: 'yearly' });
    });
  });

  describe('ClientTable', () => {
    const mockSchools = [
      {
        id: 1,
        name: 'Angkor School',
        slug: 'angkor-school',
        school_key: 'PEN001',
        admin_email: 'admin@angkor.edu',
        status: 'active',
        is_active: true,
        subscription_plan: 'yearly',
        subscription_status: 'active',
        subscription_end_date: '2026-12-31',
        students_count: 320,
        teachers_count: 24,
      },
      {
        id: 2,
        name: 'ITC School',
        slug: 'itc-school',
        school_key: 'PEN002',
        admin_email: 'admin@itc.edu',
        status: 'inactive',
        is_active: false,
        subscription_plan: 'monthly',
        subscription_status: 'expiring_soon',
        subscription_end_date: '2026-09-15',
        students_count: 140,
        teachers_count: 12,
      },
    ];

    it('renders school columns and row data accurately', () => {
      render(
        <ClientTable
          schools={mockSchools}
          loading={false}
          error=""
          isFiltered={false}
          pagination={{ current_page: 1, last_page: 1, total: 2, from: 1, to: 2 }}
          onPageChange={jest.fn()}
          onClearFilters={jest.fn()}
          onRetry={jest.fn()}
          onToggleStatus={jest.fn()}
          onEditSchool={jest.fn()}
          onDeleteSchool={jest.fn()}
        />
      );

      expect(screen.getByText('Angkor School')).toBeInTheDocument();
      expect(screen.getByText('PEN001')).toBeInTheDocument();
      expect(screen.getByText('admin@angkor.edu')).toBeInTheDocument();
      expect(screen.getByText('320')).toBeInTheDocument();
      expect(screen.getByText('24')).toBeInTheDocument();

      expect(screen.getByText('ITC School')).toBeInTheDocument();
      expect(screen.getByText('PEN002')).toBeInTheDocument();
      expect(screen.getByText('admin@itc.edu')).toBeInTheDocument();
      expect(screen.getByText('140')).toBeInTheDocument();
      expect(screen.getByText('12')).toBeInTheDocument();
    });

    it('renders proper loading state with placeholders and not premature empty state', () => {
      const { container } = render(
        <ClientTable
          schools={[]}
          loading={true}
          error=""
          isFiltered={false}
          pagination={{}}
        />
      );

      expect(screen.queryByText('No clients found.')).not.toBeInTheDocument();
      expect(container.querySelectorAll('.placeholder').length).toBeGreaterThan(0);
    });

    it('renders empty state when no clients exist', () => {
      render(
        <ClientTable
          schools={[]}
          loading={false}
          error=""
          isFiltered={false}
          pagination={{ total: 0 }}
        />
      );

      expect(screen.getByText('No clients found.')).toBeInTheDocument();
    });

    it('renders filtered empty state with clear filters button', () => {
      const handleClear = jest.fn();
      render(
        <ClientTable
          schools={[]}
          loading={false}
          error=""
          isFiltered={true}
          pagination={{ total: 0 }}
          onClearFilters={handleClear}
        />
      );

      expect(screen.getByText('No clients match the selected filters.')).toBeInTheDocument();
      const clearBtn = screen.getByRole('button', { name: /clear filters/i });
      fireEvent.click(clearBtn);
      expect(handleClear).toHaveBeenCalledTimes(1);
    });

    it('renders error state with retry button', () => {
      const handleRetry = jest.fn();
      render(
        <ClientTable
          schools={[]}
          loading={false}
          error="Network error 500"
          isFiltered={false}
          pagination={{ total: 0 }}
          onRetry={handleRetry}
        />
      );

      expect(screen.getByText('Unable to load clients.')).toBeInTheDocument();
      expect(screen.getByText('Network error 500')).toBeInTheDocument();
      const retryBtn = screen.getByRole('button', { name: /try again/i });
      fireEvent.click(retryBtn);
      expect(handleRetry).toHaveBeenCalledTimes(1);
    });

    it('renders pagination and handles page change', () => {
      const handlePageChange = jest.fn();
      render(
        <ClientTable
          schools={mockSchools}
          loading={false}
          error=""
          isFiltered={false}
          pagination={{ current_page: 2, last_page: 5, total: 50, from: 11, to: 20 }}
          onPageChange={handlePageChange}
        />
      );

      expect(screen.getByText(/showing/i)).toBeInTheDocument();
      expect(screen.getByText('50')).toBeInTheDocument();

      const nextBtn = screen.getByRole('button', { name: /next/i });
      fireEvent.click(nextBtn);
      expect(handlePageChange).toHaveBeenCalledWith(3);

      const prevBtn = screen.getByRole('button', { name: /previous/i });
      fireEvent.click(prevBtn);
      expect(handlePageChange).toHaveBeenCalledWith(1);
    });
  });

  describe('StatusConfirmModal', () => {
    it('prompts deactivation confirmation for active school', () => {
      const handleConfirm = jest.fn();
      const handleClose = jest.fn();
      const activeSchool = {
        id: 10,
        name: 'Royal University',
        school_key: 'RU01',
        admin_email: 'admin@ru.edu',
        is_active: true,
        status: 'active',
      };

      render(
        <StatusConfirmModal
          isOpen={true}
          school={activeSchool}
          submitting={false}
          onConfirm={handleConfirm}
          onClose={handleClose}
        />
      );

      expect(screen.getByText('Deactivate Royal University?')).toBeInTheDocument();
      expect(screen.getByText(/account status to/i)).toBeInTheDocument();

      const deactivateBtn = screen.getByRole('button', { name: /deactivate/i });
      fireEvent.click(deactivateBtn);
      expect(handleConfirm).toHaveBeenCalledWith(activeSchool, false);
    });

    it('prompts activation confirmation for inactive school', () => {
      const handleConfirm = jest.fn();
      const handleClose = jest.fn();
      const inactiveSchool = {
        id: 11,
        name: 'Olympic Academy',
        school_key: 'OA01',
        admin_email: 'admin@oa.edu',
        is_active: false,
        status: 'inactive',
      };

      render(
        <StatusConfirmModal
          isOpen={true}
          school={inactiveSchool}
          submitting={false}
          onConfirm={handleConfirm}
          onClose={handleClose}
        />
      );

      expect(screen.getByText('Activate Olympic Academy?')).toBeInTheDocument();

      const activateBtn = screen.getByRole('button', { name: /activate/i });
      fireEvent.click(activateBtn);
      expect(handleConfirm).toHaveBeenCalledWith(inactiveSchool, true);
    });
  });

  describe('CreateSchoolModal', () => {
    it('renders with school icon, title, subtitle, and input fields', () => {
      const handleClose = jest.fn();
      const { container } = render(
        <CreateSchoolModal isOpen={true} onClose={handleClose} onSuccess={jest.fn()} />
      );

      expect(screen.getByText('Create New School')).toBeInTheDocument();
      expect(
        screen.getByText('Register a new school client and assign its administrator.')
      ).toBeInTheDocument();
      expect(screen.getByPlaceholderText('e.g. Angkor International School')).toBeInTheDocument();
      expect(screen.getByPlaceholderText('admin@school.edu')).toBeInTheDocument();
      expect(screen.getByPlaceholderText('Minimum 8 characters')).toBeInTheDocument();
      expect(screen.getByPlaceholderText('e.g. SCH-00123')).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /create school/i })).toBeInTheDocument();

      // Check header icon badge
      const iconBadge = container.querySelector('.client-modal-icon-badge');
      expect(iconBadge).toBeInTheDocument();
    });

    it('toggles password visibility', () => {
      render(
        <CreateSchoolModal isOpen={true} onClose={jest.fn()} onSuccess={jest.fn()} />
      );

      const passwordInput = screen.getByPlaceholderText('Minimum 8 characters');
      expect(passwordInput).toHaveAttribute('type', 'password');

      const toggleBtn = screen.getByRole('button', { name: /show password/i });
      fireEvent.click(toggleBtn);
      expect(passwordInput).toHaveAttribute('type', 'text');

      const hideBtn = screen.getByRole('button', { name: /hide password/i });
      fireEvent.click(hideBtn);
      expect(passwordInput).toHaveAttribute('type', 'password');
    });
  });
});

