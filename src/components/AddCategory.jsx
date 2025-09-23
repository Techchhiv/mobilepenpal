import React, { useEffect, useState } from "react";
import $ from "jquery";
import "datatables.net-dt/js/dataTables.dataTables.js";
import { Icon } from "@iconify/react/dist/iconify.js";
import { Link } from "react-router-dom";
import API from "../helper/api";
import { useAuth } from "../context/AuthContext";

const AddCategory = () => {
  const { hasPermission, hasAnyPermission } = useAuth();

  // ---- permissions we’ll use here
  const canView   = hasPermission("category.view");
  const canCreate = hasPermission("category.create");
  const canUpdate = hasPermission("category.update");
  const canDelete = hasPermission("category.delete");
  const canSeeActions = hasAnyPermission(["category.update", "category.delete"]);

  const [message, setMessage] = useState("");
  const [name, setName] = useState("");
  const [categories, setCategories] = useState([]);
  const [editId, setEditId] = useState(null);

  const fetchCategories = async () => {
    if (!canView) return;
    try {
      const res = await API.get("/categories"); // public list
      setCategories(Array.isArray(res.data) ? res.data : res.data?.data ?? []);
    } catch (error) {
      setMessage("Failed to load categories");
      console.error(error);
    }
  };

  useEffect(() => {
    fetchCategories();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [canView]);

  const createCategory = async (e) => {
    e.preventDefault();
    if (!canCreate) return; // extra guard
    try {
      const res = await API.post("/admin/categories", { name });
      setMessage(`Category "${res.data.name}" created successfully!`);
      setName("");
      fetchCategories();
    } catch (error) {
      setMessage("Error creating category");
      console.error(error);
    }
  };

  const editCategory = (category) => {
    if (!canUpdate) return;
    setEditId(category.id);
    setName(category.name);
  };

  const updateCategory = async (e) => {
    e.preventDefault();
    if (!canUpdate) return;
    try {
      const res = await API.put(`/admin/categories/${editId}`, { name });
      setMessage(`Category "${res.data.name}" updated successfully!`);
      setName("");
      setEditId(null);
      fetchCategories();
    } catch (error) {
      setMessage("Error updating category");
      console.error(error);
    }
  };

  const deleteCategory = async (id) => {
    if (!canDelete) return;
    try {
      await API.delete(`/admin/categories/${id}`);
      setMessage(`Category deleted successfully!`);
      fetchCategories();
    } catch (error) {
      setMessage("Error deleting category");
      console.error(error);
    }
  };

  // No view permission → show a simple notice
  if (!canView) {
    return (
      <div className="card p-24">
        <h6 className="text-xl mb-8">Categories</h6>
        <p className="text-danger">You don’t have permission to view categories.</p>
      </div>
    );
  }

  return (
    <div className="row gy-4 basic-data-table">
      <div className="card col-lg-8 justify-content-center mx-auto">
        <div className="card-header">
          <h6 className="text-xl mb-0">Add New Category</h6>
        </div>

        <div className="card-body">
          {/* Create / Update form — shown only if user can create OR update */}
          {(canCreate || (editId && canUpdate)) && (
            <div className="mb-10">
              <form
                onSubmit={editId ? updateCategory : createCategory}
                className="d-flex flex-column gap-2"
              >
                <label className="form-label fw-bold text-neutral-900" htmlFor="name">
                  Category Title:
                </label>
                <input
                  type="text"
                  className="form-control border border-neutral-200 radius-8"
                  id="name"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  required
                  placeholder="Enter category name"
                />

                {editId ? (
                  <button
                    type="submit"
                    className="btn btn-primary-600 radius-8"
                    disabled={!canUpdate}
                  >
                    Update
                  </button>
                ) : (
                  <button
                    type="submit"
                    className="btn btn-primary-600 radius-8"
                    disabled={!canCreate}
                  >
                    Create
                  </button>
                )}
              </form>
            </div>
          )}

          {message && <p className="mb-12">{message}</p>}

          <table className="table bordered-table mb-0" id="dataTable" data-page-length={10}>
            <thead>
              <tr>
                <th scope="col">
                  <div className="form-check style-check d-flex align-items-center">
                    <label className="form-check-label">S.L</label>
                  </div>
                </th>
                <th scope="col">Name</th>
                {canSeeActions && <th scope="col">Action</th>}
              </tr>
            </thead>

            <tbody>
              {categories.length > 0 ? (
                categories.map((category, index) => (
                  <tr key={category.id || index}>
                    <td>
                      <div className="form-check style-check d-flex align-items-center">
                        <label className="form-check-label">{index + 1}</label>
                      </div>
                    </td>

                    <td>
                      <div className="d-flex align-items-center">
                        <img
                          src="assets/images/user-list/user-list1.png"
                          alt=""
                          className="flex-shrink-0 me-12 radius-8"
                        />
                        <h6 className="text-md mb-0 fw-medium flex-grow-1">
                          {category.name}
                        </h6>
                      </div>
                    </td>

                    {canSeeActions && (
                      <td>
                        {canUpdate && (
                          <Link
                            to="#"
                            onClick={() => editCategory(category)}
                            className="w-32-px h-32-px me-8 bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center"
                            title="Edit"
                          >
                            <Icon icon="lucide:edit" />
                          </Link>
                        )}
                        {canDelete && (
                          <Link
                            to="#"
                            onClick={() => deleteCategory(category.id)}
                            className="w-32-px h-32-px me-8 bg-danger-focus text-danger-main rounded-circle d-inline-flex align-items-center justify-content-center"
                            title="Delete"
                          >
                            <Icon icon="mingcute:delete-2-line" />
                          </Link>
                        )}
                      </td>
                    )}
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={canSeeActions ? 3 : 2} className="text-center py-3">
                    No data found
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default AddCategory;
