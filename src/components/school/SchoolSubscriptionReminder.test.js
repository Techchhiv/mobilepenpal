import React from "react";
import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";

jest.mock("@iconify/react", () => ({
  Icon: ({ icon, ...props }) => <span data-testid="icon" data-icon={icon} {...props} />,
}));

import SchoolSubscriptionReminder from "./SchoolSubscriptionReminder";

const renderWithRouter = (ui) => {
  return render(<MemoryRouter>{ui}</MemoryRouter>);
};

describe("SchoolSubscriptionReminder", () => {
  it("renders loading skeleton properly without flashing 'No Subscription' or '0 days'", () => {
    renderWithRouter(<SchoolSubscriptionReminder loading={true} />);
    expect(screen.getByTestId("subscription-loading")).toBeInTheDocument();
    expect(screen.queryByText(/No Active Subscription/i)).not.toBeInTheDocument();
    expect(screen.queryByText(/0 days remaining/i)).not.toBeInTheDocument();
  });

  it("renders error state gracefully when error prop is provided", () => {
    renderWithRouter(
      <SchoolSubscriptionReminder
        loading={false}
        error="Unable to fetch subscription"
      />
    );
    expect(screen.getByTestId("subscription-error")).toBeInTheDocument();
    expect(
      screen.getByText(/Unable to load subscription information\. Please try again later\./i)
    ).toBeInTheDocument();
  });

  it("renders 'No Active Subscription' state when school has no subscription", () => {
    renderWithRouter(
      <SchoolSubscriptionReminder
        loading={false}
        subscription={{
          has_subscription: false,
          is_active: false,
          status: "none",
          plan: null,
          end_date: null,
        }}
      />
    );

    expect(screen.getByTestId("subscription-none")).toBeInTheDocument();
    expect(screen.getByText("No Active Subscription")).toBeInTheDocument();
    expect(
      screen.getByText(
        /There is currently no active subscription associated with your school\. Please contact Khmer PenPal for assistance\./i
      )
    ).toBeInTheDocument();
    expect(screen.queryByText(/days remaining/i)).not.toBeInTheDocument();
    expect(screen.getByRole("link", { name: /View Subscription/i })).toHaveAttribute(
      "href",
      "/school/subscription"
    );
  });

  it("renders normal active state when more than 30 days remaining", () => {
    // 60 days in the future
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 60);
    const endStr = futureDate.toISOString().split("T")[0];

    renderWithRouter(
      <SchoolSubscriptionReminder
        loading={false}
        subscription={{
          has_subscription: true,
          is_active: true,
          is_expired: false,
          status: "active",
          plan: "yearly",
          end_date: endStr,
          days_left: 60,
        }}
      />
    );

    expect(screen.getByTestId("subscription-normal")).toBeInTheDocument();
    expect(screen.getByText("Yearly Plan")).toBeInTheDocument();
    expect(screen.getByText(/Active/i)).toBeInTheDocument();
    expect(screen.getByText(/60 days remaining/i)).toBeInTheDocument();
    // Warning banner should NOT appear
    expect(screen.queryByText(/⚠ Subscription Expiring Soon/i)).not.toBeInTheDocument();
  });

  it("renders expiring soon warning reminder when 30 days or less remaining", () => {
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 24);
    const endStr = futureDate.toISOString().split("T")[0];

    renderWithRouter(
      <SchoolSubscriptionReminder
        loading={false}
        subscription={{
          has_subscription: true,
          is_active: true,
          is_expired: false,
          status: "expiring_soon",
          plan: "Premium Plan",
          end_date: endStr,
          days_left: 24,
        }}
      />
    );

    expect(screen.getByTestId("subscription-warning")).toBeInTheDocument();
    expect(screen.getByText("Premium Plan")).toBeInTheDocument();
    expect(screen.getByText(/⚠ Subscription Expiring Soon/i)).toBeInTheDocument();
    expect(
      screen.getByText(
        /Your subscription expires in 24 days\. Please contact Khmer PenPal if you would like to renew your subscription\./i
      )
    ).toBeInTheDocument();
  });

  it("renders stronger critical warning when 7 days or less remaining", () => {
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 5);
    const endStr = futureDate.toISOString().split("T")[0];

    renderWithRouter(
      <SchoolSubscriptionReminder
        loading={false}
        subscription={{
          has_subscription: true,
          is_active: true,
          is_expired: false,
          status: "critical",
          plan: "monthly",
          end_date: endStr,
          days_left: 5,
        }}
      />
    );

    expect(screen.getByTestId("subscription-critical")).toBeInTheDocument();
    expect(screen.getByText("Monthly Plan")).toBeInTheDocument();
    expect(screen.getByText(/⚠ Subscription Expiring Soon/i)).toBeInTheDocument();
    expect(
      screen.getByText(
        /Your subscription expires in 5 days\. Please contact Khmer PenPal to renew your subscription\./i
      )
    ).toBeInTheDocument();
  });

  it("renders expired state and NEVER displays negative remaining days", () => {
    const pastDate = new Date();
    pastDate.setDate(pastDate.getDate() - 10);
    const endStr = pastDate.toISOString().split("T")[0];

    renderWithRouter(
      <SchoolSubscriptionReminder
        loading={false}
        subscription={{
          has_subscription: true,
          is_active: false,
          is_expired: true,
          status: "expired",
          plan: "Premium Plan",
          end_date: endStr,
          days_left: 0,
        }}
      />
    );

    expect(screen.getByTestId("subscription-expired")).toBeInTheDocument();
    expect(screen.getAllByText(/Subscription Expired/i).length).toBeGreaterThanOrEqual(1);
    expect(
      screen.getByText(/Please contact Khmer PenPal for subscription assistance\./i)
    ).toBeInTheDocument();
    // Negative days MUST NOT appear!
    expect(screen.queryByText(/-[0-9]+ days remaining/i)).not.toBeInTheDocument();
    expect(screen.queryByText(/remaining/i)).not.toBeInTheDocument();
  });
});
