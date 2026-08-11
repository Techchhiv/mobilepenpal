import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useNavigate, useParams } from "react-router-dom";
import SchoolLayout from "../../masterLayout/SchoolLayout";
import API from "../../../../helper/api";
import API_BASE_URL from "../../../../helper/Base_urls";

const Required = () => <span className="text-danger ms-1">*</span>;

export default function TeacherEdit() {
    const { id } = useParams();
    const navigate = useNavigate();

    const [loading, setLoading] = useState(true);
    const [submitting, setSubmitting] = useState(false);

    const [name, setName] = useState("");
    const [email, setEmail] = useState("");
    const [phone, setPhone] = useState("");
    const [subject, setSubject] = useState("");

    // Optional password change
    const [password, setPassword] = useState("");
    const [confirmPassword, setConfirmPassword] = useState("");
    const [showPassword, setShowPassword] = useState(false);

    // photo
    const [uploadedImage, setUploadedImage] = useState(null);
    const [existingPhoto, setExistingPhoto] = useState(null);

    const [error, setError] = useState("");

    const photoUrl = (p) =>
        !p ? null : String(p).startsWith("http") ? p : `${API_BASE_URL}/${String(p).replace(/^\/+/, "")}`;

    const previewImageSrc = useMemo(() => {
        if (uploadedImage?.src) return uploadedImage.src;
        if (existingPhoto) return photoUrl(existingPhoto);
        return null;
    }, [uploadedImage, existingPhoto]);

    const handleFileChange = (e) => {
        const file = e.target.files?.[0];
        if (!file) return;

        const reader = new FileReader();
        reader.onload = () => setUploadedImage({ src: reader.result });
        reader.readAsDataURL(file);
        e.target.value = "";
    };

    const removeNewImage = () => setUploadedImage(null);

    const fetchTeacher = async () => {
        setLoading(true);
        setError("");
        try {
            const res = await API.get(`/school/teachers/${id}`);
            const t = res?.data?.teacher ?? res?.data;

            setName(t?.name ?? "");
            setEmail(t?.email ?? "");
            setPhone(t?.phone ?? "");
            setSubject(t?.subject ?? "");
            setExistingPhoto(t?.photo ?? null);
        } catch (err) {
            console.error("Fetch teacher failed:", err);
            setError(err?.response?.data?.message || "Failed to load teacher details.");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchTeacher();
    }, [id]);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError("");

        if (password && password !== confirmPassword) {
            setError("Passwords do not match. Please verify password entries.");
            return;
        }
        if (password && password.length < 6) {
            setError("Password must be at least 6 characters long.");
            return;
        }

        setSubmitting(true);
        try {
            const formData = new FormData();
            formData.append("_method", "PUT");
            formData.append("name", name);
            formData.append("email", email);
            formData.append("phone", phone || "");
            formData.append("subject", subject || "");

            if (password) {
                formData.append("password", password);
            }

            if (uploadedImage?.src) {
                formData.append("photo", uploadedImage.src);
            }

            await API.post(`/school/teachers/${id}`, formData);

            navigate("/school/teachers", {
                state: {
                    flash: `Teacher "${name}" updated successfully.`,
                },
                replace: true,
            });
        } catch (err) {
            setError(
                err?.response?.data?.errors?.name?.[0] ||
                err?.response?.data?.errors?.email?.[0] ||
                err?.response?.data?.errors?.password?.[0] ||
                err?.response?.data?.errors?.photo?.[0] ||
                err?.response?.data?.message ||
                "Failed to update teacher profile."
            );
            console.error(err);
        } finally {
            setSubmitting(false);
        }
    };

    return (
        <SchoolLayout>
            <div className="col-lg-12">
                <div className="card">
                    <div className="card-header d-flex justify-content-between align-items-center">
                        <div>
                            <h3 className="card-title mb-0">Edit Teacher Profile</h3>
                            <small className="text-muted">Update instructor details and credentials for {name || "Teacher"}</small>
                        </div>
                        <div className="d-flex gap-2">
                            <Link to={`/school/teachers/${id}`} className="btn btn-outline-info d-flex align-items-center">
                                <Icon icon="mdi:eye" className="me-2" /> View Profile
                            </Link>
                            <Link to="/school/teachers" className="btn btn-secondary d-flex align-items-center">
                                <Icon icon="mdi:arrow-left" className="me-2" /> Back
                            </Link>
                        </div>
                    </div>

                    <div className="card-body">
                        {error && (
                            <div className="alert alert-danger">
                                <Icon icon="mdi:alert-circle" className="me-2" />
                                {error}
                            </div>
                        )}

                        {loading ? (
                            <div className="text-center py-5">
                                <div className="spinner-border text-primary" role="status">
                                    <span className="visually-hidden">Loading teacher details...</span>
                                </div>
                            </div>
                        ) : (
                            <form onSubmit={handleSubmit}>
                                <div className="row gy-4">
                                    {/* Left Column: Avatar Photo & Info */}
                                    <div className="col-md-4">
                                        <div className="card h-100">
                                            <div className="card-header bg-light">
                                                <h6 className="mb-0">Teacher Photo</h6>
                                            </div>
                                            <div className="card-body text-center d-flex flex-column justify-content-center gap-2">
                                                <div className="mb-3">
                                                    {previewImageSrc ? (
                                                        <div className="position-relative mx-auto" style={{ width: "150px", height: "150px" }}>
                                                            {uploadedImage && (
                                                                <button
                                                                    type="button"
                                                                    className="position-absolute top-0 end-0 z-1 text-danger btn btn-sm btn-light"
                                                                    style={{ margin: "5px" }}
                                                                    onClick={removeNewImage}
                                                                    title="Remove New Photo"
                                                                >
                                                                    <Icon icon="radix-icons:cross-2" />
                                                                </button>
                                                            )}
                                                            <img
                                                                src={previewImageSrc}
                                                                alt="Preview"
                                                                className="w-100 h-100 object-fit-cover rounded-circle border"
                                                            />
                                                        </div>
                                                    ) : (
                                                        <div
                                                            className="mx-auto rounded-circle border d-flex align-items-center justify-content-center bg-light overflow-hidden"
                                                            style={{ width: "150px", height: "150px" }}
                                                        >
                                                            <Icon icon="mdi:account-circle" className="text-secondary" width="100%" height="100%" />
                                                        </div>
                                                    )}
                                                </div>

                                                <label className="d-flex align-items-center justify-content-center btn btn-outline-primary w-100">
                                                    <Icon icon="solar:camera-outline" className="me-3" />
                                                    Change Photo
                                                    <input type="file" accept="image/*" className="d-none" onChange={handleFileChange} />
                                                </label>
                                                <small className="text-muted d-block">JPG, PNG or GIF up to 5MB</small>

                                                <div className="mt-3 p-3 bg-light rounded text-start">
                                                    <div className="d-flex align-items-center gap-2 text-primary fw-bold mb-1">
                                                        <Icon icon="mdi:information-outline" /> Account Info
                                                    </div>
                                                    <small className="text-muted d-block">
                                                        Modifying email address will update the login credentials for this teacher account.
                                                    </small>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    {/* Right Column: Edit Form */}
                                    <div className="col-md-8">
                                        <div className="card mb-4">
                                            <div className="card-header bg-light">
                                                <h6 className="d-flex align-content-center mb-0">
                                                    <Icon icon="mdi:account" className="me-3" />
                                                    Personal Details
                                                </h6>
                                            </div>
                                            <div className="card-body">
                                                <div className="row g-3">
                                                    <div className="col-md-6">
                                                        <label className="form-label">
                                                            Full Name <Required />
                                                        </label>
                                                        <input
                                                            type="text"
                                                            className="form-control"
                                                            value={name}
                                                            onChange={(e) => setName(e.target.value)}
                                                            required
                                                        />
                                                    </div>

                                                    <div className="col-md-6">
                                                        <label className="form-label">
                                                            Email Address <Required />
                                                        </label>
                                                        <input
                                                            type="email"
                                                            className="form-control"
                                                            value={email}
                                                            onChange={(e) => setEmail(e.target.value)}
                                                            required
                                                        />
                                                    </div>

                                                    <div className="col-md-6">
                                                        <label className="form-label">Phone Number</label>
                                                        <input
                                                            type="text"
                                                            className="form-control"
                                                            value={phone}
                                                            onChange={(e) => setPhone(e.target.value)}
                                                        />
                                                    </div>

                                                    <div className="col-md-6">
                                                        <label className="form-label">Subject / Department</label>
                                                        <input
                                                            type="text"
                                                            className="form-control"
                                                            value={subject}
                                                            onChange={(e) => setSubject(e.target.value)}
                                                        />
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <div className="card mb-4">
                                            <div className="card-header bg-light d-flex align-items-center justify-content-between">
                                                <h6 className="d-flex align-content-center mb-0">
                                                    <Icon icon="mdi:lock" className="me-3" />
                                                    Reset Password (Optional)
                                                </h6>
                                                <small className="text-muted">Leave blank to keep current password</small>
                                            </div>
                                            <div className="card-body">
                                                <div className="row g-3">
                                                    <div className="col-md-6">
                                                        <label className="form-label">New Password</label>
                                                        <div className="position-relative">
                                                            <input
                                                                type={showPassword ? "text" : "password"}
                                                                className="form-control pe-5"
                                                                placeholder="Leave empty to keep unchanged"
                                                                value={password}
                                                                onChange={(e) => setPassword(e.target.value)}
                                                            />
                                                            <button
                                                                type="button"
                                                                className="btn btn-link position-absolute top-50 end-0 translate-middle-y text-muted pe-3 text-decoration-none"
                                                                onClick={() => setShowPassword(!showPassword)}
                                                            >
                                                                <Icon icon={showPassword ? "mdi:eye-off" : "mdi:eye"} />
                                                            </button>
                                                        </div>
                                                    </div>

                                                    <div className="col-md-6">
                                                        <label className="form-label">Confirm New Password</label>
                                                        <input
                                                            type={showPassword ? "text" : "password"}
                                                            className="form-control"
                                                            placeholder="Re-enter new password"
                                                            value={confirmPassword}
                                                            onChange={(e) => setConfirmPassword(e.target.value)}
                                                        />
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        {/* Form Actions */}
                                        <div className="d-flex justify-content-end gap-2">
                                            <button type="submit" className="d-flex align-items-center btn btn-primary" disabled={submitting}>
                                                {submitting ? (
                                                    <>
                                                        <span className="spinner-border spinner-border-sm me-2" role="status" /> Saving...
                                                    </>
                                                ) : (
                                                    <>
                                                        <Icon icon="mdi:content-save" className="me-2" /> Save Changes
                                                    </>
                                                )}
                                            </button>
                                            <Link to="/school/teachers" className="d-flex align-items-center btn btn-secondary">
                                                Cancel
                                            </Link>
                                        </div>
                                    </div>
                                </div>
                            </form>
                        )}
                    </div>
                </div>
            </div>
        </SchoolLayout>
    );
}
