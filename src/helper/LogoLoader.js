import React from "react";
import "../assets/css/LogoLoader.css"

const LogoLoader = () => {
  return (
    <div className="logo-loader">
      <img
        src="/assets/images/pen_logo.png"
        alt="Loading..."
        className="rotating-logo"
      />
      <p>Loading...</p> 
    </div>
  );
};

export default LogoLoader;
