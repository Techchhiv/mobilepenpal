import React from "react";
import MasterLayout from "../../masterLayout/MasterLayout";
import Breadcrumb from "../../components/Breadcrumb";
import ProfileSettingsView from "../../components/profile/ProfileSettingsView";

const AdminProfilePage = () => {
  return (
    <MasterLayout>
      <Breadcrumb title="Profile & Settings" />
      <ProfileSettingsView />
    </MasterLayout>
  );
};

export default AdminProfilePage;
