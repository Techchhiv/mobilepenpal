import React from "react";
import { Link } from "react-router-dom";
import { useFavorite } from "../../context/FavoriteContext";
import { MdOutlineFavorite, MdFavoriteBorder } from "react-icons/md";
import { IoIosEye } from "react-icons/io";
import { FaCartPlus } from "react-icons/fa6";
import MasterLayout from "../masterLayout/MasterLayout";
import API_BASE_URL from "../../helper/Base_urls";

/** Fallback slug builder if API doesn't send product.slug */
const slugify = (name = "", id) => {
  const base = String(name)
    .toLowerCase()
    .trim()
    .replace(/[\s_]+/g, "-")        // spaces/underscores -> dash
    .replace(/[^a-z0-9-]/g, "")     // strip non-url chars
    .replace(/-+/g, "-")            // collapse dashes
    .replace(/^-|-$/g, "");         // trim dashes
  return id ? `${base}-${id}` : base;
};

const Favorite = () => {
  const { favorites, toggleFavorite, isFavorited } = useFavorite();

  const truncate = (text, desktopLimit = 50, mobileLimit = 30) => {
    const isMobile = typeof window !== "undefined" && window.innerWidth < 768;
    const limit = isMobile ? mobileLimit : desktopLimit;
    return (text || "").length > limit ? text.slice(0, limit) + "..." : text || "";
  };

  /** Build SEO detail link: /product-detail/:slug */
  const productDetailLink = (p) => `/product-detail/${p.slug || slugify(p.name, p.id)}`;

  return (
    <MasterLayout>
      <div className="container py-4">
        <h4 className="mb-4">Your Favorite Products</h4>

        <div className="row gy-4 mx0">
          {favorites.length > 0 ? (
            favorites.map((product) => {
              const firstImage =
                Array.isArray(product.image) && product.image[0]
                  ? `${API_BASE_URL}/storage/${product.image[0]}`
                  : "/assets/images/placeholder.png"; // optional fallback

              return (
                <div className="col-6 col-md-4 col-lg-3" key={product.id}>
                  <div className="card-0 overflow-hidden radius-8 border h-100 bg-white position-relative">
                    <Link to={productDetailLink(product)} className="text-decoration-none text-dark">
                      <div className="product-image-wrapper position-relative">
                        <img
                          src={firstImage}
                          className="product-image w-100 h-100 object-fit-cover"
                          alt={product.name || "Product"}
                        />

                        {/* Favorite toggle */}
                        <button
                          className="btn btn-light position-absolute top-0 end-0 m-2 p-1 rounded-circle shadow-sm"
                          onClick={(e) => {
                            e.preventDefault(); // prevent link navigation
                            toggleFavorite(product);
                          }}
                          aria-label={isFavorited(product.id) ? "Remove favorite" : "Add favorite"}
                        >
                          {isFavorited(product.id) ? (
                            <MdOutlineFavorite size={22} color="#dc3545" />
                          ) : (
                            <MdFavoriteBorder size={22} color="#dc3545" />
                          )}
                        </button>
                      </div>
                    </Link>

                    <div className="card-body px-3">
                      <p style={{ fontSize: typeof window !== "undefined" && window.innerWidth < 768 ? "12px" : "1rem" }}>
                        {truncate(product.name)}
                      </p>

                      <p className="fs-6 fs-md-5 m-0">
                        <span className="bg-success-focus text-lg rounded-2 fw-medium text-danger-main">
                          {product.price}
                        </span>{" "}
                        $
                      </p>

                      <p className="align-items-center d-flex text-sm m-0">
                        <IoIosEye />
                        <span className="ms-2">
                          {product.view_count ?? 0}
                          <span className="ms-2">people</span>
                        </span>
                      </p>

                      <p className="align-items-center d-flex me-2 text-sm">
                        <FaCartPlus />
                        <span className="ms-2">{product.category?.name || "Unknown Category"}</span>
                      </p>
                    </div>
                  </div>
                </div>
              );
            })
          ) : (
            <div className="text-center col-12">
              <h5>No favorite products yet.</h5>
            </div>
          )}
        </div>
      </div>
    </MasterLayout>
  );
};

export default Favorite;
