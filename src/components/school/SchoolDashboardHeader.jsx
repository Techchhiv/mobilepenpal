import React, { useState, useEffect } from "react";
import { Icon } from "@iconify/react";
import { useAuth } from "../../context/AuthContext";

const SchoolDashboardHeader = () => {
    const { user } = useAuth();
    const [dateTime, setDateTime] = useState(new Date());

    useEffect(() => {
        const timer = setInterval(() => setDateTime(new Date()), 1000);
        return () => clearInterval(timer);
    }, []);

    const greeting = (() => {
        const hour = dateTime.getHours();
        if (hour < 12) return "Good Morning";
        if (hour < 17) return "Good Afternoon";
        return "Good Evening";
    })();

    const formattedDate = dateTime.toLocaleDateString("en-US", {
        weekday: "long",
        year: "numeric",
        month: "long",
        day: "numeric",
    });

    const formattedTime = dateTime.toLocaleTimeString("en-US", {
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit",
    });

    return (
        <div
            className="card bg-gradient-start-1 border-0 shadow-none mb-24 overflow-hidden"
            style={{ borderRadius: "12px" }}
        >
            <div className="card-body p-24">
                <div className="d-flex flex-wrap align-items-center justify-content-between gap-3">
                    <div>
                        <h5 className="fw-bold text-primary-light mb-1">
                            {greeting}, {user?.name || "School Admin"} 👋
                        </h5>
                        <p
                            className="fw-medium text-secondary-light mb-0"
                            style={{ fontSize: "14px" }}
                        >
                            Here's what's happening with your school today.
                        </p>
                    </div>

                    <div className="d-flex flex-column align-items-end gap-2">
                        <div className="d-flex align-items-center gap-2 px-16 py-8 w-100 justify-content-end">
                            <Icon
                                icon="solar:calendar-bold-duotone"
                                className="text-primary-600 text-xl"
                            />
                            <span className="fw-medium text-sm text-primary-light">
                                {formattedDate}
                            </span>
                        </div>
                        <div className="d-flex align-items-center gap-2 px-16 py-8 w-100 justify-content-end">
                            <Icon
                                icon="solar:clock-circle-bold-duotone"
                                className="text-primary-600 text-xl"
                            />
                            <span
                                className="fw-medium text-sm text-primary-light"
                                style={{ fontVariantNumeric: "tabular-nums" }}
                            >
                                {formattedTime}
                            </span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default SchoolDashboardHeader;
