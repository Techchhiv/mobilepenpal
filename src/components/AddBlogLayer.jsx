import React, { useEffect, useRef, useState } from "react";
import hljs from "highlight.js";
import ReactQuill from "react-quill-new";
import { Link, useNavigate } from "react-router-dom";
import API from "../helper/api";

const AddBlogLayer = () => {
  const [name, setName] = useState("");
  const [categories, setCategories] = useState([]);
  const [price, setPrice] = useState("");
  const [description, setDescription] = useState("");
  const [image, setImage] = useState("");
  const [message, setMessage] = useState("");
  const [category_id, setCategory_id] = useState("");
  const [status, setStatus] = useState("1"); // Default to Active
  const navigate = useNavigate();

  const [filePreviews, setFilePreviews] = useState([]);

 const [selectedFiles, setSelectedFiles] = useState([]); // store actual File objects

const handleFileChange = (e) => {
  const files = Array.from(e.target.files);
  setSelectedFiles((prevFiles) => [...prevFiles, ...files]);

  const previewUrls = files.map((file) => URL.createObjectURL(file));
  setFilePreviews((prev) => [...prev, ...previewUrls]);

  // Clear input value to allow selecting same file again if needed
  e.target.value = null;
};

const handleRemoveImage = (index) => {
  setFilePreviews((prev) => prev.filter((_, i) => i !== index));
  setSelectedFiles((prev) => prev.filter((_, i) => i !== index));
};

const createProduct = async (e,  clearAfterSave = false) => {
  e.preventDefault();
  try {
    const formData = new FormData();
    formData.append("name", name);
    formData.append("price", parseFloat(price));
    formData.append("description", description);
    formData.append("category_id", category_id);
    formData.append("status", parseInt(status));

    // Append files from selectedFiles state, NOT from input DOM element
    selectedFiles.forEach((file) => {
      formData.append("image[]", file);
    });

    const res = await API.post("/admin/products", formData, {
      headers: {
        "Content-Type": "multipart/form-data",
      },
    });

    setMessage(`Product "${res.data.name}" created successfully!`);
   if (clearAfterSave) {
      // Only clear the form if "Save" button clicked
      setName("");
      setPrice("");
      setDescription("");
      setFilePreviews([]);
      setSelectedFiles([]);
      setCategory_id("");

      navigate("/table-data"); // Redirect to products page
    }
  } catch (error) {
    setMessage("Error creating product");
    console.error("Submission Error:", error?.response?.data || error.message);
  }
};

  const fetchCategories = async () => {
    try {
      const res = await API.get("/categories");
      setCategories(res.data);
    } catch (error) {
      setMessage("Error fetching categories");
      console.error(error);
    }
  };

  useEffect(() => {
    fetchCategories();
  }, []);


  const quillRef = useRef(null);
  const [value, setValue] = useState(``);
  const [isHighlightReady, setIsHighlightReady] = useState(false);

  useEffect(() => {
    hljs?.configure({
      languages: [
        "javascript",
        "ruby",
        "python",
        "java",
        "csharp",
        "cpp",
        "go",
        "php",
        "swift",
      ],
    });
  }, []);

  const handleSave = () => {
    const editorContent = quillRef.current.getEditor().root.innerHTML;
    // console.log("Editor content:", editorContent);
  };

  const modules = isHighlightReady
    ? {
        syntax: {
          highlight: (text) => hljs?.highlightAuto(text).value,
        },
        toolbar: {
          container: "#toolbar-container",
        },
      }
    : {
        toolbar: {
          container: "#toolbar-container",
        },
      };

  const formats = [
    "font",
    "size",
    "bold",
    "italic",
    "underline",
    "strike",
    "color",
    "background",
    "script",
    "header",
    "blockquote",
    "code-block",
    "list",
    "indent",
    "direction",
    "align",
    "link",
    "image",
    "video",
    "formula",
  ];

  return (
    <div className="row gy-4">
      <form onSubmit={(e) => e.preventDefault()}>
            <div className="col-lg-8">
        <div className="card mt-24">
          <div className="card-header border-bottom">
            <h6 className="text-xl mb-0">Add New Product</h6>
          </div>
          <div className="card-body p-24">
       
              <div>
                <label
                  className="form-label fw-bold text-neutral-900"
                  htmlFor="title"
                >
                  Post Title:{" "}
                </label>
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
                <label className="form-label fw-bold text-neutral-900">
                  Post Category:{" "}
                </label>
                <select
                  className="form-control border border-neutral-200 radius-8"
                  value={category_id}
                  onChange={(e) => setCategory_id(e.target.value)}
                >
                  <option value="">Select category</option>
                  {categories.map((category) => (
                    <option key={category.id} value={category.id}>
                      {category.name}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="form-label fw-bold text-neutral-900">
                  Pricing:{" "}
                </label>
                <input
                  type="number"
                  className="form-control border border-neutral-200 radius-8"
                  style={{ width: "300px" }}
                  id="Pricing"
                  value={price}
                  onChange={(e) => setPrice(e.target.value)}
                  placeholder="Enter pricing"
                />
              </div>
              <div>
                <label className="form-label fw-bold text-neutral-900">
                  Post Description
                </label>
                <div className="border border-neutral-200 radius-8 overflow-hidden">
                  <div className="height-200">
                    <div id="toolbar-container">
                      <span className="ql-formats">
                        <select className="ql-font"></select>
                        <select className="ql-size"></select>
                      </span>
                      <span className="ql-formats">
                        <button className="ql-bold"></button>
                        <button className="ql-italic"></button>
                        <button className="ql-underline"></button>
                        <button className="ql-strike"></button>
                      </span>
                      <span className="ql-formats">
                        <select className="ql-color"></select>
                        <select className="ql-background"></select>
                      </span>
                      <span className="ql-formats">
                        <button className="ql-script" value="sub"></button>
                        <button className="ql-script" value="super"></button>
                      </span>
                      <span className="ql-formats">
                        <button className="ql-header" value="1"></button>
                        <button className="ql-header" value="2"></button>
                        <button className="ql-blockquote"></button>
                        <button className="ql-code-block"></button>
                      </span>
                      <span className="ql-formats">
                        <button className="ql-list" value="ordered"></button>
                        <button className="ql-list" value="bullet"></button>
                        <button className="ql-indent" value="-1"></button>
                        <button className="ql-indent" value="+1"></button>
                      </span>
                      <span className="ql-formats">
                        <button className="ql-direction" value="rtl"></button>
                        <select className="ql-align"></select>
                      </span>
                      <span className="ql-formats">
                        <button className="ql-link"></button>
                        <button className="ql-image"></button>
                        <button className="ql-video"></button>
                        <button className="ql-formula"></button>
                      </span>
                      <span className="ql-formats">
                        <button className="ql-clean"></button>
                      </span>
                    </div>
                    <ReactQuill
                      ref={quillRef}
                      theme="snow"
                      value={description}
                      onChange={(value) => setDescription(value)}
                      modules={modules}
                      formats={formats}
                      placeholder="Compose an epic..."
                    />
                  </div>
                </div>
              </div>
              <div>
                <label className="form-label fw-bold text-neutral-900">
                  Upload Media
                </label>
                <div className="upload-image-wrapper">
                  {filePreviews.length > 0 ? (
                    filePreviews.map((file, index) => (
                      <div
                        key={index}
                        className="uploaded-img position-relative h-160-px w-100 border input-form-light radius-8 overflow-hidden border-dashed bg-neutral-50"
                      >
                        <button
                          type="button"
                          className="uploaded-img__remove position-absolute top-0 end-0 z-1 text-2xxl line-height-1 me-8 mt-8 d-flex bg-danger-600 w-40-px h-40-px justify-content-center align-items-center rounded-circle"
                          onClick={() => handleRemoveImage(index)}
                        >
                          <iconify-icon
                            icon="radix-icons:cross-2"
                            className="text-2xl text-white"
                          ></iconify-icon>
                        </button>
                        <img
                          id={`uploaded-img__preview-${index}`}
                          className="w-100 h-100 object-fit-cover"
                          src={file}
                          alt={`Uploaded-${index}`}
                        />
                      </div>
                    ))
                  ) : (
                    <label
                      className="upload-file h-160-px w-100 border input-form-light radius-8 overflow-hidden border-dashed bg-neutral-50 bg-hover-neutral-200 d-flex align-items-center flex-column justify-content-center gap-1"
                      htmlFor="upload-file"
                    >
                      <iconify-icon
                        icon="solar:camera-outline"
                        className="text-xl text-secondary-light"
                      ></iconify-icon>
                      <span className="fw-semibold text-secondary-light">
                        Upload
                      </span>
                      <input
                        id="upload-file"
                        type="file"
                        hidden
                        name="image[]"
                        accept="image/*"
                        value={image}
                        multiple
                        onChange={handleFileChange}
                      />
                    </label>
                  )}
                </div>
              </div>
               <div className="mt-24">
                <label className="form-label fw-bold text-neutral-900">
                  Status:{" "}
                </label>
                <select
                  className="form-control border border-neutral-200 radius-8"
                  value={status}
                  onChange={(e) => setStatus(e.target.value)}
                >
                  <option value="1">Active</option>
                  <option value="0">Inactive</option>
                </select>
              </div>
              <button type="submit" className="btn btn-primary-600 radius-8 mt-3"  onClick={(e) => createProduct(e, true) }>
                Save
              </button>
              <button type="submit" className="btn btn-info-600 radius-8 mt-3 ms-3" onClick={(e) => createProduct(e, false)}>
                Save New
              </button>
              
              <div className="d-flex flex-column gap-24">
        
        </div>
          </div>
        </div>
      </div>
       
      </form>
    </div>
  );
};

export default AddBlogLayer;
