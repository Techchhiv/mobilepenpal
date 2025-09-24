import React, { useEffect, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, NavLink, useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { hasRole, hasPermission } from "../utils/permissions";
import ThemeToggleButton from "../helper/ThemeToggleButton";
import API from "../helper/api";
import penLogo from "../assets/images/pen_logo.png";

const MasterLayout = ({ children }) => {
  const { user, loading, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const [sidebarActive, setSidebarActive] = useState(false);
  const [mobileMenu, setMobileMenu] = useState(false);
  const [openDropdownKey, setOpenDropdownKey] = useState(null);

  // Use show... variables for each menu item based on roles and permissions
  const showManageClients = hasRole(user?.roles, "manage_clients Admin") || hasPermission(user?.permissions, "menu.manage_clients");

  const showPayments = hasRole(user?.roles, "Payment Admin") || hasPermission(user?.permissions, "menu.payments");
  const showAnalytics = hasPermission(user?.permissions, "menu.analytics");
  const showReports = hasPermission(user?.permissions, "menu.reports");
  const showManageUsers = hasRole(user?.roles, "admin") || hasPermission(user?.permissions, "users.manage");
  const showRoles = hasRole(user?.roles, "admin") || hasPermission(user?.permissions, "roles.manage");
  const showPermissions = hasRole(user?.roles, "admin") || hasPermission(user?.permissions, "permissions.manage");

  useEffect(() => {
    const p = location.pathname;
    if (p.startsWith("/admin/users") || p.startsWith("/admin/roles") || p.startsWith("/admin/permissions")) {
      setOpenDropdownKey("access");
    } else if (p.startsWith("/company") || p.startsWith("/notification") || p.startsWith("/notification-alert") || p.startsWith("/theme") || p.startsWith("/currencies") || p.startsWith("/language") || p.startsWith("/payment-gateway")) {
      setOpenDropdownKey("settings");
    } else {
      setOpenDropdownKey(null);
    }
  }, [location.pathname]);

  const handleLogout = async () => {
    logout();
  };

  if (loading) return <div>Loading...</div>;

  return (
    <section className={mobileMenu ? "overlay active" : "overlay"}>
      {/* Sidebar */}
      <aside className={sidebarActive ? "sidebar active" : "sidebar"}>
        <button onClick={() => setMobileMenu(false)} type="button" className="sidebar-close-btn">
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

            {/* Manage Clients */}
            {showManageClients && (
              <li>
                <NavLink to="/admin/schools">
                  <Icon icon="mdi:account-multiple" className="menu-icon" />
                  <span>Manage Clients</span>
                </NavLink>
              </li>
            )}

            {/* Payments */}
            {showPayments && (
              <li>
                <NavLink to="/admin/payments">
                  <Icon icon="mdi:credit-card" className="menu-icon" />
                  <span>Payments</span>
                </NavLink>
              </li>
            )}

            {/* Analytics */}
            {showAnalytics && (
              <li>
                <NavLink to="/admin/analytics">
                  <Icon icon="mdi:chart-line" className="menu-icon" />
                  <span>Analytics</span>
                </NavLink>
              </li>
            )}

            {/* Reports */}
            {showReports && (
              <li>
                <NavLink to="/admin/reports">
                  <Icon icon="mdi:file-chart" className="menu-icon" />
                  <span>Manage Report</span>
                </NavLink>
              </li>
            )}

            {/* Manage Users */}
            {showManageUsers && (
              <li className={`dropdown ${openDropdownKey === "access" ? "open" : ""}`}>
                <a
                  href="#access"
                  className={`menu-trigger ${openDropdownKey === "access" ? "active-page" : ""}`}
                  onClick={(e) => {
                    e.preventDefault();
                    setOpenDropdownKey((prev) => (prev === "access" ? null : "access"));
                  }}
                >
                  <Icon icon="flowbite:users-group-outline" className="menu-icon" />
                  <span>Manage Users</span>
                  <Icon icon={openDropdownKey === "access" ? "mdi:chevron-up" : "mdi:chevron-down"} className="caret ms-auto" />
                </a>
                <ul className="sidebar-submenu" style={{ maxHeight: openDropdownKey === "access" ? "600px" : "0px", overflow: "hidden", transition: "max-height .25s ease" }}>
                  {showManageUsers && (
                    <li>
                      <NavLink to="/admin/users" className={({ isActive }) => (isActive ? "active-page" : "")}>
                        <i className="ri-circle-fill circle-icon text-primary-600 w-auto" />
                        Users
                      </NavLink>
                    </li>
                  )}
                  {showRoles && (
                    <li>
                      <NavLink to="/admin/roles" className={({ isActive }) => (isActive ? "active-page" : "")}>
                        <i className="ri-circle-fill circle-icon text-warning-main w-auto" />
                        Roles
                      </NavLink>
                    </li>
                  )}
                  {showPermissions && (
                    <li>
                      <NavLink to="/admin/permissions" className={({ isActive }) => (isActive ? "active-page" : "")}>
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
                <button type="button" className="sidebar-toggle" onClick={() => setSidebarActive((s) => !s)}>
                  {sidebarActive ? (
                    <Icon icon="iconoir:arrow-right" className="icon text-2xl non-active" />
                  ) : (
                    <Icon icon="heroicons:bars-3-solid" className="icon text-2xl non-active" />
                  )}
                </button>
                <button onClick={() => setMobileMenu(true)} type="button" className="sidebar-mobile-toggle">
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
                  <button className="d-flex justify-content-center align-items-center rounded-circle" type="button" data-bs-toggle="dropdown">
                    <img src={penLogo} alt="user" className="w-40-px h-40-px object-fit-cover rounded-circle" />
                  </button>
                  <div className="dropdown-menu to-top dropdown-menu-sm">
                    <div className="py-12 px-16 radius-8 bg-primary-50 mb-16 d-flex align-items-center justify-content-between gap-2">
                      <div>
                        <h6 className="text-lg text-primary-light fw-semibold mb-2">{user?.name ?? "User"}</h6>
                        <span className="text-secondary-light fw-medium text-sm">{user?.email ?? ""}</span>
                      </div>
                      <button type="button" className="hover-text-danger">
                        <Icon icon="radix-icons:cross-1" className="icon text-xl" />
                      </button>
                    </div>
                    <ul className="to-top-list">
                      <li>
                        <Link className="dropdown-item text-black px-0 py-8 hover-bg-transparent hover-text-primary d-flex align-items-center gap-3" to="/view-profile">
                          <Icon icon="solar:user-linear" className="icon text-xl" />
                          My Profile
                        </Link>
                      </li>
                      <li>
                        <Link className="dropdown-item text-black px-0 py-8 hover-bg-transparent hover-text-primary d-flex align-items-center gap-3" to="/company">
                          <Icon icon="icon-park-outline:setting-two" className="icon text-xl" />
                          Setting
                        </Link>
                      </li>
                      <li>
                        <button className="dropdown-item text-black px-0 py-8 hover-bg-transparent hover-text-danger d-flex align-items-center gap-3 w-100 text-start" onClick={handleLogout} type="button">
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

        {/* Content */}
        <div className="dashboard-main-body">{children}</div>

        {/* Footer */}
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
