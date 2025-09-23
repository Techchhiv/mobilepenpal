import React, { useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import MasterLayout from "../masterLayout/MasterLayout";
import { Container, Row, Col, Button, Form } from "react-bootstrap";
import { Link, useNavigate } from "react-router-dom";
import { useCart } from "../../context/CartContext";
import API from "../../helper/api";
import API_BASE_URL from "../../helper/Base_urls";

/* ---------- constants & helpers ---------- */
const SITE_NAME = "សម្បត្តិ ផ្សារឡាន";
const PROD_ORIGIN = "https://www.sambatpsalan.com";

// Use prod origin for Telegram if running on localhost / private IPs
const BASE_URL =
  typeof window === "undefined"
    ? PROD_ORIGIN
    : /^(http:\/\/localhost|http:\/\/127\.|http:\/\/10\.|http:\/\/192\.168\.)/i.test(
        window.location.origin
      )
    ? PROD_ORIGIN
    : window.location.origin;

const ORDER_LINK_URL = `${BASE_URL}/cart`; // change if you have a dedicated order page

const isMobile = () =>
  typeof window !== "undefined" ? window.innerWidth < 768 : false;

const nameToSlug = (name = "") =>
  String(name)
    .normalize("NFKD")
    .toLowerCase()
    .trim()
    .replace(/[\s_]+/g, "-")
    .replace(/[^\p{L}\p{N}-]+/gu, "")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");

const fallbackSlug = (name, id) => {
  const base = nameToSlug(name);
  return `${base || "item"}-${id}`;
};

// HTML escape for Telegram HTML parse_mode
const htmlEscape = (s = "") =>
  String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

// Build a public product URL from cart item using the public BASE_URL
const productPublicUrl = (item) => {
  const slug =
    (item.slug && String(item.slug).trim()) || fallbackSlug(item.name, item.id);
  return `${BASE_URL}/product/${encodeURIComponent(slug)}`;
};

const imgFallback = `${API_BASE_URL}/assets/images/og-default.jpg`;

/* ----------------------------- component ----------------------------- */
const Cart = () => {
  const { cartItems, setCartItems } = useCart();
  const [userName, setUserName] = useState("");
  const [userPhone, setUserPhone] = useState("");
  const navigate = useNavigate();

  const truncate = (text, desktopLimit = 100, mobileLimit = 100) => {
    const limit = isMobile() ? mobileLimit : desktopLimit;
    return text.length > limit ? text.slice(0, limit) + "..." : text;
  };

  const subtotal = useMemo(
    () =>
      cartItems.reduce(
        (acc, item) =>
          acc +
          (Number(item.price) || 0) * (Number(item.quantity) || 1),
        0
      ),
    [cartItems]
  );

  const updateQuantity = (id, delta) => {
    setCartItems((prev) =>
      prev.map((item) =>
        item.id === id
          ? {
              ...item,
              quantity: Math.max(1, (Number(item.quantity) || 1) + delta),
            }
          : item
      )
    );
  };

  const removeItem = (id) => {
    setCartItems((prev) => prev.filter((item) => item.id !== id));
  };

  const handleCheckout = async (e) => {
    e.preventDefault();
    if (!cartItems.length) return;

    // 1) Auth check
    const token = localStorage.getItem("token");
    if (!token) {
      try {
        const currentPath =
          window.location.pathname + window.location.search;
        const { data } = await API.get(
          `auth/google/redirect?redirect=${encodeURIComponent(currentPath)}`
        );
        if (data?.url) window.location.href = data.url;
      } catch (error) {
        console.error("Google login redirect error:", error);
      }
      return;
    }

    // 2) Create order
    const formData = new FormData();
    formData.append("user_name", userName);
    formData.append("user_phone", userPhone);
    formData.append("status", "pending");
    formData.append("total_price", String(subtotal));

    cartItems.forEach((item, index) => {
      formData.append(`items[${index}][product_id]`, item.id);
      formData.append(`items[${index}][quantity]`, item.quantity);
      formData.append(`items[${index}][price]`, item.price);
    });

    try {
      await API.post("/orders", formData, {
        headers: {
          "Content-Type": "multipart/form-data",
          Authorization: `Bearer ${token}`,
        },
      });

      // 3) Notify Telegram (use public URLs only)
       const botToken = "7916718965:AAFhoLvmylP3iFrdcN6oruoFhseiEHK7CAc";
      const chatId = "1381670381";

      const orderLines = cartItems
        .map((item, i) => {
          const url = productPublicUrl(item);
          const name = htmlEscape(item.name);
          const qty = Number(item.quantity) || 1;
          const price = Number(item.price) || 0;
          const lineTotal = (qty * price).toFixed(2);
          return `${i + 1}. <a href="${url}">${name}</a> — ${qty} × $${price.toFixed(
            2
          )} = $${lineTotal}`;
        })
        .join("\n");

      const siteTitle = `<a href="${BASE_URL}"><b>${htmlEscape(
        SITE_NAME
      )}</b></a>`;
      const orderHeader = `🧾 <a href="${ORDER_LINK_URL}">Order</a>:`; // clickable

      const message =
        `${siteTitle}\n` +
        `🛒 <b>New Order Received</b>\n\n` +
        `👤 Name: ${htmlEscape(userName)}\n` +
        `📞 Phone: ${htmlEscape(userPhone)}\n\n` +
        `${orderHeader}\n${orderLines}\n\n` +
        `💵 <b>Total:</b> $${subtotal.toFixed(2)}`;

      const tgRes = await fetch(
        `https://api.telegram.org/bot${botToken}/sendMessage`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            chat_id: chatId,
            text: message,
            parse_mode: "HTML",
            disable_web_page_preview: false,
          }),
        }
      );
      const tgJson = await tgRes.json();
      if (!tgRes.ok) {
        console.error("Telegram error:", tgJson);
      }

      // 4) Cleanup + redirect
      setCartItems([]);
      setUserName("");
      setUserPhone("");
      navigate("/");
    } catch (error) {
      console.error("Checkout error:", error);
    }
  };

  return (
    <MasterLayout>
      <Container className="py-4">
        <div className="d-flex justify-content-between align-items-center mb-4 flex-wrap">
          <h4 className="mb-2">Your Cart</h4>
          <Link to="/">
            <p className="text-primary mb-0">Continue shopping</p>
          </Link>
        </div>

        {cartItems.length === 0 ? (
          <p>Your cart is empty.</p>
        ) : (
          <Form onSubmit={handleCheckout}>
            {cartItems.map((item) => (
              <Row
                key={item.id}
                className="align-items-center mb-4 border-bottom pb-3"
              >
                <Col xs={12} md={2} className="mb-2 mb-md-0">
                  <img
                    src={item.image || imgFallback}
                    alt={item.name}
                    className="img-fluid rounded"
                    onError={(e) => {
                      e.currentTarget.src = imgFallback;
                    }}
                  />
                </Col>
                <Col xs={12} md={4}>
                  <strong className="d-block">
                    {truncate(item.name)}
                  </strong>
                  <span className="text-muted">
                    ${(Number(item.price) || 0).toFixed(2)}
                  </span>
                </Col>
                <Col
                  xs={12}
                  md={3}
                  className="d-flex align-items-center justify-content-start my-2"
                >
                  <Button
                    variant="outline-secondary"
                    onClick={() => updateQuantity(item.id, -1)}
                  >
                    -
                  </Button>
                  <span className="mx-2">{item.quantity}</span>
                  <Button
                    variant="outline-secondary"
                    onClick={() => updateQuantity(item.id, 1)}
                  >
                    +
                  </Button>
                  <Button
                    variant="link"
                    className="text-danger ms-2"
                    onClick={() => removeItem(item.id)}
                  >
                    <Icon icon="mdi:trash-can-outline" />
                  </Button>
                </Col>
                <Col xs={12} md={3} className="text-md-end">
                  <strong>
                    $
                    {(
                      (Number(item.price) || 0) *
                      (Number(item.quantity) || 1)
                    ).toFixed(2)}
                  </strong>
                </Col>
              </Row>
            ))}

            <Row className="mb-3">
              <Col xs={12} md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>User Name</Form.Label>
                  <Form.Control
                    type="text"
                    placeholder="Enter your name"
                    value={userName}
                    onChange={(e) => setUserName(e.target.value)}
                    required
                  />
                </Form.Group>
              </Col>
              <Col xs={12} md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Phone Number</Form.Label>
                  <Form.Control
                    type="tel"
                    placeholder="Enter your phone number"
                    value={userPhone}
                    onChange={(e) => setUserPhone(e.target.value)}
                    required
                  />
                </Form.Group>
              </Col>
            </Row>

            <div className="text-end">
              <h5>
                <strong>Subtotal:</strong> ${subtotal.toFixed(2)}
              </h5>
              <p className="text-muted">
                Taxes and shipping calculated at checkout
              </p>
              <Button
                type="submit"
                className="px-4 py-2"
                style={{ backgroundColor: "#861657" }}
                disabled={!cartItems.length || !userName || !userPhone}
              >
                Check out
              </Button>
            </div>
          </Form>
        )}
      </Container>
    </MasterLayout>
  );
};

export default Cart;
