import React from "react";
import { Link } from "react-router-dom";
import { Icon } from "@iconify/react";
import { useAuth } from "../../context/AuthContext";

/**
 * AdminDashboardQuickActions
 * Shows quick-action cards only when the current user is authorized.
 * Each action matches the exact route gate permission used in App.js.
 */
const AdminDashboardQuickActions = () => {
    const { isSuperAdmin, hasPermission, hasAnyPermission } = useAuth();

    const actions = [
        // Manage Clients — matches Gate anyPerm=["menu.manage_clients"]
        (isSuperAdmin || hasPermission("menu.manage_clients")) && {
            title: "Add School",
            desc: "Register new school tenant",
            icon: "ph:plus-circle-bold",
            to: "/admin/schools",
        },
        // System Users — matches Gate anyPerm=["users.manage","roles.manage","permissions.manage"]
        (isSuperAdmin || hasAnyPermission(["users.manage", "roles.manage", "permissions.manage"])) && {
            title: "System Users",
            desc: "Manage admin & staff roles",
            icon: "ph:user-gear-bold",
            to: "/admin/users",
        },
        // Subscriptions — matches Gate anyPerm=["menu.payments"] (backend requires menu.payments)
        (isSuperAdmin || hasPermission("menu.payments")) && {
            title: "Manage Subscription",
            desc: "School subscription tiers & plans",
            icon: "ph:credit-card-bold",
            to: "/admin/subscriptions/schools",
        },
        // Reports — matches Gate anyPerm=["menu.reports","reports.view"]
        (isSuperAdmin || hasPermission("menu.reports") || hasPermission("reports.view")) && {
            title: "School Reports",
            desc: "View & export school report data",
            icon: "ph:chart-bar-bold",
            to: "/admin/reports",
        },
        // Invoices — matches Gate anyPerm=["billing.view","menu.payments"]
        (isSuperAdmin || hasPermission("billing.view") || hasPermission("menu.payments")) && {
            title: "Invoices",
            desc: "Financial billing records",
            icon: "ph:file-text-bold",
            to: "/admin/invoices",
        },
        // Global Functions — destination requires menu.payments; do NOT show for users.manage only
        (isSuperAdmin || hasPermission("menu.payments")) && {
            title: "Global Functions",
            desc: "Price config & feature lock modal",
            icon: "ph:gear-six-bold",
            to: "/admin/subscriptions/users?modal=settings",
        },
    ].filter(Boolean); // remove any false entries for unauthorized actions

    if (actions.length === 0) return null;

    return (
        <div className="card border shadow-sm mb-24" style={{ borderRadius: "12px" }}>
            <div className="card-header bg-white py-16 px-24 border-bottom d-flex align-items-center justify-content-between">
                <div className="d-flex align-items-center gap-2">
                    <Icon icon="solar:bolt-bold-duotone" className="text-primary-600 text-xl" />
                    <h6 className="mb-0 fw-bold">Quick Actions</h6>
                </div>
                {/* Feature Locks shortcut — destination requires menu.payments */}
                {(isSuperAdmin || hasPermission("menu.payments")) && (
                    <div className="d-flex align-items-center gap-2">
                        <Link
                            to="/admin/subscriptions/users?modal=feature_locks"
                            className="btn btn-sm btn-outline-primary text-xs font-semibold rounded-pill px-12 d-flex align-items-center gap-1"
                        >
                            <Icon icon="ph:lock-key-bold" className="text-sm" />
                            Feature Locks Modal
                        </Link>
                    </div>
                )}
            </div>
            <div className="card-body p-20">
                <div className="row g-3">
                    {actions.map((act, idx) => (
                        <div className="col-12 col-sm-6 col-lg-3" key={idx}>
                            <Link
                                to={act.to}
                                className="d-flex align-items-center gap-3 p-16 rounded-3 border bg-hover-neutral-50 transition-all text-decoration-none h-100"
                            >
                                <div className="w-40-px h-40-px rounded-circle bg-primary-50 text-primary-600 d-flex align-items-center justify-content-center flex-shrink-0">
                                    <Icon icon={act.icon} className="text-xl" />
                                </div>
                                <div className="overflow-hidden">
                                    <h6 className="text-sm fw-bold text-primary-light mb-1 text-truncate">
                                        {act.title}
                                    </h6>
                                    <p className="text-xs text-secondary-light mb-0 text-truncate">
                                        {act.desc}
                                    </p>
                                </div>
                            </Link>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
};

export default AdminDashboardQuickActions;
