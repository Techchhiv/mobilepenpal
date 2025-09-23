import React from "react";
import MasterLayout from "../masterLayout/MasterLayout";
import Breadcrumb from "../components/Breadcrumb";
import AddBlogLayer from "../components/AddBlogLayer";

const AddBlogPage = () => {
  return (
    <>
      {/* MasterLayout */}
      <MasterLayout>
        {/* Breadcrumb */}
        <Breadcrumb title='Add Product' />

        {/* AddBlogLayer */}
        <AddBlogLayer />
      </MasterLayout>
    </>
  );
};

export default AddBlogPage;
