import { useEffect, useState } from 'react';
import API from '../helper/api';

function normalizeSubscription(subscription) {
  if (!subscription) return null;
  return {
    id: subscription.id,
    plan: subscription.plan ?? '',
    amount: subscription.amount !== null && subscription.amount !== undefined
      ? Number(subscription.amount)
      : null,
    status: subscription.status ?? 'none',
    active: Boolean(subscription.active),
    startDate: subscription.start_date ?? null,
    endDate: subscription.end_date ?? null,
    createdAt: subscription.created_at ?? null,
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
    schoolName: school.name ?? 'Unknown School',
    schoolCode: school.school_key ?? '',
    schoolSlug: school.slug ?? '',
    schoolEmail: adminEmail,
    adminName,
    adminEmail,
    status: school.status ?? (school.is_active ? 'active' : 'inactive'),
    // Students
    totalStudents: Number(students.total ?? 0),
    activeStudents: Number(students.active ?? 0),
    inactiveStudents: Number(students.inactive ?? 0),
    maleStudents: Number(students.male ?? 0),
    femaleStudents: Number(students.female ?? 0),
    // Teachers
    totalTeachers: Number(teachers.total ?? 0),
    activeTeachers: Number(teachers.active ?? 0),
    inactiveTeachers: Number(teachers.inactive ?? 0),
    // Counts
    totalBranches: Number(school.branches_count ?? 0),
    totalUsers: Number(school.users_count ?? 0),
    totalSubscriptions: Number(school.subscriptions_count ?? 0),
    // Subscription
    currentSubscription,
    latestSubscription,
    subscriptionHistory: Array.isArray(school.subscription_history)
      ? school.subscription_history.map(normalizeSubscription)
      : [],
    // Dates
    createdAt: school.created_at ?? null,
    updatedAt: school.updated_at ?? null,
  };
}

export function useSchoolDetail(schoolId) {
  const [school, setSchool] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [refreshIndex, setRefreshIndex] = useState(0);

  const refetch = () => setRefreshIndex(prev => prev + 1);

  useEffect(() => {
    if (!schoolId) {
      setSchool(null);
      setLoading(false);
      return;
    }

    let cancelled = false;
    setLoading(true);
    setError('');

    async function load() {
      try {
        const response = await API.get(`/admin/reports/schools/${schoolId}`);
        if (cancelled) return;
        const detail = response.data?.data?.school;
        setSchool(detail ? normalizeSchoolDetail(detail) : null);
      } catch (err) {
        if (!cancelled) {
          setError(
            err.response?.data?.message ||
            'Unable to load school details right now.'
          );
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    load();

    return () => {
      cancelled = true;
    };
  }, [schoolId, refreshIndex]);

  return { school, loading, error, refetch };
}

export default useSchoolDetail;
