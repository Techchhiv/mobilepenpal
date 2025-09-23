// src/frontend/masterLayout/MasterLayout.jsx
import React, { useEffect, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";
import API from "../../helper/api";
import SearchBar from "../components/SearchBox";
import { Container, Row, Col, Form, Button } from "react-bootstrap";
import { MdOutlineFavorite } from "react-icons/md";
import { useFavorite } from "../../context/FavoriteContext";
import LogoLoader from "../../helper/LogoLoader";
import FaceFOng from "../../assets/images/1x/facebook.png";
import TeleFOng from "../../assets/images/1x/telegram.png";
import TKFOng from "../../assets/images/1x/tiktok.png";
import { useCart } from "../../context/CartContext";
import Seo from "../components/Seo"; // ← add this

const nameToSlug = (name = "") =>
  String(name)
    .normalize("NFKD")
    .toLowerCase()
    .trim()
    .replace(/[\s_]+/g, "-")
    .replace(/[^\p{L}\p{N}-]+/gu, "")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");

// Build /category/:slug
const categoryLink = (item) =>
  `/category/${encodeURIComponent(item?.slug ?? nameToSlug(item?.name ?? ""))}`;

const DEFAULT_HERO =
  "https://sambatpsalan.com/static/media/cover.09f6ce551469fb2ace96.jpg";

const MasterLayout = ({ children }) => {
  const { user, loading, logout } = useAuth();
  const navigate = useNavigate();
  const { cartItems } = useCart();
  const { favorites } = useFavorite();

  const [loading0, setLoading0] = useState(true);
  const [mobileMenu, setMobileMenu] = useState(false);
  const [isSearchOpen, setSearchOpen] = useState(false);
  const [active, setActive] = useState("");
  const [showMore, setShowMore] = useState(false);
  const [isMobile, setIsMobile] = useState(false);
  const [categories, setCategories] = useState([]);

  const location = useLocation();

  useEffect(() => {
    const fetchCategories = async () => {
      try {
        const res = await API.get("/categories");
        setCategories(Array.isArray(res.data) ? res.data : []);
      } catch (error) {
        console.error("Error fetching categories:", error);
        setCategories([]);
      } finally {
        setLoading0(false);
      }
    };
    fetchCategories();
  }, []);

  useEffect(() => {
    const handleResize = () => setIsMobile(window.innerWidth < 768);
    handleResize();
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  // highlight active category by slug from URL
  useEffect(() => {
    const m = location.pathname.match(/^\/category\/([^/?#]+)/);
    if (m?.[1]) setActive(decodeURIComponent(m[1]));
    else if (location.pathname === "/") setActive("home");
  }, [location.pathname]);

  const handleLogout = async () => {
    try {
      await API.post("/logout");
      localStorage.removeItem("token");
      localStorage.removeItem("user");
      logout();
      navigate("/");
    } catch (error) {
      console.error("Logout failed:", error);
    }
  };

  const handleGoogleSignIn = async () => {
    try {
      const currentPath = window.location.pathname + window.location.search;
      const response = await API.get(
        `auth/google/redirect?redirect=${encodeURIComponent(currentPath)}`
      );
      if (response.data?.url) {
        window.location.href = response.data.url;
      } else {
        console.error("Redirect URL not received");
      }
    } catch (error) {
      console.error("Error getting Google redirect URL:", error);
    }
  };

  const MAX_VISIBLE = 10;
  const visibleMenus = Array.isArray(categories)
    ? categories.slice(0, MAX_VISIBLE)
    : [];
  const hiddenMenus = Array.isArray(categories)
    ? categories.slice(MAX_VISIBLE)
    : [];

  // ---------- SEO defaults (route-aware) ----------
  const canonicalPath = location.pathname + location.search;

  // Skip default SEO on product detail (the ProductDetail page sets its own <Seo />)
  const skipDefaultSeo = /^\/product\//.test(location.pathname);

  // Build a simple dynamic title/description for common routes
  let seoTitle;
  let seoDesc =
    "ស្វែងរកឡានថ្មី និងឡានចាស់គុណភាពល្អ តម្លៃសមរម្យ នៅកម្ពុជា។";
  let seoImage = DEFAULT_HERO;

  if (location.pathname === "/") {
    seoTitle = "ផ្ទាំងដើម";
  } else if (/^\/category\//.test(location.pathname)) {
    const slug = decodeURIComponent(location.pathname.split("/")[2] || "");
    const cat = categories.find(
      (c) => (c?.slug ?? nameToSlug(c?.name ?? "")) === slug
    );
    const catName = cat?.name || slug.replace(/-/g, " ");
    seoTitle = `${catName}`;
    seoDesc = `ជម្រើសឡានក្នុងប្រភេទ ${catName} តម្លៃសមរម្យ នៅកម្ពុជា។`;
  } else if (location.pathname === "/favorite") {
    seoTitle = "ទំនិញដែលចូលចិត្ត";
  } else if (location.pathname === "/cart") {
    seoTitle = "order";
  } else if (location.pathname.startsWith("/sign-in")) {
    seoTitle = "ចូលគណនី";
  } else {
    // generic fallback
    seoTitle = "ទំព័រ";
  }

  if (loading0) return <LogoLoader />;
  if (loading) return <div>Loading...</div>;

  return (
    <section className={mobileMenu ? "overlay active" : "overlay"}>
      <main>
        {/* Default SEO (children pages can override; product page skips) */}
        {!skipDefaultSeo && (
          <Seo
            title={seoTitle}
            description={seoDesc}
            canonical={canonicalPath}
            image={seoImage}
          />
        )}

        {/* ---------- Header ---------- */}
        <div className="container py-2 mt-4 border-bottom">
          <div className="row align-items-center justify-content-between mt-3 mb-3">
            <div className="col-auto align-items-center d-flex">
              <Icon
                icon="ion:search-sharp"
                className="fs-4 cursor-pointer"
                onClick={() => setSearchOpen(true)}
              />
              <a href="https://www.facebook.com/share/1C3XQZ12ft/?mibextid=wwXIfr">
                <img
                  src={FaceFOng}
                  alt="Facebook"
                  className="ms-3"
                  style={{ width: "20px" }}
                />
              </a>
              <a href="https://www.tiktok.com/@sambat_phsalan168">
                <img
                  src={TKFOng}
                  alt="TikTok"
                  className="ms-1"
                  style={{ width: "20px" }}
                />
              </a>
              <a href="https://t.me/Sok_heng1688">
                <img
                  src={TeleFOng}
                  alt="Telegram"
                  className="ms-1"
                  style={{ width: "20px" }}
                />
              </a>
            </div>

            <div className="col text-center">
              <h5 className="mb-0">សម្បត្តិ ផ្សារឡាន</h5>
            </div>

            <div className="col-auto d-flex align-items-center gap-3">
              <Link to="/favorite" className="position-relative">
                <MdOutlineFavorite className="text-danger text-2xl" />
                {favorites.length > 0 && (
                  <span
                    className="badge position-absolute top-0 start-100 translate-middle bg-danger text-white rounded-circle"
                    style={{ fontSize: "0.7rem" }}
                  >
                    {favorites.length}
                  </span>
                )}
              </Link>

              <Link
                to="/cart"
                className="position-relative text-dark text-decoration-none"
              >
                <Icon icon="ion:cart-outline" className="fs-4" />
                {cartItems.length > 0 && (
                  <span
                    className="badge position-absolute top-0 start-100 translate-middle bg-danger text-white rounded-circle"
                    style={{ fontSize: "0.7rem" }}
                  >
                    {cartItems.reduce(
                      (acc, item) => acc + Number(item.quantity),
                      0
                    )}
                  </span>
                )}
              </Link>

              <div className="dropdown">
                <button
                  className="btn p-0 bg-transparent border-0 dropdown-toggle"
                  id="userMenu"
                  data-bs-toggle="dropdown"
                  aria-expanded="false"
                >
                  <Icon
                    icon="solar:user-linear"
                    className="text-dark"
                    style={{ fontSize: 24, cursor: "pointer" }}
                  />
                </button>

                <div
                  className="dropdown-menu dropdown-menu-end p-0 shadow"
                  aria-labelledby="userMenu"
                >
                  <div className="py-2 px-3 border-bottom text-center">
                    <h6 className="fw-bold mb-0">
                      {user ? user.name : "Welcome!"}
                    </h6>
                    <small className="text-muted">
                      {user ? user.email : "Please Sign In"}
                    </small>
                  </div>

                  <ul className="list-unstyled mb-0 py-1">
                    <li>
                      <button
                        onClick={handleGoogleSignIn}
                        className="dropdown-item d-flex align-items-center justify-content-center gap-2"
                      >
                        <Icon icon="logos:google-gmail" /> Sign In
                      </button>
                    </li>
                    <li>
                      <Link
                        to="/sign-in"
                        className="dropdown-item d-flex align-items-center justify-content-center gap-2"
                      >
                        <Icon icon="solar:user-linear" /> Admin
                      </Link>
                    </li>
                    <li>
                      <button
                        onClick={handleLogout}
                        className="dropdown-item d-flex align-items-center justify-content-center gap-2 text-danger"
                      >
                        <Icon icon="lucide:power" /> Log Out
                      </button>
                    </li>
                  </ul>
                </div>
              </div>
            </div>
          </div>

          {/* Menu Section */}
          <div className="my-3 d-flex gap-3 flex-wrap justify-content-center">
            <Link
              to="/"
              onClick={() => setActive("home")}
              className={`text-decoration-none pb-1 ${
                active === "home"
                  ? "border-bottom border-primary"
                  : "text-secondary"
              }`}
            >
              Home
            </Link>

            {/* Top visible menus (by slug) */}
            {Array.isArray(visibleMenus) &&
              visibleMenus.map((item) => {
                const slug = item?.slug ?? nameToSlug(item?.name ?? "");
                return (
                  <Link
                    key={item.id}
                    to={categoryLink(item)}
                    onClick={() => setActive(slug)}
                    className={`text-decoration-none pb-1 ${
                      active === slug
                        ? "border-bottom border-primary text-uppercase"
                        : "text-secondary text-uppercase"
                    }`}
                  >
                    {item.name}
                  </Link>
                );
              })}

            {isMobile && hiddenMenus.length > 0 && (
              <span
                onClick={() => setShowMore(!showMore)}
                style={{ cursor: "pointer" }}
              >
                <Icon
                  icon={
                    showMore
                      ? "material-symbols-light:arrow-circle-up"
                      : "material-symbols-light:arrow-circle-right-rounded"
                  }
                  width="24"
                  height="24"
                />
              </span>
            )}
          </div>

          {/* Mobile “more” dropdown (by slug) */}
          {isMobile && showMore && (
            <div className="dropdown-menu show position-static mt-2 px-3 py-2 shadow-sm">
              {hiddenMenus.map((item) => {
                const slug = item?.slug ?? nameToSlug(item?.name ?? "");
                return (
                  <Link
                    to={categoryLink(item)}
                    key={item.id}
                    className="dropdown-item text-uppercase"
                    onClick={() => {
                      setActive(slug);
                      setShowMore(false);
                    }}
                  >
                    {item.name}
                  </Link>
                );
              })}
            </div>
          )}

          <SearchBar isOpen={isSearchOpen} onClose={() => setSearchOpen(false)} />
        </div>

        <div className="dashboard-main-body">{children}</div>

        {/* Footer */}
        <footer
          className="pt-5 pb-4"
          style={{ background: "linear-gradient(135deg, #e5fbc1, #fddfdc)" }}
        >
          <Container>
            <div className="text-center mb-4">
              <h2 className="fw-bold">លក់ឡានគ្រប់ប្រភេទដែលមានគុណភាពខ្ពស់</h2>
              <p className="text-muted">Join our email list for exclusive offers.</p>
              <Form className="d-flex justify-content-center">
                <Form.Control
                  type="email"
                  placeholder="Email"
                  className="me-2 w-50 rounded-pill px-4 border-0"
                  style={{ maxWidth: "400px", background: "#e4ffae" }}
                />
                <Button
                  type="submit"
                  className="rounded-pill px-4"
                  style={{ background: "#e4ffae", border: "none" }}
                >
                  →
                </Button>
              </Form>
            </div>

            <Row className="mt-5 text-start">
              <Col md={4}>
                <h5 className="fw-bold">Menu</h5>
                <div className="d-flex flex-column">
                  {categories.map((item) => (
                    <Link
                      key={item.id}
                      to={categoryLink(item)}
                      className="text-decoration-none mb-2 text-uppercase text-dark"
                    >
                      {item.name}
                    </Link>
                  ))}
                </div>
              </Col>
              <Col md={4}>
                <h5 className="fw-bold">Our Store</h5>
                <p>
                  Try Heng III Thong
                  <br />
                  Phnom Penh, Cambodia
                </p>
                <p><strong>Mon – Fri:</strong></p>
                <p><strong>Sat – Sun:</strong> </p>
              </Col>
              <Col md={4}>
                <h5 className="fw-bold">Our Promise</h5>
                <p>លក់ឡានគ្រប់ប្រភេទដែលមានគុណភាពខ្ពស់</p>
                <img src="assets/images/logoCar.png" alt="Flower" style={{ height: "180px" }} />
              </Col>
            </Row>

            <div className="text-center mt-3 text-muted" style={{ fontSize: "0.85rem" }}>
              សម្បត្តិ ផ្សារឡាន © 2025
            </div>
          </Container>
        </footer>
      </main>
    </section>
  );
};

export default MasterLayout;
