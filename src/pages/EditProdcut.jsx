import React from "react";
import MasterLayout from "../masterLayout/MasterLayout";
import Breadcrumb from "../components/Breadcrumb";
import EditProductLayer from "../components/editProductLayer";
import { useParams } from "react-router-dom";
const EditProduct = () => {
       const { id } = useParams();
      //  console.log(id);
  return (
    <>
      {/* MasterLayout */}
      <MasterLayout>
        {/* Breadcrumb */}
        <Breadcrumb title='Edit Product' />

        {/* AddBlogLayer */}
        <EditProductLayer />
      </MasterLayout>
    </>
  );
};

export default EditProduct;
