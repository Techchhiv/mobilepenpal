import React from "react";
import MasterLayout from "../masterLayout/MasterLayout";
import Breadcrumb from "../components/Breadcrumb";
import AddCategory from "../components/AddCategory";
const Category = () => {
  return (
    <>
      {/* MasterLayout */}
      <MasterLayout>
        {/* Breadcrumb */}
        <Breadcrumb title='Category' />

        {/* AddCategory */}
        <AddCategory />
      </MasterLayout>
    </>
  );
};

export default Category;
