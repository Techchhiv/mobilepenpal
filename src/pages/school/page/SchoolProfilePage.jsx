import React from "react";
import SchoolLayout from "../masterLayout/SchoolLayout";
import Breadcrumb from "../../../components/Breadcrumb";
import ProfileSettingsView from "../../../components/profile/ProfileSettingsView";

const SchoolProfilePage = () => {
  return (
    <SchoolLayout>
      <Breadcrumb title="Profile & Settings" />
      <ProfileSettingsView />
    </SchoolLayout>
  );
};

export default SchoolProfilePage;
