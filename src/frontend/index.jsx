import React from "react";
import MasterLayout from "./masterLayout/MasterLayout";
import HomePage from "./page/HomePage";
import ProductDetail from "./page/ProductDetail";

const Index = () => {
  return (
    <>
      {/* MasterLayout */}
      <MasterLayout>
        
      <HomePage />

      </MasterLayout>
    </>
  );
};

export default Index;
