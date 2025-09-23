import React from "react";
import "../assets/css/LogoLoader.css"
import penLogo from '../assets/images/pen_logo.png'
const LogoLoader = () => {
  return (
    <div className="logo-loader">
      <img
        src={penLogo}
        alt="Loading..."
        className="rotating-logo"
      />
      <p>Loading...</p> 
    </div>
  );
};

export default LogoLoader;
