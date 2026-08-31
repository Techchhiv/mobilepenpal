import React, { useEffect, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, NavLink, useLocation } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import ThemeToggleButton from "../helper/ThemeToggleButton";
import penLogo from "../assets/images/pen_logo.png";
import "../assets/css/Layout.css";

const MasterLayout = ({ children }) => {
  const { user, loading, logout, hasPermission, isSuperAdmin } = useAuth();
  const location = useLocation();

  const [sidebarActive, setSidebarActive] = useState(false);
  const [mobileMenu, setMobileMenu] = useState(false);
  const [openDropdownKey, setOpenDropdownKey] = useState(null);

  // ── Permission booleans aligned with backend RBAC ──────────────────────────
  const showManageClients    = isSuperAdmin || hasPermission("menu.manage_clients");
  const showStudents         = isSuperAdmin || hasPermission("student.view") || hasPermission("children.view");
  // Reports: backend requires menu.reports OR reports.view
  const showReports          = isSuperAdmin || hasPermission("menu.reports") || hasPermission("reports.view");
  // User management
  const showManageUsers      = isSuperAdmin || hasPermission("users.manage");
  const showRoles            = isSuperAdmin || hasPermission("roles.manage");
  const showPermissions      = isSuperAdmin || hasPermission("permissions.manage");
  // Curriculum
  const showWorldManage      = isSuperAdmin || hasPermission("worlds.view") || hasPermission("world.view");
  // Billing sub-items — each matches the exact backend middleware
  const showPayments         = isSuperAdmin || hasPermission("menu.payments");
  const showInvoices         = isSuperAdmin || hasPermission("billing.view") || hasPermission("menu.payments");
  const showSchoolSubs       = isSuperAdmin || hasPermission("menu.payments");
  const showUserSubs         = isSuperAdmin || hasPermission("menu.payments");
  const showExpenses         = isSuperAdmin || hasPermission("billing.view") || hasPermission("menu.payments");
  // Show the Access Management parent if at least one child is accessible
  const showAccessManagement = showManageUsers || showRoles || showPermissions;
  const showBilling          = showPayments || showInvoices || showSchoolSubs || showUserSubs || showExpenses;

  useEffect(() => {
    const p = location.pathname;
    if (p.startsWith("/admin/users") || p.startsWith("/admin/roles") || p.startsWith("/admin/permissions")) {
      setOpenDropdownKey("access");
    } else if (p.startsWith("/admin/schools") && !p.includes("/payments")) {
      setOpenDropdownKey("management");
    } else if (
      p.startsWith("/admin/worlds") ||
      p.startsWith("/admin/levels") ||
      p.startsWith("/admin/stages") ||
      p.startsWith("/admin/exercises") ||
      p.startsWith("/admin/question-templates")
    ) {
      setOpenDropdownKey("world");
    } else if (
      p.startsWith("/admin/payments") ||
      p.startsWith("/admin/invoices") ||
      p.startsWith("/admin/subscriptions") ||
      p.startsWith("/admin/expenses") ||
      p.match(/^\/admin\/schools\/\d+\/payments/)
    ) {
      setOpenDropdownKey("billing");
    } else if (p.startsWith("/admin/students")) {
      setOpenDropdownKey(null);
    } else {
      setOpenDropdownKey(null);
    }
  }, [location.pathname]);

  if (loading) return <div>Loading...</div>;

  const handleLogout = async () => {
    logout();
  };

  const closeMobileSidebar = () => {
    setMobileMenu(false);
    setSidebarActive(false);
    setOpenDropdownKey(null);
  };


  return (
    <section className={mobileMenu ? "overlay active" : "overlay"}
      onClick={(e) => {
        if (!mobileMenu) return;
        if (e.target.closest(".sidebar")) return;
        closeMobileSidebar();
      }}>
      {/* Sidebar */}
      <aside className={sidebarActive || mobileMenu ? "sidebar active" : "sidebar"}>
        <button
          onClick={() => {
            setMobileMenu(false);
            setSidebarActive(false);
          }}
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
            {/* <li className="sidebar-menu-group-title">Application</li> */}

            <li>
              <NavLink to="/admin" end>
                <Icon icon="mdi:view-dashboard" className="menu-icon" />
                <span>Dashboard</span>
              </NavLink>
            </li>

            {showManageClients && (
              <li>
                <NavLink to="/admin/schools">
                  <Icon icon="mdi:account-multiple" className="menu-icon" />
                  <span>Manage Clients</span>
                </NavLink>
              </li>
            )}

            {showStudents && (
              <li>
                <NavLink to="/admin/students">
                  <Icon icon="mdi:account-school" className="menu-icon" />
                  <span>Manage Students</span>
                </NavLink>
              </li>
            )}

            {showBilling && (
              <li className={`dropdown ${openDropdownKey === "billing" ? "open" : ""}`}>
                <a
                  href="#billing"
                  className={`menu-trigger ${openDropdownKey === "billing" ? "active-page" : ""}`}
                  onClick={(e) => {
                    e.preventDefault();
                    setOpenDropdownKey((prev) => (prev === "billing" ? null : "billing"));
                  }}
                >
                  <Icon icon="mdi:card-account-details-star" className="menu-icon" />
                  <span>Billing</span>
                  <Icon
                    icon={openDropdownKey === "billing" ? "mdi:chevron-up" : "mdi:chevron-down"}
                    className="caret ms-auto"
                  />
                </a>

                <ul
                  className="sidebar-submenu"
                  style={{
                    maxHeight: openDropdownKey === "billing" ? "600px" : "0px",
                    overflow: "hidden",
                    transition: "max-height .25s ease",
                  }}
                >
                  {showPayments && (
                    <li>
                      <NavLink
                        to="/admin/payments"
                        className={({ isActive }) => (isActive ? "active-page" : "")}
                      >
                        <i className="ri-circle-fill circle-icon text-primary-600 w-auto" />
                        Payments
                      </NavLink>
                    </li>
                  )}
                  {showInvoices && (
                    <li>
                      <NavLink
                        to="/admin/invoices"
                        className={({ isActive }) => (isActive ? "active-page" : "")}
                      >
                        <i className="ri-circle-fill circle-icon text-success-main w-auto" />
                        Invoices
                      </NavLink>
                    </li>
                  )}
                  {showSchoolSubs && (
                    <li>
                      <NavLink
                        to="/admin/subscriptions/schools"
                        className={({ isActive }) => (isActive ? "active-page" : "")}
                      >
                        <i className="ri-circle-fill circle-icon text-info-main w-auto" />
                        School Subscriptions
                      </NavLink>
                    </li>
                  )}
                  {showUserSubs && (
                    <li>
                      <NavLink
                        to="/admin/subscriptions/users"
                        className={({ isActive }) => (isActive ? "active-page" : "")}
                      >
                        <i className="ri-circle-fill circle-icon text-warning-main w-auto" />
                        User Subscriptions
                      </NavLink>
                    </li>
                  )}
                  {showExpenses && (
                    <li>
                      <NavLink
                        to="/admin/expenses"
                        className={({ isActive }) => (isActive ? "active-page" : "")}
                      >
                        <i className="ri-circle-fill circle-icon text-danger-main w-auto" />
                        Expenses
                      </NavLink>
                    </li>
                  )}
                </ul>
              </li>
            )}

            {showReports && (
              <li>
                <NavLink to="/admin/reports">
                  <Icon icon="mdi:file-chart" className="menu-icon" />
                  <span>Reports</span>
                </NavLink>
              </li>
            )}


            {showWorldManage && (
              <li className={`dropdown ${openDropdownKey === "world" ? "open" : ""}`}>
                <a
                  href="#world"
                  className={`menu-trigger ${openDropdownKey === "world" ? "active-page" : ""}`}
                  onClick={(e) => {
                    e.preventDefault();
                    setOpenDropdownKey((prev) => (prev === "world" ? null : "world"));
                  }}
                >
                  <Icon icon="mdi:earth" className="menu-icon" />
                  <span>World Management</span>
                  <Icon
                    icon={openDropdownKey === "world" ? "mdi:chevron-up" : "mdi:chevron-down"}
                    className="caret ms-auto"
                  />
                </a>

                <ul
                  className="sidebar-submenu"
                  style={{
                    maxHeight: openDropdownKey === "world" ? "600px" : "0px",
                    overflow: "hidden",
                    transition: "max-height .25s ease",
                  }}
                >
                  <li>
                    <NavLink
                      to="/admin/worlds"
                      className={({ isActive }) => (isActive ? "active-page" : "")}
                    >
                      <i className="ri-circle-fill circle-icon text-primary-600 w-auto" />
                      Manage Worlds
                    </NavLink>
                  </li>

                  {/* <li>
                    <NavLink
                      to="/admin/levels"
                      className={({ isActive }) => (isActive ? "active-page" : "")}
                    >
                      <i className="ri-circle-fill circle-icon text-warning-main w-auto" />
                      Manage Levels
                    </NavLink>
                  </li> */}

                  {/* <li>
                    <NavLink
                      to="/admin/stages"
                      className={({ isActive }) => (isActive ? "active-page" : "")}
                    >
                      <i className="ri-circle-fill circle-icon text-info-main w-auto" />
                      Manage Stages
                    </NavLink>
                  </li> */}

                  <li>
                    <NavLink
                      to="/admin/exercises"
                      className={({ isActive }) => (isActive ? "active-page" : "")}
                    >
                      <i className="ri-circle-fill circle-icon text-success-main w-auto" />
                      Manage Exercises
                    </NavLink>
                  </li>

                  <li>
                    <NavLink
                      to="/admin/question-templates"
                      className={({ isActive }) => (isActive ? "active-page" : "")}
                    >
                      <i className="ri-circle-fill circle-icon text-info-main w-auto" />
                      Manage Questions
                    </NavLink>
                  </li>
                </ul>
              </li>
            )}


            {showAccessManagement && (
              <li
                className={`dropdown ${openDropdownKey === "access" ? "open" : ""}`}
              >
                <a
                  href="#access"
                  className={`menu-trigger ${openDropdownKey === "access" ? "active-page" : ""
                    }`}
                  onClick={(e) => {
                    e.preventDefault();
                    setOpenDropdownKey((prev) =>
                      prev === "access" ? null : "access"
                    );
                  }}
                >
                  <Icon icon="flowbite:users-group-outline" className="menu-icon" />
                  <span>Manage Users</span>
                  <Icon
                    icon={
                      openDropdownKey === "access"
                        ? "mdi:chevron-up"
                        : "mdi:chevron-down"
                    }
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
                        to="/admin/users"
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
                        to="/admin/roles"
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
                        to="/admin/permissions"
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

            {/* ── Super Admin Only: System Audit Logs ── */}
            {isSuperAdmin && (
              <li>
                <NavLink to="/admin/audit-logs">
                  <Icon icon="mdi:shield-lock-outline" className="menu-icon" />
                  <span>System Audit Logs</span>
                </NavLink>
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
