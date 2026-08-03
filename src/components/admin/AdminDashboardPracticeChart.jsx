import React from "react";
import Chart from "react-apexcharts";
import { Icon } from "@iconify/react";

const AdminDashboardPracticeChart = ({ practiceTrend = [] }) => {
    const categories = practiceTrend.map((d) => d.label || d.date);
    const attemptsData = practiceTrend.map((d) => d.attempts || 0);
    const correctData = practiceTrend.map((d) => d.correct || 0);

    const chartOptions = {
        chart: {
            type: "area",
            height: 280,
            toolbar: { show: false },
            fontFamily: "Inter, sans-serif",
            sparkline: { enabled: false },
        },
        dataLabels: { enabled: false },
        stroke: { curve: "smooth", width: 2 },
        colors: ["#487FFF", "#45B369"],
        fill: {
            type: "gradient",
            gradient: {
                shadeIntensity: 1,
                opacityFrom: 0.3,
                opacityTo: 0.05,
                stops: [0, 90, 100],
            },
        },
        xaxis: {
            categories: categories.length > 0 ? categories : ["No Data"],
            labels: {
                style: { colors: "#94A3B8", fontSize: "12px" },
            },
            axisBorder: { show: false },
            axisTicks: { show: false },
        },
        yaxis: {
            labels: {
                style: { colors: "#94A3B8", fontSize: "12px" },
            },
        },
        grid: {
            borderColor: "#F1F5F9",
            strokeDashArray: 4,
        },
        tooltip: {
            theme: "light",
            y: {
                formatter: (val) => `${val} submissions`,
            },
        },
        legend: {
            position: "top",
            horizontalAlign: "right",
        },
    };

    const chartSeries = [
        { name: "Total Attempt Submissions", data: attemptsData },
        { name: "Correct Submissions", data: correctData },
    ];

    return (
        <div className="card border shadow-sm h-100" style={{ borderRadius: "12px" }}>
            <div className="card-header bg-white py-16 px-24 border-bottom d-flex align-items-center justify-content-between">
                <div>
                    <h6 className="mb-0 fw-bold">Platform-Wide Practice Volume (14 Days)</h6>
                    <span className="text-xs text-secondary-light">Daily student exercise attempts & accuracy trends across all schools</span>
                </div>
                <div className="d-flex align-items-center gap-2">
                    <span className="badge bg-success-50 text-success-600 px-12 py-6 rounded-pill text-xs fw-semibold">
                        Live Analytics
                    </span>
                </div>
            </div>
            <div className="card-body p-20">
                {practiceTrend.length > 0 ? (
                    <Chart options={chartOptions} series={chartSeries} type="area" height={280} />
                ) : (
                    <div className="d-flex flex-column align-items-center justify-content-center py-5">
                        <Icon icon="solar:chart-line-broken" className="text-secondary-light text-4xl mb-2" />
                        <p className="text-secondary-light text-sm mb-0">No practice activity recorded in the last 14 days.</p>
                    </div>
                )}
            </div>
        </div>
    );
};

export default AdminDashboardPracticeChart;
