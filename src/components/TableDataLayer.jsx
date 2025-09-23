import React, { useEffect, useState } from "react";
import $ from "jquery";
import "datatables.net-dt/js/dataTables.dataTables.js";
import { Icon } from "@iconify/react";
import { Link } from "react-router-dom";
import API from "../helper/api";
import API_BASE_URL from "../helper/Base_urls";
import { useAuth } from "../context/AuthContext";

const TableDataLayer = () => {
  const { hasPermission, hasAnyPermission } = useAuth(); // ⬅️ use perms
  const [products, setProducts] = useState([]);
  const [message, setMessage] = useState("");

  const truncate = (text, limit = 20) =>
    text?.length > limit ? text.slice(0, limit) + "..." : text;

  const fetchProducts = async () => {
    try {
      const res = await API.get("/products"); // public GET is fine
      setProducts(res.data);
    } catch (error) {
      console.error(error);
    }
  };

  useEffect(() => { fetchProducts(); }, []);

  useEffect(() => {
    if (products.length > 0) {
      const table = $("#dataTable").DataTable({ destroy: true, pageLength: 10 });
      return () => table.destroy(true);
    }
  }, [products]);

  // show action col only if user has at least one action permission
  const canAnyRowAction = hasAnyPermission([
    "products.view",
    "products.update",
    "products.delete",
  ]);

  const deleteProduct = async (id) => {
    try {
      // 🔧 fixed stray space after `/`
      const res = await API.delete(`/admin/products/${id}`);
      // many APIs return 204 No Content for delete
      if (res.status === 200 || res.status === 204) {
        setMessage("Product deleted successfully");
        setProducts((prev) => prev.filter((p) => p.id !== id));
      }
    } catch (error) {
      if (error?.response?.status === 403) {
        setMessage("You don't have permission to delete products.");
      } else {
        setMessage("Delete failed.");
      }
      console.error(error);
    }
  };

  return (
    <div className="card basic-data-table">
      <div className="card-header d-flex justify-content-between align-items-center">
        <div className="text-success">{message}</div>

        {/* ⬇️ Only show Add button if user can create */}
        {hasPermission("products.create") && (
          <Link to="/add-blog">
            <button type="button" className="btn btn-primary-600 radius-3 px-20 py-11">
              Add
            </button>
          </Link>
        )}
      </div>

      <div className="card-body">
        <table className="table bordered-table mb-0" id="dataTable" data-page-length={10}>
          <thead>
            <tr>
              <th scope="col">
                <div className="form-check style-check d-flex align-items-center">
                  <label className="form-check-label">S.L</label>
                </div>
              </th>
              <th scope="col">Name</th>
              <th scope="col">Category</th>
              <th scope="col" className="dt-orderable-asc dt-orderable-desc">Price</th>
              <th scope="col">Status</th>

              {/* ⬇️ Hide Action column if no action permissions */}
              {canAnyRowAction && <th scope="col">Action</th>}
            </tr>
          </thead>

          <tbody>
            {products.map((product, index) => (
              <tr key={product.id}>
                <td>
                  <div className="form-check style-check d-flex align-items-center">
                    <input className="form-check-input" type="checkbox" />
                    <label className="form-check-label">{index + 1}</label>
                  </div>
                </td>

                <td>
                  <div className="d-flex align-items-center">
                    {Array.isArray(product.image) && product.image.length > 0 && (
                      <img
                        src={`${API_BASE_URL}/storage/${product.image[0]}`}
                        alt="Product"
                        style={{
                          width: 40, height: 40, objectFit: "cover", borderRadius: 8,
                        }}
                      />
                    )}

                    {/* Viewing the detail link also can be permission-gated, optional */}
                    {hasPermission("products.view") ? (
                      <Link to={`/products/${product.id}`} className="text-primary-600 ms-2">
                        {truncate(product.name)}
                      </Link>
                    ) : (
                      <span className="ms-2">{truncate(product.name)}</span>
                    )}
                  </div>
                </td>

                <td>
                  <h6 className="text-md mb-0 fw-medium">
                    {product.category?.name || "No category"}
                  </h6>
                </td>

                <td>${Number(product.price || 0).toFixed(2)}</td>

                <td>
                  <span
                    className={`px-24 py-4 rounded-pill fw-medium text-sm ${
                      product.status ? "bg-success-focus text-success-main" : "bg-danger-focus text-danger-main"
                    }`}
                  >
                    {product.status ? "Active" : "Inactive"}
                  </span>
                </td>

                {/* ⬇️ Render row actions only if allowed */}
                {canAnyRowAction && (
                  <td>
                    {hasPermission("products.view") && (
                      <Link
                        to={`/products/${product.id}`}
                        className="w-32-px h-32-px me-8 bg-primary-light text-primary-600 rounded-circle d-inline-flex align-items-center justify-content-center"
                        title="View"
                      >
                        <Icon icon="iconamoon:eye-light" />
                      </Link>
                    )}

                    {hasPermission("products.update") && (
                      <Link
                        to={`/edit-product/${product.id}`}
                        className="w-32-px h-32-px me-8 bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center"
                        title="Edit"
                      >
                        <Icon icon="lucide:edit" />
                      </Link>
                    )}

                    {hasPermission("products.delete") && (
                      <button
                        type="button"
                        onClick={() => deleteProduct(product.id)}
                        className="w-32-px h-32-px me-8 bg-danger-focus text-danger-main rounded-circle d-inline-flex align-items-center justify-content-center border-0"
                        title="Delete"
                      >
                        <Icon icon="mingcute:delete-2-line" />
                      </button>
                    )}
                  </td>
                )}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default TableDataLayer;
