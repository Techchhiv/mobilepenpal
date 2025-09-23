// src/frontend/components/SearchBar.jsx
import React, { useRef, useEffect, useState } from "react";
import { Search, X } from "lucide-react";
import { Link } from "react-router-dom";
import "./SearchBar.css";
import API from "../../helper/api";
import API_BASE_URL from "../../helper/Base_urls";

/* ---------------- helpers ---------------- */
const nameToSlug = (name = "") =>
  String(name)
    .normalize("NFKD")
    .toLowerCase()
    .trim()
    .replace(/[\s_]+/g, "-")
    .replace(/[^\p{L}\p{N}-]+/gu, "")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");

const productSlug = (p) => {
  const s = (p?.slug ?? "").trim();
  return s ? s : `${nameToSlug(p?.name || "item")}-${p?.id ?? ""}`;
};

const categorySlug = (c) => {
  const s = (c?.slug ?? "").trim();
  return s ? s : nameToSlug(c?.name || "category");
};

// Resolve product image into an absolute URL w/ fallbacks
const productThumb = (image) => {
  try {
    if (typeof image === "string" && image.startsWith("[")) image = JSON.parse(image);
  } catch {}
  if (typeof image === "string" && image) return `${API_BASE_URL}/storage/${image}`;
  if (Array.isArray(image) && image.length) {
    const first = image[0];
    if (typeof first === "string") return `${API_BASE_URL}/storage/${first}`;
    if (first?.url) return first.url;
    if (first?.path) return `${API_BASE_URL}/storage/${first.path}`;
  }
  return `${API_BASE_URL}/assets/images/og-default.jpg`;
};

const fetchWithFallback = async (paths) => {
  for (const path of paths) {
    try {
      const res = await API.get(path);
      if (res?.data) return res.data;
    } catch {}
  }
  return [];
};
/* ----------------------------------------- */

const SearchBar = ({ isOpen, onClose }) => {
  const [query, setQuery] = useState("");
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const inputRef = useRef(null);

  useEffect(() => {
    if (!isOpen) return;
    (async () => {
      const [prods, cats] = await Promise.all([
        fetchWithFallback(["/products", "api/products", "/api/products"]),
        fetchWithFallback(["/categories", "api/categories", "/api/categories"]),
      ]);
      setProducts(Array.isArray(prods) ? prods : []);
      setCategories(Array.isArray(cats) ? cats : []);
    })();
  }, [isOpen]);

  useEffect(() => {
    if (isOpen && inputRef.current) inputRef.current.focus();
  }, [isOpen]);

  useEffect(() => {
    const onEsc = (e) => e.key === "Escape" && onClose();
    if (isOpen) document.addEventListener("keydown", onEsc);
    return () => document.removeEventListener("keydown", onEsc);
  }, [isOpen, onClose]);

  const filteredSuggestions =
    query.trim().length > 0
      ? products
          .filter(
            (p) =>
              typeof p?.name === "string" &&
              p.name.toLowerCase().includes(query.toLowerCase())
          )
          .slice(0, 8)
      : [];

  const latestCategories = [...categories]
    .filter((c) => c?.id || c?.created_at || c?.createdAt)
    .sort((a, b) => {
      const ta = new Date(a.created_at || a.createdAt || a.id).getTime();
      const tb = new Date(b.created_at || b.createdAt || b.id).getTime();
      return tb - ta;
    })
    .slice(0, 6);

  if (!isOpen) return null;

  return (
    <div className="search-overlay" onClick={onClose}>
      <div className="search-container" onClick={(e) => e.stopPropagation()}>
        <div className="search-bar">
          <form onSubmit={(e) => e.preventDefault()}>
            <div className="search-input-wrapper">
              <Search size={20} className="search-icon" />
              <input
                ref={inputRef}
                type="text"
                placeholder="Search for products..."
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                className="search-input"
              />
              {query && (
                <button
                  type="button"
                  className="clear-button"
                  onClick={() => setQuery("")}
                  aria-label="Clear search"
                >
                  <X size={16} />
                </button>
              )}
            </div>
          </form>
        </div>

        {filteredSuggestions.length > 0 && (
          <div className="search-suggestions">
            <h5>Suggestions</h5>
            <ul className="suggestions-list">
              {filteredSuggestions.map((p) => {
                const img = productThumb(p.image);
                return (
                  <li key={p.id} className="suggestion-item">
                    <Link
                      to={`/product/${encodeURIComponent(productSlug(p))}`}
                      className="suggestion-button suggestion-with-thumb"
                      onClick={onClose}
                    >
                      <img
                        className="suggestion-thumb"
                        src={img}
                        alt={p.name || "Product"}
                        onError={(e) => {
                          e.currentTarget.src = `${API_BASE_URL}/assets/images/og-default.jpg`;
                        }}
                      />
                      <span className="suggestion-title">{p.name}</span>
                    </Link>
                  </li>
                );
              })}
            </ul>
          </div>
        )}

        <div className="popular-searches">
          <h5>Popular Searches</h5>
          <div className="popular-tags">
            {latestCategories.map((c) => (
              <Link
                key={c.id ?? c.slug ?? c.name}
                to={`/category/${encodeURIComponent(categorySlug(c))}`}
                className="popular-tag"
                onClick={onClose}
              >
                {c.name}
              </Link>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default SearchBar;
