// src/pages/school/layout/SchoolLayout.jsx
import React, { useEffect, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, NavLink, useNavigate, useLocation } from "react-router-dom";
import ThemeToggleButton from "../../../helper/ThemeToggleButton";
import API from "../../../helper/api";
import { useAuth } from "../../../context/AuthContext";
import penLogo from "../../../assets/images/pen_logo.png";

const SchoolLayout = ({ children }) => {
  const { user, loading, logout, hasPermission,isSchoolAdmin } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const [sidebarActive, setSidebarActive] = useState(false);
  const [mobileMenu, setMobileMenu] = useState(false);
  const [openDropdownKey, setOpenDropdownKey] = useState(null);

  const showManageUsers = hasPermission("users.manage");
  const showRoles = hasPermission("roles.manage");
  const showPermissions = hasPermission("permissions.manage");
  const showTeacher = hasPermission("teachers.view");


  // Open dropdown based on route
  useEffect(() => {
    const p = location.pathname;
    if (
      p.startsWith("/school/users") ||
      p.startsWith("/school/roles") ||
      p.startsWith("/school/permissions")
    ) {
      setOpenDropdownKey("access");
    } else if (
      p.startsWith("/school/teachers") ||
      p.startsWith("/school/students") ||
      p.startsWith("/school/performance")
    ) {
      setOpenDropdownKey("management");
    } else {
      setOpenDropdownKey(null);
    }
  }, [location.pathname]);

  const handleLogout = async () => {
    try {
      await API.post("/logout");
    } catch (err) {
      console.error("Logout error:", err);
    }
    logout();
    navigate("/sign-in-school", { replace: true });
  };

  if (loading) return <div>Loading...</div>;

  return (
    <section className={mobileMenu ? "overlay active" : "overlay"}>
      {/* Sidebar */}
      <aside className={sidebarActive ? "sidebar active" : "sidebar"}>
        <button
          onClick={() => setMobileMenu(false)}
          type="button"
          className="sidebar-close-btn"
        >
          <Icon icon="radix-icons:cross-2" />
        </button>

        <div>
          <Link to="/school" className="sidebar-logo">
            <h6> {user?.name ?? "User"}</h6>
          </Link>
        </div>

        <div className="sidebar-menu-area">
          <ul className="sidebar-menu">
            <li className="sidebar-menu-group-title">School Dashboard</li>

           {showTeacher && (
             <li>
              <NavLink
                to="/school/teachers"
                className={({ isActive }) => (isActive ? "active-page" : "")}
              >
                <Icon icon="mdi:teach" className="menu-icon" />
                <span>Manage Teachers</span>
              </NavLink>
            </li>
           )}

            <li>
              <NavLink
                to="/school/students"
                className={({ isActive }) => (isActive ? "active-page" : "")}
              >
                <Icon icon="mdi:account-school" className="menu-icon" />
                <span>Manage Students</span>
              </NavLink>
            </li>

            <li>
              <NavLink
                to="/school/performance"
                className={({ isActive }) => (isActive ? "active-page" : "")}
              >
                <Icon icon="mdi:chart-bar" className="menu-icon" />
                <span>Analyze Performance</span>
              </NavLink>
            </li>

            {/* Manage Users / Roles / Permissions */}
            {(showManageUsers || showRoles || showPermissions) && (
              <li className={`dropdown ${openDropdownKey === "access" ? "open" : ""}`}>
                <a
                  href="#access"
                  className={`menu-trigger ${openDropdownKey === "access" ? "active-page" : ""
                    }`}
                  onClick={(e) => {
                    e.preventDefault();
                    setOpenDropdownKey((prev) => (prev === "access" ? null : "access"));
                  }}
                >
                  <Icon icon="flowbite:users-group-outline" className="menu-icon" />
                  <span>Manage Users</span>
                  <Icon
                    icon={openDropdownKey === "access" ? "mdi:chevron-up" : "mdi:chevron-down"}
                    className="caret ms-auto"
                  />
                </a>

                <ul
                  className="sidebar-submenu"
                  style={{
                    maxHeight: openDropdownKey === "access" ? "600px" : "0px",
                    overflow: "hidden",
                    transition: "max-height .25s ease",
                  }}
                >
                  {showManageUsers && (
                    <li>
                      <NavLink
                        to="/school/users"
                        className={({ isActive }) => (isActive ? "active-page" : "")}
                      >
                        <i className="ri-circle-fill circle-icon text-primary-600 w-auto" />
                        Users
                      </NavLink>
                    </li>
                  )}
                  {showRoles && (
                    <li>
                      <NavLink
                        to="/school/roles"
                        className={({ isActive }) => (isActive ? "active-page" : "")}
                      >
                        <i className="ri-circle-fill circle-icon text-warning-main w-auto" />
                        Roles
                      </NavLink>
                    </li>
                  )}
                  {showPermissions && (
                    <li>
                      <NavLink
                        to="/school/permissions"
                        className={({ isActive }) => (isActive ? "active-page" : "")}
                      >
                        <i className="ri-circle-fill circle-icon text-info-main w-auto" />
                        Permissions
                      </NavLink>
                    </li>
                  )}
                </ul>
              </li>
            )}
          </ul>
        </div>
      </aside>

      {/* Main Content */}
      <main className={sidebarActive ? "dashboard-main active" : "dashboard-main"}>
        <div className="navbar-header">
          <div className="row align-items-center justify-content-between">
            <div className="col-auto">
              <div className="d-flex flex-wrap align-items-center gap-4">
                <button
                  type="button"
                  className="sidebar-toggle"
                  onClick={() => setSidebarActive((s) => !s)}
                >
                  <Icon
                    icon={sidebarActive ? "iconoir:arrow-right" : "heroicons:bars-3-solid"}
                    className="icon text-2xl non-active"
                  />
                </button>
                <button
                  onClick={() => setMobileMenu(true)}
                  type="button"
                  className="sidebar-mobile-toggle"
                >
                  <Icon icon="heroicons:bars-3-solid" className="icon" />
                </button>
                <form className="navbar-search">
                  <input type="text" name="search" placeholder="Search" />
                  <Icon icon="ion:search-outline" className="icon" />
                </form>
              </div>
            </div>

            <div className="col-auto">
              <div className="d-flex flex-wrap align-items-center gap-3">
                <ThemeToggleButton />

                {/* Profile dropdown */}
                <div className="dropdown">
                  <button
                    className="d-flex justify-content-center align-items-center rounded-circle"
                    type="button"
                    data-bs-toggle="dropdown"
                  >
                    <img
                      src={penLogo}
                      alt="user"
                      className="w-40-px h-40-px object-fit-cover rounded-circle"
                    />
                  </button>

                  <div className="dropdown-menu to-top dropdown-menu-sm">
                    <div className="py-12 px-16 radius-8 bg-primary-50 mb-16 d-flex align-items-center justify-content-between gap-2">
                      <div>
                        <h6 className="text-lg text-primary-light fw-semibold mb-2">
                          {user?.name ?? "User"}
                        </h6>
                        <span className="text-secondary-light fw-medium text-sm">
                          {user?.email ?? ""}
                        </span>
                      </div>
                      <button type="button" className="hover-text-danger">
                        <Icon icon="radix-icons:cross-1" className="icon text-xl" />
                      </button>
                    </div>

                    <ul className="to-top-list">
                      <li>
                        <Link
                          to="/school/profile"
                          className="dropdown-item text-black px-0 py-8 hover-bg-transparent hover-text-primary d-flex align-items-center gap-3"
                        >
                          <Icon icon="solar:user-linear" className="icon text-xl" />
                          My Profile
                        </Link>
                      </li>
                      <li>
                        <button
                          className="dropdown-item text-black px-0 py-8 hover-bg-transparent hover-text-danger d-flex align-items-center gap-3 w-100 text-start"
                          onClick={handleLogout}
                          type="button"
                        >
                          <Icon icon="lucide:power" className="icon text-xl" />
                          Log Out
                        </button>
                      </li>
                    </ul>
                  </div>
                </div>
                {/* Profile dropdown end */}
              </div>
            </div>
          </div>
        </div>

        {/* Children Content */}
        <div className="dashboard-main-body">{children}</div>

        {/* Footer */}
        <footer className="d-footer">
          <div className="row align-items-center justify-content-between">
            <div className="col-auto">
              <p className="mb-0">© {new Date().getFullYear()} KhmerPenpal. All Rights Reserved.</p>
            </div>
            <div className="col-auto">
              <p className="mb-0">Made by <span className="text-primary-600">KhmerPenpal</span></p>
            </div>
          </div>
        </footer>
      </main>
    </section>
  );
};

export default SchoolLayout;
