import React, { useEffect, useRef, useState } from "react";
import hljs from "highlight.js";
import ReactQuill from "react-quill-new";
import { useNavigate, useParams } from "react-router-dom";
import API from "../helper/api";
import API_BASE_URL from "../helper/Base_urls";

const EditProductLayer = () => {
  const { id } = useParams();

  const [name, setName] = useState("");
  const [categories, setCategories] = useState([]);
  const [price, setPrice] = useState("");
  const [description, setDescription] = useState("");
  const [message, setMessage] = useState("");
  const [category_id, setCategory_id] = useState("");
  const [status, setStatus] = useState("1"); // keep as "1"/"0" for the select
  const navigate = useNavigate();

  const [filePreviews, setFilePreviews] = useState([]); // JS arrays, no TS generics
  const [selectedFiles, setSelectedFiles] = useState([]);

  const handleFileChange = (e) => {
    const files = Array.from(e.target.files || []);
    setSelectedFiles((prev) => [...prev, ...files]);
    const previewUrls = files.map((f) => URL.createObjectURL(f));
    setFilePreviews((prev) => [...prev, ...previewUrls]);
    e.target.value = null; // allow re-selecting same files
  };

  const handleRemoveImage = (index) => {
    setFilePreviews((prev) => prev.filter((_, i) => i !== index));
    setSelectedFiles((prev) => prev.filter((_, i) => i !== index));
  };

  const updateProduct = async (e) => {
    e.preventDefault();
    try {
      const formData = new FormData();
      formData.append("name", name);
      formData.append("price", String(parseFloat(price || "0")));
      formData.append("description", description);
      formData.append("category_id", String(category_id));
      formData.append("status", status === "1" ? "1" : "0"); // send 1/0

      selectedFiles.forEach((file) => {
        formData.append("image[]", file); // matches backend (image.*)
      });

      const res = await API.post(`/admin/products/${id}?_method=PUT`, formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });

      setMessage(`Product "${res.data.name}" updated successfully!`);
      navigate("/table-data");
    } catch (error) {
      setMessage("Error updating product");
      console.error("Submission Error:", error?.response?.data || error.message);
    }
  };

  const fetchProduct = async () => {
    try {
      const { data } = await API.get(`/products/${id}`);
      setName(data.name ?? "");
      setPrice(String(data.price ?? ""));
      setDescription(data.description ?? "");
      setCategory_id(String(data.category_id ?? ""));
      setStatus(data.status ? "1" : "0"); // normalize to "1"/"0"

      if (Array.isArray(data.image) && data.image.length) {
        const baseUrl = `${API_BASE_URL}/storage/`;
        setFilePreviews(data.image.map((p) => `${baseUrl}${p}`));
      }
    } catch (error) {
      setMessage("Error fetching product");
      console.error(error);
    }
  };

  const fetchCategories = async () => {
    try {
      const { data } = await API.get("/categories"); // baseURL already includes /api
      setCategories(data);
    } catch (error) {
      setMessage("Error fetching categories");
      console.error(error);
    }
  };

  useEffect(() => {
    fetchCategories();
    fetchProduct();
  }, []);

  // (Optional) Quill syntax highlight config — safe even if hljs not styled
  const quillRef = useRef(null);
  useEffect(() => {
    hljs?.configure({
      languages: ["javascript", "ruby", "python", "java", "csharp", "cpp", "go", "php", "swift"],
    });
  }, []);
  const modules = { toolbar: { container: "#toolbar-container" } };
  const formats = [
    "font","size","bold","italic","underline","strike","color","background","script","header","blockquote","code-block",
    "list","indent","direction","align","link","image","video","formula",
  ];

  return (
    <div className="row gy-4">
      <form onSubmit={updateProduct}>
        <div className="col-lg-8">
          <div className="card mt-24">
            <div className="card-header border-bottom">
              <h6 className="text-xl mb-0">Add New Product</h6>
            </div>

            <div className="card-body p-24">
              <div>
                <label className="form-label fw-bold text-neutral-900" htmlFor="title">Post Title:</label>
                <input
                  type="text"
                  className="form-control border border-neutral-200 radius-8"
                  id="title"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Enter Post Title"
                />
              </div>

              <div>
                <label className="form-label fw-bold text-neutral-900">Post Category:</label>
                <select
                  className="form-control border border-neutral-200 radius-8"
                  value={category_id}
                  onChange={(e) => setCategory_id(e.target.value)}
                >
                  <option value="">Select category</option>
                  {categories.map((c) => (
                    <option key={c.id} value={c.id}>{c.name}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="form-label fw-bold text-neutral-900">Pricing:</label>
                <input
                  type="number"
                  className="form-control border border-neutral-200 radius-8"
                  style={{ width: 300 }}
                  id="Pricing"
                  value={price}
                  onChange={(e) => setPrice(e.target.value)}
                  placeholder="Enter pricing"
                />
              </div>

              <div>
                <label className="form-label fw-bold text-neutral-900">Post Description</label>
                <div className="border border-neutral-200 radius-8 overflow-hidden">
                  <div className="height-200">
                    <div id="toolbar-container" />
                    <ReactQuill
                      ref={quillRef}
                      theme="snow"
                      value={description}
                      onChange={setDescription}
                      modules={modules}
                      formats={formats}
                      placeholder="Compose an epic..."
                    />
                  </div>
                </div>
              </div>

              <div>
                <label className="form-label fw-bold text-neutral-900">Upload Media</label>
                <div className="upload-image-wrapper">
                  {filePreviews.length > 0 ? (
                    filePreviews.map((file, index) => (
                      <div key={index} className="uploaded-img position-relative h-160-px w-100 border input-form-light radius-8 overflow-hidden border-dashed bg-neutral-50">
                        <button
                          type="button"
                          className="uploaded-img__remove position-absolute top-0 end-0 z-1 me-8 mt-8 d-flex bg-danger-600 w-40-px h-40-px justify-content-center align-items-center rounded-circle"
                          onClick={() => handleRemoveImage(index)}
                        >
                          <iconify-icon icon="radix-icons:cross-2" className="text-2xl text-white" />
                        </button>
                        <img className="w-100 h-100 object-fit-cover" src={file} alt={`Uploaded-${index}`} />
                      </div>
                    ))
                  ) : (
                    <label
                      className="upload-file h-160-px w-100 border input-form-light radius-8 overflow-hidden border-dashed bg-neutral-50 bg-hover-neutral-200 d-flex align-items-center flex-column justify-content-center gap-1"
                      htmlFor="upload-file"
                    >
                      <iconify-icon icon="solar:camera-outline" className="text-xl text-secondary-light" />
                      <span className="fw-semibold text-secondary-light">Upload</span>
                      <input
                        id="upload-file"
                        type="file"
                        hidden
                        name="image[]"
                        accept="image/*"
                        multiple
                        onChange={handleFileChange}
                      />
                    </label>
                  )}
                </div>
              </div>

              <div className="mt-24">
                <label className="form-label fw-bold text-neutral-900">Status:</label>
                <select
                  className="form-control border border-neutral-200 radius-8"
                  value={status}
                  onChange={(e) => setStatus(e.target.value)}
                >
                  <option value="1">Active</option>
                  <option value="0">Inactive</option>
                </select>
              </div>

              <button type="submit" className="btn btn-primary-600 radius-8 mt-3">
                Update Product
              </button>

              {message && <p className="mt-12">{message}</p>}
            </div>
          </div>
        </div>
      </form>
    </div>
  );
};

export default EditProductLayer;
