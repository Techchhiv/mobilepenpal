// src/frontend/page/ProductDetail.jsx
import React, { useEffect, useState } from "react";
import { Carousel, Button, Col, Container, Row, Modal, Spinner } from "react-bootstrap";
import { Icon } from "@iconify/react";
import MasterLayout from "../masterLayout/MasterLayout";
import fallbackHero from "../../assets/images/nb.png";
import { useNavigate, useParams } from "react-router-dom";
import API from "../../helper/api";
import API_BASE_URL from "../../helper/Base_urls";
import { useCart } from "../../context/CartContext";
import RichDescription from "../components/RichDescription";
import TeleFOng from "../../assets/images/1x/telegram.png";

/* -------------------------- helpers -------------------------- */

const extractIdFromSlug = (slug) => {
  const m = slug?.match(/-(\d+)$/);
  return m ? m[1] : null;
};

const makeDescription = (html, fallback = "") => {
  if (typeof document === "undefined") return (fallback || "").slice(0, 160);
  const tmp = document.createElement("div");
  tmp.innerHTML = html || "";
  const text = tmp.textContent || tmp.innerText || "";
  return (text || fallback).trim().slice(0, 160);
};

const upsertMeta = (attr, key, content) => {
  if (typeof document === "undefined" || !content) return;
  let el = document.querySelector(`meta[${attr}="${key}"]`);
  if (!el) {
    el = document.createElement("meta");
    el.setAttribute(attr, key);
    document.head.appendChild(el);
  }
  el.setAttribute("content", content);
};

const normalizeImageArray = (image, imageBaseUrl) => {
  try {
    if (typeof image === "string" && image.startsWith("[")) {
      image = JSON.parse(image);
    }
  } catch {}
  if (typeof image === "string" && image) return [`${imageBaseUrl}${image}`];
  if (Array.isArray(image) && image.length && typeof image[0] === "string")
    return image.map((p) => `${imageBaseUrl}${p}`);
  if (Array.isArray(image) && image.length && typeof image[0] === "object") {
    return image
      .map((it) => (it?.url ? it.url : it?.path ? `${imageBaseUrl}${it.path}` : null))
      .filter(Boolean);
  }
  return [];
};

const fmtMoney = (n) => {
  const num = Number(n);
  if (Number.isNaN(num)) return "0";
  return num.toLocaleString();
};

/* --------------------------- component --------------------------- */

const ProductDetail = () => {
  const { slug } = useParams();
  const navigate = useNavigate();
  const { addToCart } = useCart();

  const [product, setProduct] = useState(null);
  const [gallery, setGallery] = useState([fallbackHero]);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState("");

  const [show, setShow] = useState(false);
  const [currentImageIndex, setCurrentImageIndex] = useState(0);

  // Share / copy UI
  const [copied, setCopied] = useState(false);

  const imageBaseUrl = `${API_BASE_URL}/storage/`;

  useEffect(() => {
    let alive = true;
    setLoading(true);
    setErr("");
    setProduct(null);
    setGallery([fallbackHero]);

    const doFetch = async () => {
      try {
        const bySlug = await API.get(`/products/slug/${encodeURIComponent(slug)}`);
        if (!alive) return;
        setProduct(bySlug.data);
        const imgs = normalizeImageArray(bySlug?.data?.image, imageBaseUrl);
        setGallery(imgs.length ? imgs : [fallbackHero]);
        setLoading(false);
        return;
      } catch {}

      const id = extractIdFromSlug(slug);
      if (!id) {
        setErr("Product not found.");
        setLoading(false);
        return;
      }

      try {
        const inc = await API.get(`/products/${id}`);
        if (!alive) return;
        setProduct(inc.data);
        const imgs = normalizeImageArray(inc?.data?.image, imageBaseUrl);
        setGallery(imgs.length ? imgs : [fallbackHero]);
        setLoading(false);
        return;
      } catch {
        try {
          const res = await API.get(`/productDetailByProduct/${id}`);
          if (!alive) return;
          setProduct(res.data);
          const imgs = normalizeImageArray(res?.data?.image, imageBaseUrl);
          setGallery(imgs.length ? imgs : [fallbackHero]);
          setLoading(false);
        } catch (e) {
          if (!alive) return;
          console.error("Failed to load product:", e);
          setErr("Unable to load product.");
          setLoading(false);
        }
      }
    };

    doFetch();
    return () => {
      alive = false;
    };
  }, [slug, imageBaseUrl]);

  useEffect(() => {
    if (!product) return;
    const title = product.name || "Product";
    const desc = makeDescription(product.description, product.name);
    const img = gallery[0];
    const url =
      typeof window !== "undefined"
        ? `${window.location.origin}/product/${encodeURIComponent(slug)}`
        : "";

    if (typeof document !== "undefined") document.title = title;
    upsertMeta("name", "description", desc);
    upsertMeta("property", "og:type", "product");
    upsertMeta("property", "og:title", title);
    upsertMeta("property", "og:description", desc);
    upsertMeta("property", "og:image", img);
    upsertMeta("property", "og:url", url);
    upsertMeta("name", "twitter:card", "summary_large_image");
    upsertMeta("name", "twitter:title", title);
    upsertMeta("name", "twitter:description", desc);
    upsertMeta("name", "twitter:image", img);
  }, [product, gallery, slug]);

  /* --------------------------- cart actions --------------------------- */

  const handleAddToCart = () => {
    if (!product) return;
    const img =
      (Array.isArray(product.image) && product.image[0]
        ? `${imageBaseUrl}${product.image[0]}`
        : gallery[0]) || fallbackHero;

    addToCart({
      id: product.id,
      name: product.name,
      price: parseFloat(product.price) || 0,
      quantity: 1,
      image: img,
    });
  };

  const buyNowToCart = () => {
    handleAddToCart();
    navigate("/cart");
  };

  /* --------------------------- contact & share --------------------------- */

  // current page URL (single definition)
  const currentUrl = typeof window !== "undefined" ? window.location.href : "";

  // Telegram contact button with prefilled message (including link)
  const TELEGRAM_USERNAME = "Sok_heng1688";
  const contactTelegram = () => {
    const title = product?.name || "this product";
    const price = product?.price ? `$${fmtMoney(product.price)}` : "";
    const message = `Hello, I'm interested in: ${title}${price ? ` — ${price}` : ""}\n${currentUrl}`;
    const tgUrl = `https://t.me/${TELEGRAM_USERNAME}?text=${encodeURIComponent(message)}`;
    window.open(tgUrl, "_blank", "noopener,noreferrer");
  };

  const shareText = product?.name
    ? `${product.name} — $${fmtMoney(product.price)}`
    : "Check this out";

  const openShare = (url) => window.open(url, "_blank", "noopener,noreferrer");

  const shareFacebook = () =>
    openShare(`https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(currentUrl)}`);

  const shareX = () =>
    openShare(
      `https://twitter.com/intent/tweet?url=${encodeURIComponent(currentUrl)}&text=${encodeURIComponent(
        shareText
      )}`
    );

  // Instagram & TikTok → copy link
  const copyLink = async () => {
    try {
      await navigator.clipboard.writeText(currentUrl);
      setCopied(true);
      setTimeout(() => setCopied(false), 1800);
    } catch {
      window.prompt("Copy this link:", currentUrl);
    }
  };
  const shareInstagram = copyLink;
  const shareTikTok = copyLink;

  /* ---------------------------- modal handlers ---------------------------- */

  const openModal = (img) => {
    const index = gallery.findIndex((g) => g === img);
    setCurrentImageIndex(index >= 0 ? index : 0);
    setShow(true);
  };
  const closeModal = () => setShow(false);
  const goToNext = () =>
    setCurrentImageIndex((i) => (i === gallery.length - 1 ? 0 : i + 1));
  const goToPrev = () =>
    setCurrentImageIndex((i) => (i === 0 ? gallery.length - 1 : i - 1));

  /* -------------------------------- render -------------------------------- */

  return (
    <MasterLayout>
      <Container className="py-4">
        {loading ? (
          <div className="d-flex justify-content-center align-items-center py-5">
            <Spinner animation="border" role="status" className="me-2" />
            <span>Loading product…</span>
          </div>
        ) : err ? (
          <div className="text-center py-5">
            <h5 className="mb-3">{err}</h5>
            <Button variant="dark" onClick={() => navigate("/")}>
              Back to Home
            </Button>
          </div>
        ) : (
          <Row>
            {/* Mobile gallery */}
            <Col xs={12} className="d-block d-md-none mb-4">
              <Carousel interval={null} className="shadow-sm rounded">
                {gallery.map((img, index) => (
                  <Carousel.Item key={index}>
                    <div
                      style={{ position: "relative", cursor: "pointer" }}
                      onClick={() => openModal(img)}
                    >
                      <img
                        src={img}
                        alt={`Slide ${index}`}
                        className="d-block w-100"
                        style={{ objectFit: "cover", height: "300px", borderRadius: "12px" }}
                      />
                      <Icon
                        icon="mdi:magnify"
                        width={24}
                        className="position-absolute"
                        style={{
                          top: 10,
                          right: 10,
                          color: "#000",
                          background: "#fff",
                          borderRadius: "50%",
                          padding: "5px",
                        }}
                      />
                    </div>
                  </Carousel.Item>
                ))}
              </Carousel>
            </Col>

            {/* Desktop gallery */}
            <Col md={6} className="d-none d-md-block">
              <Row className="g-3">
                {gallery.map((img, index) => (
                  <Col xs={index === 0 ? 12 : 6} key={index} className="position-relative">
                    <img
                      src={img}
                      className="w-100 rounded shadow-sm"
                      style={{ cursor: "pointer" }}
                      alt={`Product ${index}`}
                      onClick={() => openModal(img)}
                    />
                    <Icon
                      icon="mdi:magnify"
                      width="24"
                      className="position-absolute"
                      style={{
                        top: 10,
                        right: 10,
                        color: "#000",
                        background: "#fff",
                        borderRadius: "50%",
                        padding: "5px",
                        cursor: "pointer",
                      }}
                      onClick={() => openModal(img)}
                    />
                  </Col>
                ))}
              </Row>
            </Col>

            {/* Detail */}
            <Col md={6}>
              <h5 className="fw-bold">{product?.name ?? "…"}</h5>
              <p className="fs-5">
                Price:{" "}
                <span className="bg-success-focus px-1 rounded-2 fw-medium text-success-main">
                  {fmtMoney(product?.price)}
                </span>{" "}
                $
              </p>

              <div className="d-flex gap-2 mb-3">
                <Button variant="outline-dark" className="w-50" onClick={handleAddToCart}>
                  Add to cart
                </Button>
                <Button onClick={buyNowToCart} variant="dark" className="w-50 btn btn-dark">
                  Buy it now
                </Button>
              </div>

              {/* ---------- CONTACT & SHARE ---------- */}
              <div className="mb-4">
                {/* BIG contact button */}
                <Button
                  onClick={contactTelegram}
                  className="w-100 d-flex align-items-center justify-content-center gap-2 py-2"
                  style={{ background: "#2AABEE", borderColor: "#2AABEE" }}
                >
                  <img src={TeleFOng} alt="Telegram" style={{ width: 22, height: 22 }} />
                  <span>Contact • ទំនាក់ទំនងទិញ (Telegram)</span>
                </Button>

                {/* Small icons row */}
                <div className="d-flex align-items-center gap-2 flex-wrap mt-3">
                  <button
                    className="btn btn-light rounded-circle p-2 shadow-sm"
                    onClick={shareFacebook}
                    title="Share to Facebook"
                  >
                    <Icon icon="mdi:facebook" width="20" />
                  </button>

                  <button
                    className="btn btn-light rounded-circle p-2 shadow-sm"
                    onClick={shareX}
                    title="Share to X"
                  >
                    <Icon icon="mdi:twitter" width="20" />
                  </button>

                  <button
                    className="btn btn-light rounded-circle p-2 shadow-sm"
                    onClick={shareInstagram}
                    title="Share to Instagram (copy link)"
                  >
                    <Icon icon="mdi:instagram" width="20" />
                  </button>

                  <button
                    className="btn btn-light rounded-circle p-2 shadow-sm"
                    onClick={shareTikTok}
                    title="Share to TikTok (copy link)"
                  >
                    <Icon icon="ri:tiktok-fill" width="20" />
                  </button>

                  <button
                    className="btn btn-outline-secondary rounded-pill px-3 py-1"
                    onClick={copyLink}
                    title="Copy link"
                  >
                    <Icon icon="mdi:content-copy" width="18" />
                    <span className="ms-1">Copy link</span>
                  </button>

                  {copied && <span className="text-success small ms-1">Copied!</span>}
                </div>
              </div>
              {/* ---------- /CONTACT & SHARE ---------- */}

              <RichDescription
                className="bg-white p-3 rounded-3 mb-4 shadow-sm"
                htmlOrText={product?.description || ""}
              />
            </Col>
          </Row>
        )}

        {/* Zoom modal */}
        <Modal
          show={show}
          onHide={closeModal}
          centered
          size="lg"
          contentClassName="bg-transparent border-0"
        >
          <Modal.Body className="p-0 position-relative d-flex align-items-center justify-content-center">
            <Button
              variant="light"
              onClick={goToPrev}
              className="position-absolute start-0"
              style={{ top: "50%", transform: "translateY(-50%)", zIndex: 1051, borderRadius: "30%", fontSize: "20px" }}
            >
              <Icon icon="mdi:chevron-left" />
            </Button>
            <img
              src={gallery[currentImageIndex]}
              alt="Zoomed"
              className="w-100 rounded-3 shadow"
              style={{ maxHeight: "90vh", objectFit: "contain" }}
            />
            <Button
              variant="light"
              onClick={goToNext}
              className="position-absolute end-0"
              style={{ top: "50%", transform: "translateY(-50%)", zIndex: 1051, borderRadius: "30%", fontSize: "20px" }}
            >
              <Icon icon="mdi:chevron-right" />
            </Button>
            <Button
              variant="light"
              onClick={closeModal}
              className="position-absolute top-0 end-0 m-2"
              style={{ borderRadius: "30%", fontSize: "20px", zIndex: 1052 }}
            >
              <Icon icon="mdi:close" />
            </Button>
          </Modal.Body>
        </Modal>
      </Container>
    </MasterLayout>
  );
};

export default ProductDetail;
