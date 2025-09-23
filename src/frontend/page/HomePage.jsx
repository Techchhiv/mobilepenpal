import React, { useEffect, useRef, useState } from "react";
import useReactApexChart from "../../hook/useReactApexChart";
import { Icon } from "@iconify/react";
import { Link } from "react-router-dom";
import "../components/style.css";
import API from "../../helper/api";
import API_BASE_URL from "../../helper/Base_urls";
import { IoIosEye } from "react-icons/io";
import { FaCartPlus } from "react-icons/fa6";
import { MdFavoriteBorder, MdOutlineFavorite } from "react-icons/md";
import { useFavorite } from "../../context/FavoriteContext";
import LogoLoader from "../../helper/LogoLoader";
import Seo from "../components/Seo";

const slugify = (name = "", id) => {
  const base = String(name)
    .normalize("NFKD")
    .toLowerCase()
    .trim()
    .replace(/[\s_]+/g, "-")
    .replace(/[^\p{L}\p{N}-]+/gu, "")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");
  return `${base || "item"}-${id}`;
};
const getSafeSlug = (p) => {
  const s = (p.slug ?? "").trim();
  return s.length ? s : slugify(p.name, p.id);
};

export default function HomePage() {
  let { createChart } = useReactApexChart();

  const [showDropdown, setShowDropdown] = useState(false);
  const [minPrice, setMinPrice] = useState("");
  const [maxPrice, setMaxPrice] = useState("");
  const [showMobileFilter, setShowMobileFilter] = useState(false);
  const [showMobileSort, setShowMobileSort] = useState(false);

  const desktopDropdownRef = useRef(null);
  const mobileFilterRef = useRef(null);
  const mobileSortRef = useRef(null);

  const [products, setProducts] = useState([]);
  const [sortOption, setSortOption] = useState("Relevance");
  const { toggleFavorite, isFavorited } = useFavorite();
  const [loading, setLoading] = useState(true);

  const truncate = (text, desktopLimit = 50, mobileLimit = 30) => {
    if (!text) return "";
    const isMobile = window.innerWidth < 768;
    const limit = isMobile ? mobileLimit : desktopLimit;
    return text.length > limit ? text.slice(0, limit) + "..." : text;
  };

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

  useEffect(() => {
    (async () => {
      try {
        const res = await API.get("/products");
        setProducts(Array.isArray(res.data) ? res.data : []);
      } catch (e) {
        console.error(e);
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  useEffect(() => {
    const onDown = (e) => {
      if (desktopDropdownRef.current && !desktopDropdownRef.current.contains(e.target)) setShowDropdown(false);
      if (mobileFilterRef.current && !mobileFilterRef.current.contains(e.target)) setShowMobileFilter(false);
      if (mobileSortRef.current && !mobileSortRef.current.contains(e.target)) setShowMobileSort(false);
    };
    document.addEventListener("mousedown", onDown);
    return () => document.removeEventListener("mousedown", onDown);
  }, []);

  if (loading) return <LogoLoader />;

  return (
  <>
   <Seo
   title="ផ្សារលក់ឡានស្អាតៗ មានគុណភាព តម្លៃសមរម្យ"
        description="ស្វែងរកឡានថ្មី និងឡានចាស់គុណភាពល្អ តម្លៃសមរម្យ នៅកម្ពុជា។"
        canonical="/"
        image="https://sambatpsalan.com/static/media/cover.09f6ce551469fb2ace96.jpg" 
   />
     <div className="col-xxl-12 container">
      {/* Filters */}
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
      <div className="row gy-4 mx0 mt-2">
        {filtered.length ? (
          filtered.map((product) => {
            const imgSrc =
              Array.isArray(product.image) && product.image[0]
                ? `${API_BASE_URL}/storage/${product.image[0]}`
                : `${API_BASE_URL}/assets/images/og-default.jpg`;

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
                        onError={(e) => (e.currentTarget.src = `${API_BASE_URL}/assets/images/og-default.jpg`)}
                      />
                      <button
                        className="fav-btn"
                        onClick={(e) => {
                          e.preventDefault();
                          toggleFavorite(product);
                        }}
                        aria-label={isFavorited(product.id) ? "Unfavorite" : "Favorite"}
                      >
                        {isFavorited(product.id)
                          ? <MdOutlineFavorite size={22} color="#dc3545" />
                          : <MdFavoriteBorder size={22} color="#dc3545" />}
                      </button>
                    </div>
                  </Link>

                  <div className="px-3 py-3">
                    <p className="mb-2 fw-semibold product-title">{truncate(product.name, 60, 38)}</p>

                    <div className="d-flex align-items-center gap-2 mb-2">
                      <span className="price-chip">{Number(product.price).toLocaleString()}</span>
                      <span className="text-muted">$</span>
                    </div>

                    <p className="align-items-center d-flex text-sm m-0 mb-1">
                      <IoIosEye />
                      <span className="ms-2">
                        {product.view_count ?? 0} <span className="ms-1">people</span>
                      </span>
                    </p>
                    <p className="align-items-center d-flex text-sm m-0">
                      <FaCartPlus />
                      <span className="ms-2">{product.category?.name || "Unknown Category"}</span>
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
  </>
  );
}
