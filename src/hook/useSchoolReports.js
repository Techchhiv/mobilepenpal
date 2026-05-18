import { useEffect, useState } from 'react';
import API from '../helper/api';

const PAGE_SIZE = 10;
const EMPTY_SUMMARY = {
  totalSchools: 0,
  activeSchools: 0,
  totalStudents: 0,
  totalTeachers: 0,
};

function normalizeSubscription(subscription) {
  if (!subscription) return null;

  return {
    id: subscription.id,
    plan: subscription.plan ?? '',
    status: subscription.status ?? 'none',
    startDate: subscription.start_date ?? null,
    endDate: subscription.end_date ?? null,
    amount: subscription.amount ?? null,
    active: Boolean(subscription.active),
    createdAt: subscription.created_at ?? null,
    updatedAt: subscription.updated_at ?? null,
  };
}

function normalizeSchoolListItem(school = {}) {
  const adminName = school.admin?.name ?? '';
  const adminEmail = school.admin?.email ?? school.admin_email ?? '';
  const totalStudents = Number(school.students_count ?? 0);
  const activeStudents = Number(school.active_students_count ?? 0);
  const totalTeachers = Number(school.teachers_count ?? 0);
  const activeTeachers = Number(school.active_teachers_count ?? 0);

  return {
    schoolId: String(school.id ?? ''),
    schoolName: school.name ?? 'Unknown school',
    schoolCode: school.school_key ?? '',
    schoolSlug: school.slug ?? '',
    schoolEmail: adminEmail,
    adminContactName: adminName,
    adminContactEmail: adminEmail,
    status: school.status ?? (school.is_active ? 'active' : 'inactive'),
    totalStudents,
    activeStudents,
    inactiveStudents: Number(
      school.inactive_students_count ?? Math.max(totalStudents - activeStudents, 0)
    ),
    totalTeachers,
    activeTeachers,
    inactiveTeachers: Number(
      school.inactive_teachers_count ?? Math.max(totalTeachers - activeTeachers, 0)
    ),
    subscriptionPlan: school.subscription_plan ?? '',
    subscriptionStatus: school.subscription_status ?? 'none',
    subscriptionStartDate: school.subscription_start_date ?? null,
    subscriptionEndDate: school.subscription_end_date ?? null,
    hasActiveSubscription: Boolean(school.has_active_subscription),
    createdAt: school.created_at ?? null,
    lastUpdatedAt: school.updated_at ?? null,
  };
}

function normalizeSchoolDetail(school = {}) {
  const adminName = school.admin?.name ?? '';
  const adminEmail = school.admin?.email ?? school.admin_email ?? '';
  const students = school.students ?? {};
  const teachers = school.teachers ?? {};
  const currentSubscription = normalizeSubscription(school.current_subscription);
  const latestSubscription = normalizeSubscription(school.latest_subscription);

  return {
    schoolId: String(school.id ?? ''),
    schoolName: school.name ?? 'Unknown school',
    schoolCode: school.school_key ?? '',
    schoolSlug: school.slug ?? '',
    schoolEmail: adminEmail,
    adminContactName: adminName,
    adminContactEmail: adminEmail,
    status: school.status ?? (school.is_active ? 'active' : 'inactive'),
    totalStudents: Number(students.total ?? 0),
    activeStudents: Number(students.active ?? 0),
    inactiveStudents: Number(students.inactive ?? 0),
    maleStudents: Number(students.male ?? 0),
    femaleStudents: Number(students.female ?? 0),
    totalTeachers: Number(teachers.total ?? 0),
    activeTeachers: Number(teachers.active ?? 0),
    inactiveTeachers: Number(teachers.inactive ?? 0),
    totalUsers: Number(school.users_count ?? 0),
    totalBranches: Number(school.branches_count ?? 0),
    totalSubscriptions: Number(school.subscriptions_count ?? 0),
    subscriptionPlan: currentSubscription?.plan ?? latestSubscription?.plan ?? '',
    subscriptionStatus:
      school.subscription_status ??
      currentSubscription?.status ??
      latestSubscription?.status ??
      'none',
    subscriptionStartDate:
      currentSubscription?.startDate ?? latestSubscription?.startDate ?? null,
    subscriptionEndDate:
      currentSubscription?.endDate ?? latestSubscription?.endDate ?? null,
    currentSubscription,
    latestSubscription,
    subscriptionHistory: Array.isArray(school.subscription_history)
      ? school.subscription_history.map(normalizeSubscription)
      : [],
    createdAt: school.created_at ?? null,
    lastUpdatedAt: school.updated_at ?? null,
  };
}

function normalizeSummary(summary = {}) {
  return {
    totalSchools: Number(summary.total_schools ?? 0),
    activeSchools: Number(summary.total_active_schools ?? summary.active_schools ?? 0),
    totalStudents: Number(summary.total_students ?? 0),
    totalTeachers: Number(summary.total_teachers ?? 0),
  };
}

function buildParams(filters) {
  return {
    search: filters.search || undefined,
    school_status: filters.schoolStatus || undefined,
    subscription_status: filters.subscriptionStatus || undefined,
    plan: filters.plan || undefined,
    page: filters.page || 1,
    per_page: PAGE_SIZE,
  };
}

export function useSchoolReports(filters, selectedSchoolId) {
  const {
    search = '',
    schoolStatus = '',
    subscriptionStatus = '',
    plan = '',
    page = 1,
  } = filters;
  const [schools, setSchools] = useState([]);
  const [summaryStats, setSummaryStats] = useState(EMPTY_SUMMARY);
  const [totalPages, setTotalPages] = useState(0);
  const [totalItems, setTotalItems] = useState(0);
  const [loading, setLoading] = useState(true);
  const [selectedSchool, setSelectedSchool] = useState(null);
  const [selectedSchoolLoading, setSelectedSchoolLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    let cancelled = false;

    async function loadSchools() {
      setLoading(true);
      setError('');

      try {
        const response = await API.get('/admin/reports/schools', {
          params: buildParams({
            search,
            schoolStatus,
            subscriptionStatus,
            plan,
            page,
          }),
        });

        if (cancelled) return;

        const payload = response.data?.data ?? {};
        setSchools(
          Array.isArray(payload.schools)
            ? payload.schools.map(normalizeSchoolListItem)
            : []
        );
        setSummaryStats(normalizeSummary(payload.summary));
        setTotalPages(Number(payload.pagination?.last_page ?? 0));
        setTotalItems(Number(payload.pagination?.total ?? 0));
      } catch (fetchError) {
        if (cancelled) return;

        setSchools([]);
        setSummaryStats(EMPTY_SUMMARY);
        setTotalPages(0);
        setTotalItems(0);
        setError(
          fetchError.response?.data?.message ||
          'Unable to load school reports right now.'
        );
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    loadSchools();

    return () => {
      cancelled = true;
    };
  }, [
    search,
    schoolStatus,
    subscriptionStatus,
    plan,
    page,
  ]);

  useEffect(() => {
    let cancelled = false;

    if (!selectedSchoolId) {
      setSelectedSchool(null);
      setSelectedSchoolLoading(false);
      return () => {
        cancelled = true;
      };
    }

    const fallbackSchool =
      schools.find((school) => school.schoolId === String(selectedSchoolId)) ?? null;

    setSelectedSchool(fallbackSchool);

    async function loadSchoolDetail() {
      setSelectedSchoolLoading(true);

      try {
        const response = await API.get(`/admin/reports/schools/${selectedSchoolId}`);

        if (cancelled) return;

        const detail = response.data?.data?.school;
        setSelectedSchool(detail ? normalizeSchoolDetail(detail) : fallbackSchool);
      } catch {
        if (!cancelled) {
          setSelectedSchool(fallbackSchool);
        }
      } finally {
        if (!cancelled) {
          setSelectedSchoolLoading(false);
        }
      }
    }

    loadSchoolDetail();

    return () => {
      cancelled = true;
    };
  }, [selectedSchoolId, schools]);

  return {
    filteredList: schools,
    pagedList: schools,
    selectedSchool,
    summaryStats,
    totalPages,
    totalItems,
    loading,
    selectedSchoolLoading,
    error,
  };
}

export default useSchoolReports;
