// src/frontend/page/Product.jsx
import React, { useEffect, useRef, useState } from "react";
import { Icon } from "@iconify/react";
import { useParams, Link } from "react-router-dom";
import "../components/style.css";
import API from "../../helper/api";
import API_BASE_URL from "../../helper/Base_urls";
import { IoIosEye } from "react-icons/io";
import { FaCartPlus } from "react-icons/fa6";
import { MdFavoriteBorder, MdOutlineFavorite } from "react-icons/md";
import { useFavorite } from "../../context/FavoriteContext";
import MasterLayout from "../masterLayout/MasterLayout";

/* helpers */
const nameToSlug = (name = "") =>
  String(name)
    .normalize("NFKD")
    .toLowerCase()
    .trim()
    .replace(/[\s_]+/g, "-")
    .replace(/[^\p{L}\p{N}-]+/gu, "")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");

const slugify = (name = "", id) => {
  const base = nameToSlug(name);
  return `${base || "item"}-${id}`;
};
const getSafeSlug = (p) => {
  const s = (p?.slug ?? "").trim();
  return s.length ? s : slugify(p?.name, p?.id);
};

const pickImageUrl = (image) => {
  try {
    if (typeof image === "string" && image.startsWith("[")) image = JSON.parse(image);
  } catch {}
  if (typeof image === "string" && image) return `${API_BASE_URL}/storage/${image}`;
  if (Array.isArray(image) && image.length) {
    const first = image[0];
    if (typeof first === "string") return `${API_BASE_URL}/storage/${first}`;
    if (typeof first === "object") {
      if (first?.url) return first.url;
      if (first?.path) return `${API_BASE_URL}/storage/${first.path}`;
    }
  }
  return `${API_BASE_URL}/assets/images/og-default.jpg`;
};

const truncate = (text = "", desktopLimit = 60, mobileLimit = 38) => {
  const isMobile = typeof window !== "undefined" && window.innerWidth < 768;
  const limit = isMobile ? mobileLimit : desktopLimit;
  return text.length > limit ? text.slice(0, limit) + "…" : text;
};

export default function Product() {
  const { slug } = useParams(); // /category/:slug
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [sortOption, setSortOption] = useState("Relevance");
  const [minPrice, setMinPrice] = useState("");
  const [maxPrice, setMaxPrice] = useState("");
  const [showDropdown, setShowDropdown] = useState(false);
  const desktopDropdownRef = useRef(null);
  const { toggleFavorite, isFavorited } = useFavorite();

  useEffect(() => {
    let aborted = false;

    (async () => {
      setLoading(true);

      try {
        // ✅ Only use categories to resolve slug → id (works for Khmer/Latin)
        const cats = await API.get("/categories");
        if (aborted) return;

        const list = Array.isArray(cats.data) ? cats.data : [];
        const target = decodeURIComponent(slug ?? "").trim().toLowerCase();

        const match = list.find((c) => {
          const s = (c.slug ?? nameToSlug(c.name ?? "")).toLowerCase();
          return s === target;
        });

        if (match?.id) {
          const res = await API.get(`/productsByCategory/${match.id}`);
          if (!aborted) setProducts(Array.isArray(res.data) ? res.data : []);
        } else if (!aborted) {
          setProducts([]);
        }
      } catch (e) {
        if (!aborted) setProducts([]);
        console.error("Category/Products fetch failed:", e);
      } finally {
        if (!aborted) setLoading(false);
      }
    })();

    return () => {
      aborted = true;
    };
  }, [slug]);

  const filtered = React.useMemo(() => {
    let list = [...products];
    if (minPrice !== "") list = list.filter((p) => +p.price >= +minPrice);
    if (maxPrice !== "") list = list.filter((p) => +p.price <= +maxPrice);
    switch (sortOption) {
      case "Price Low to High":
        list.sort((a, b) => +a.price - +b.price);
        break;
      case "Price High to Low":
        list.sort((a, b) => +b.price - +a.price);
        break;
      case "Newest":
        list.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
        break;
      default:
        break;
    }
    return list;
  }, [products, minPrice, maxPrice, sortOption]);

  return (
    <MasterLayout>
      <div className="col-xxl-12 container">
        {/* Filters header */}
        <div className="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3 position-relative">
          <div className="d-none d-md-flex align-items-center flex-wrap gap-3">
            <span>Filter:</span>
            <div className="position-relative">
              <p
                onClick={() => setShowDropdown(!showDropdown)}
                className="mb-0 cursor-pointer d-flex align-items-center gap-1 text-decoration-none"
                style={{ textDecoration: showDropdown ? "underline" : "none" }}
              >
                Price
                <Icon icon="material-symbols-light:keyboard-arrow-down-rounded" width="20" height="20" />
              </p>
              {showDropdown && (
                <div
                  ref={desktopDropdownRef}
                  className="position-absolute bg-white border rounded shadow p-3 mt-2"
                  style={{ minWidth: "260px", zIndex: 1050 }}
                >
                  <button
                    onClick={() => {
                      setMinPrice("");
                      setMaxPrice("");
                    }}
                    className="btn p-0 mb-2 text-primary text-decoration-underline border-0 bg-transparent"
                  >
                    Reset
                  </button>
                  <div className="d-flex align-items-center gap-2">
                    <span className="text-muted">$</span>
                    <input
                      type="number"
                      placeholder="Min"
                      value={minPrice}
                      onChange={(e) => setMinPrice(e.target.value)}
                      className="form-control"
                    />
                    <span className="text-muted">$</span>
                    <input
                      type="number"
                      placeholder="Max"
                      value={maxPrice}
                      onChange={(e) => setMaxPrice(e.target.value)}
                      className="form-control"
                    />
                  </div>
                </div>
              )}
            </div>
          </div>

          <div className="d-none d-md-flex align-items-center gap-2">
            <span>Sort by:</span>
            <select
              className="form-select form-select-sm w-auto border"
              value={sortOption}
              onChange={(e) => setSortOption(e.target.value)}
            >
              <option>Relevance</option>
              <option>Newest</option>
              <option>Price Low to High</option>
              <option>Price High to Low</option>
            </select>
            <span>{loading ? "Loading…" : `${filtered.length} Products`}</span>
          </div>
        </div>

        {/* Grid */}
        <div className="row gy-2 gy-md-4 mx0 mt-2 product-grid">
          {loading ? (
            <div className="text-center py-5">Loading…</div>
          ) : filtered.length ? (
            filtered.map((product) => {
              const imgSrc = pickImageUrl(product.image);
              const to = `/product/${encodeURIComponent(getSafeSlug(product))}`;

              return (
                <div className="col-6 col-md-4 col-lg-3" key={product.id}>
                  <div className="product-card border bg-white h-100 shadow-sm">
                    <Link to={to} className="text-decoration-none text-dark">
                      <div className="img-wrap">
                        <img
                          src={imgSrc}
                          alt={product.name || "Product"}
                          loading="lazy"
                          onError={(e) => {
                            e.currentTarget.src = `${API_BASE_URL}/assets/images/og-default.jpg`;
                          }}
                          style={{ width: "100%", height: "100%", objectFit: "cover", display: "block" }}
                        />
                        <button
                          className="fav-btn"
                          onClick={(e) => {
                            e.preventDefault();
                            toggleFavorite(product);
                          }}
                          aria-label={isFavorited(product.id) ? "Unfavorite" : "Favorite"}
                        >
                          {isFavorited(product.id) ? (
                            <MdOutlineFavorite size={22} color="#dc3545" />
                          ) : (
                            <MdFavoriteBorder size={22} color="#dc3545" />
                          )}
                        </button>
                      </div>
                    </Link>

                    <div className="px-3 py-3">
                      <p className="mb-2 fw-semibold product-title">
                        {truncate(product.name, 60, 38)}
                      </p>

                      <div className="d-flex align-items-center gap-2 mb-2">
                        <span className="price-chip">
                          {Number(product.price).toLocaleString()}
                        </span>
                        <span className="text-muted">$</span>
                      </div>

                      <p className="align-items-center d-flex text-sm m-0 mb-1">
                        <IoIosEye />
                        <span className="ms-2">
                          {product.view_count ?? 0}
                          <span className="ms-1">people</span>
                        </span>
                      </p>
                      <p className="align-items-center d-flex text-sm m-0">
                        <FaCartPlus />
                        <span className="ms-2">
                          {product.category?.name || "Unknown Category"}
                        </span>
                      </p>
                    </div>
                  </div>
                </div>
              );
            })
          ) : (
            <div className="text-center">
              <h4>No Products Found</h4>
            </div>
          )}
        </div>
      </div>
    </MasterLayout>
  );
}
