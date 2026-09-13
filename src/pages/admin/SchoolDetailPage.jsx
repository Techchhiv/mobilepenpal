import { useParams } from 'react-router-dom';
import MasterLayout from '../../masterLayout/MasterLayout';
import SchoolDetailLayer from '../../components/schoolReport/SchoolDetailLayer';
import { useSchoolDetail } from '../../hook/useSchoolDetail';
import '../../assets/css/adminReport.css';

export default function SchoolDetailPage() {
  const { id } = useParams();
  const { school, loading, error, refetch } = useSchoolDetail(id);

  return (
    <MasterLayout>
      <div className="school-detail-page-wrapper">
        <SchoolDetailLayer school={school} loading={loading} error={error} onRetry={refetch} />
      </div>
    </MasterLayout>
  );
}
