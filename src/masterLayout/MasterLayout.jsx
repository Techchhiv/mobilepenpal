// src/masterLayout/MasterLayout.jsx
import React, { useEffect, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, NavLink, useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import ThemeToggleButton from "../helper/ThemeToggleButton";
import API from "../helper/api";
import penLogo from "../assets/images/pen_logo.png";

const MasterLayout = ({ children }) => {
  const { user, loading, logout, hasRole, hasPermission, isSuperAdmin } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const [sidebarActive, setSidebarActive] = useState(false);
  const [mobileMenu, setMobileMenu] = useState(false);
  const [openDropdownKey, setOpenDropdownKey] = useState(null);

  const showManageClients = isSuperAdmin || hasRole("manage_clients Admin") || hasPermission("menu.manage_clients");
  const showPayments = isSuperAdmin || hasRole("Payment Admin") || hasPermission("menu.payments");
  const showAnalytics = isSuperAdmin || hasPermission("menu.analytics");
  const showReports = isSuperAdmin || hasPermission("menu.reports");
  const showManageUsers = isSuperAdmin || hasRole("admin") || hasPermission("users.manage");
  const showRoles = isSuperAdmin || hasRole("admin") || hasPermission("roles.manage");
  const showPermissions = isSuperAdmin || hasRole("admin") || hasPermission("permissions.manage");

  useEffect(() => {
    const p = location.pathname;
    if (p.startsWith("/admin/users") || p.startsWith("/admin/roles") || p.startsWith("/admin/permissions")) {
      setOpenDropdownKey("access");
    } else {
      setOpenDropdownKey(null);
    }
  }, [location.pathname]);

  if (loading) return <div>Loading...</div>;

  const handleLogout = async () => logout();


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
          <Link to="/admin" className="sidebar-logo">
            <h6>Khmer Penpal</h6>
          </Link>
        </div>

        <div className="sidebar-menu-area">
          <ul className="sidebar-menu" id="sidebar-menu">
            <li className="sidebar-menu-group-title">Application</li>

            {showManageClients && <li><NavLink to="/admin/schools"><Icon icon="mdi:account-multiple" /> Manage Clients</NavLink></li>}
            {showPayments && <li><NavLink to="/admin/payments"><Icon icon="mdi:credit-card" /> Payments</NavLink></li>}
            {showAnalytics && <li><NavLink to="/admin/analytics"><Icon icon="mdi:chart-line" /> Analytics</NavLink></li>}
            {showReports && <li><NavLink to="/admin/reports"><Icon icon="mdi:file-chart" /> Reports</NavLink></li>}

            {showManageUsers && (
              <li className={`dropdown ${openDropdownKey === "access" ? "open" : ""}`}>
                <a href="#access" onClick={e => { e.preventDefault(); setOpenDropdownKey(prev => prev === "access" ? null : "access"); }}>
                  <Icon icon="flowbite:users-group-outline" /> Manage Users
                  {/* <Icon icon={openDropdownKey === "access" ? "mdi:chevron-up" : "mdi:chevron-down"} /> */}
                </a>
                <ul style={{ maxHeight: openDropdownKey === "access" ? "600px" : "0px", overflow: "hidden", transition: "max-height .25s ease" }}>
                  {showManageUsers && <li><NavLink to="/admin/users">Users</NavLink></li>}
                  {showRoles && <li><NavLink to="/admin/roles">Roles</NavLink></li>}
                  {showPermissions && <li><NavLink to="/admin/permissions">Permissions</NavLink></li>}
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
                  {sidebarActive ? (
                    <Icon icon="iconoir:arrow-right" className="icon text-2xl non-active" />
                  ) : (
                    <Icon icon="heroicons:bars-3-solid" className="icon text-2xl non-active" />
                  )}
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
                          className="dropdown-item text-black px-0 py-8 hover-bg-transparent hover-text-primary d-flex align-items-center gap-3"
                          to="/view-profile"
                        >
                          <Icon icon="solar:user-linear" className="icon text-xl" />
                          My Profile
                        </Link>
                      </li>
                      <li>
                        <Link
                          className="dropdown-item text-black px-0 py-8 hover-bg-transparent hover-text-primary d-flex align-items-center gap-3"
                          to="/company"
                        >
                          <Icon icon="icon-park-outline:setting-two" className="icon text-xl" />
                          Setting
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
              </div>
            </div>
          </div>
        </div>

        <div className="dashboard-main-body">{children}</div>

        <footer className="d-footer">
          <div className="row align-items-center justify-content-between">
            <div className="col-auto">
              <p className="mb-0">© {new Date().getFullYear()} KhmerPenpal. All Rights Reserved.</p>
            </div>
            <div className="col-auto">
              <p className="mb-0">Made by <span className="text-primary-600">KhmerPenpal1</span></p>
            </div>
          </div>
        </footer>
      </main>
    </section>
  );
};

export default MasterLayout;
