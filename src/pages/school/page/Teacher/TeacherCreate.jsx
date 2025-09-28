import React, { useState } from "react";
import { Icon } from "@iconify/react";
import SchoolLayout from "../../masterLayout/SchoolLayout";
import API from "../../../../helper/api";
import { useAuth } from "../../../../context/AuthContext";

export default function TeacherCreate() {
  const { user } = useAuth(); // logged-in school admin
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [subject, setSubject] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [uploadedImage, setUploadedImage] = useState(null);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  // Handle image selection
  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setUploadedImage({ src: URL.createObjectURL(file), file });
    }
    e.target.value = "";
  };

  const removeImage = () => {
    if (uploadedImage) URL.revokeObjectURL(uploadedImage.src);
    setUploadedImage(null);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setMessage("");
    setError("");

    if (password !== confirmPassword) {
      setError("Passwords do not match.");
      return;
    }

    try {
      const formData = new FormData();
      formData.append("name", name);
      formData.append("email", email);
      formData.append("phone", phone);
      formData.append("subject", subject);
      formData.append("password", password);
      if (uploadedImage) formData.append("photo", uploadedImage.file);

      // Backend automatically assigns school_id from logged-in school admin
      const res = await API.post("/school/teachers", formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });

      setMessage(
        `Teacher created successfully! ID: ${res.data.teacher.teacher_id}, School Key: ${res.data.teacher.school_key}`
      );

      // Reset form
      setName("");
      setEmail("");
      setPhone("");
      setSubject("");
      setPassword("");
      setConfirmPassword("");
      removeImage();

    } catch (err) {
      setError(
        err?.response?.data?.errors?.name?.[0] ||
        err?.response?.data?.errors?.email?.[0] ||
        err?.response?.data?.message ||
        "Failed to create teacher."
      );
      console.error(err);
    }
  };

  return (
    <SchoolLayout>
      <div className="col-lg-12">
        <div className="card">
          <div className="card-header">
            <h5 className="card-title mb-0">Add New Teacher</h5>
          </div>
          <div className="card-body">
            {message && <div className="alert alert-success">{message}</div>}
            {error && <div className="alert alert-danger">{error}</div>}

            <form className="row gy-3" onSubmit={handleSubmit}>
              <div className="col-md-6">
                <label className="form-label">Full Name</label>
                <input
                  className="form-control"
                  placeholder="Enter Full Name"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  required
                />
              </div>

              <div className="col-md-6">
                <label className="form-label">Email</label>
                <input
                  type="email"
                  className="form-control"
                  placeholder="Enter Email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                />
              </div>

              <div className="col-md-6">
                <label className="form-label">Phone</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="+855 000 000"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                />
              </div>

              <div className="col-md-6">
                <label className="form-label">Subject</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="Enter Subject"
                  value={subject}
                  onChange={(e) => setSubject(e.target.value)}
                />
              </div>

              <div className="col-md-6">
                <label className="form-label">Password</label>
                <input
                  type="password"
                  className="form-control"
                  placeholder="Enter Password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                />
              </div>

              <div className="col-md-6">
                <label className="form-label">Confirm Password</label>
                <input
                  type="password"
                  className="form-control"
                  placeholder="Confirm Password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  required
                />
              </div>

              <div className="col-md-12">
                <label className="form-label">Photo</label>
                <div className="d-flex align-items-center gap-3 flex-wrap">
                  {uploadedImage && (
                    <div className="position-relative h-120-px w-120-px border radius-8 overflow-hidden bg-neutral-50">
                      <button
                        type="button"
                        onClick={removeImage}
                        className="position-absolute top-0 end-0 z-1 text-danger btn btn-sm"
                      >
                        <Icon icon="radix-icons:cross-2" />
                      </button>
                      <img
                        className="w-100 h-100 object-fit-cover"
                        src={uploadedImage.src}
                        alt="Preview"
                      />
                    </div>
                  )}
                  <label
                    className="upload-file-multiple h-120-px w-120-px border radius-8 d-flex align-items-center justify-content-center bg-neutral-50 cursor-pointer"
                  >
                    <Icon icon="solar:camera-outline" className="text-xl text-secondary-light" />
                    <input
                      type="file"
                      hidden
                      onChange={handleFileChange}
                    />
                  </label>
                </div>
              </div>

              <div className="col-12">
                <button className="btn btn-primary" type="submit">
                  Create Teacher
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </SchoolLayout>
  );
}
