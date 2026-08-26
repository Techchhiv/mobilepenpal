import { useParams } from 'react-router-dom';
import MasterLayout from '../../masterLayout/MasterLayout';
import SchoolDetailLayer from '../../components/schoolReport/SchoolDetailLayer';
import { useSchoolDetail } from '../../hook/useSchoolDetail';

export default function SchoolDetailPage() {
  const { id } = useParams();
  const { school, loading, error } = useSchoolDetail(id);

  return (
    <MasterLayout>
      <div className="school-detail-page-wrapper">
        <SchoolDetailLayer school={school} loading={loading} error={error} />
      </div>
    </MasterLayout>
  );
}
