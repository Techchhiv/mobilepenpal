import React, { useEffect, useMemo, useState } from "react";
import { Icon } from "@iconify/react";
import { Link, useNavigate, useParams } from "react-router-dom";
import SchoolLayout from "../../masterLayout/SchoolLayout";
import API from "../../../../helper/api";
import API_BASE_URL from "../../../../helper/Base_urls";
import { useAuth } from "../../../../context/AuthContext";

const Required = () => <span className="text-danger ms-1">*</span>;

export default function TeacherEdit() {
    const { hasPermission } = useAuth();
    const { id } = useParams();
    const navigate = useNavigate();

    const [loading, setLoading] = useState(true);
    const [submitting, setSubmitting] = useState(false);

    const [name, setName] = useState("");
    const [email, setEmail] = useState("");
    const [phone, setPhone] = useState("");
    const [subject, setSubject] = useState("");

    // password (optional change)
    const [password, setPassword] = useState("");
    const [confirmPassword, setConfirmPassword] = useState("");

    // photo
    const [uploadedImage, setUploadedImage] = useState(null); // { src, file }
    const [existingPhoto, setExistingPhoto] = useState(null); // string|null

    const [error, setError] = useState("");

    // lightbox preview
    const [previewSrc, setPreviewSrc] = useState(null);
    const closePreview = () => setPreviewSrc(null);

    useEffect(() => {
        const onKeyDown = (e) => e.key === "Escape" && closePreview();
        if (previewSrc) window.addEventListener("keydown", onKeyDown);
        return () => window.removeEventListener("keydown", onKeyDown);
    }, [previewSrc]);

    const photoUrl = (p) =>
        !p ? null : String(p).startsWith("http") ? p : `${API_BASE_URL}/${String(p).replace(/^\/+/, "")}`;

    const previewImageSrc = useMemo(() => {
        if (uploadedImage?.src) return uploadedImage.src;
        if (existingPhoto) return photoUrl(existingPhoto);
        return null;
    }, [uploadedImage, existingPhoto]);

    const displayName = useMemo(() => name?.trim() || "Teacher", [name]);

    const handleFileChange = (e) => {
        const file = e.target.files?.[0];
        if (!file) return;

        const reader = new FileReader();
        reader.onload = () => setUploadedImage({ src: reader.result, file: null });
        reader.readAsDataURL(file);

        e.target.value = "";
    };


    const removeNewImage = () => {
        if (uploadedImage?.src) URL.revokeObjectURL(uploadedImage.src);
        setUploadedImage(null);
    };

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
            setError(err?.response?.data?.message || "Failed to load teacher.");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchTeacher();
        return () => {
            if (uploadedImage?.src) URL.revokeObjectURL(uploadedImage.src);
        };
    }, [id]);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError("");

        // Optional permissions check (depends on your permission names)
        if (hasPermission && !hasPermission("teachers.update")) {
            setError("You don't have permission to update teachers.");
            return;
        }

        if (password || confirmPassword) {
            if (password !== confirmPassword) {
                setError("Passwords do not match.");
                return;
            }
            if (password.length > 0 && password.length < 6) {
                setError("Password must be at least 6 characters.");
                return;
            }
        }

        setSubmitting(true);
        try {
            const formData = new FormData();

            formData.append("name", name);
            formData.append("email", email);

            formData.append("phone", phone || "");
            formData.append("subject", subject || "");

            if (password) formData.append("password", password);
            if (uploadedImage?.src) formData.append("photo", uploadedImage.src);

            formData.append("_method", "PUT");

            await API.post(`/school/teachers/${id}`, formData, {
                headers: { "Content-Type": "multipart/form-data" },
            });

            navigate("/school/teachers", {
                state: { flash: "Teacher updated successfully!" },
                replace: true,
            });
        } catch (err) {
            console.error("Update teacher failed:", err);

            setError(
                err?.response?.data?.errors?.name?.[0] ||
                err?.response?.data?.errors?.email?.[0] ||
                err?.response?.data?.errors?.photo?.[0] ||
                err?.response?.data?.errors?.password?.[0] ||
                err?.response?.data?.message ||
                "Failed to update teacher."
            );
        } finally {
            setSubmitting(false);
        }
    };

    return (
        <SchoolLayout>
            <div className="col-12">
                <div className="card">
                    <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                        <div>
                            <h5 className="card-title mb-0">Edit Teacher</h5>
                            <small className="text-muted">Update teacher profile information</small>
                        </div>

                        <div className="d-flex gap-2">
                            <Link to="/school/teachers" className="btn btn-outline-secondary">
                                <Icon icon="mdi:arrow-left" className="me-6" />
                                Back
                            </Link>
                        </div>
                    </div>

                    <div className="card-body">
                        {error && <div className="alert alert-danger">{error}</div>}

                        {loading ? (
                            <div className="text-center py-40">
                                <div className="spinner-border" role="status" />
                                <div className="mt-12 text-muted">Loading teacher...</div>
                            </div>
                        ) : (
                            <form onSubmit={handleSubmit}>
                                <div className="row g-3">
                                    {/* LEFT: Photo */}
                                    <div className="col-12 col-lg-4">
                                        <div className="card border">
                                            <div className="card-header d-flex align-items-center gap-2">
                                                <Icon icon="solar:camera-outline" />
                                                <h6 className="mb-0">Photo</h6>
                                            </div>

                                            <div className="card-body">
                                                <div className="d-flex align-items-center gap-3">
                                                    <div
                                                        className="border radius-12 overflow-hidden bg-neutral-50"
                                                        style={{ width: 120, height: 120 }}
                                                    >
                                                        {previewImageSrc ? (
                                                            <button
                                                                type="button"
                                                                className="p-0 border-0 bg-transparent w-100 h-100"
                                                                onClick={() => setPreviewSrc(previewImageSrc)}
                                                                style={{ cursor: "zoom-in" }}
                                                                title="Click to view"
                                                            >
                                                                <img
                                                                    className="w-100 h-100 object-fit-cover"
                                                                    src={previewImageSrc}
                                                                    alt="Photo"
                                                                />
                                                            </button>
                                                        ) : (
                                                            <div className="w-100 h-100 d-flex align-items-center justify-content-center text-muted">
                                                                <Icon icon="mdi:account" width={44} />
                                                            </div>
                                                        )}
                                                    </div>

                                                    <div className="flex-grow-1">
                                                        <div className="fw-semibold">{displayName}</div>
                                                        <div className="text-muted small">Teacher ID: {id}</div>

                                                        <div className="mt-10 d-flex gap-2 flex-wrap">
                                                            <label className="btn btn-outline-primary btn-sm mb-0">
                                                                <Icon icon="solar:camera-outline" className="me-6" />
                                                                Upload
                                                                <input
                                                                    type="file"
                                                                    hidden
                                                                    accept="image/*"
                                                                    onChange={handleFileChange}
                                                                />
                                                            </label>

                                                            {uploadedImage && (
                                                                <button
                                                                    type="button"
                                                                    className="btn btn-outline-danger btn-sm"
                                                                    onClick={removeNewImage}
                                                                >
                                                                    <Icon icon="radix-icons:cross-2" className="me-6" />
                                                                    Remove
                                                                </button>
                                                            )}
                                                        </div>

                                                        <div className="text-muted small mt-8">
                                                            Max size: 2MB (jpg/png).
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    {/* RIGHT: Form */}
                                    <div className="col-12 col-lg-8">
                                        {/* Teacher Info */}
                                        <div className="card border mb-3">
                                            <div className="card-header d-flex align-items-center gap-2">
                                                <Icon icon="mdi:account" />
                                                <h6 className="mb-0">Teacher Information</h6>
                                            </div>

                                            <div className="card-body">
                                                <div className="row gy-3">
                                                    <div className="col-md-6">
                                                        <label className="form-label">
                                                            Full Name <Required />
                                                        </label>
                                                        <input
                                                            className="form-control"
                                                            value={name}
                                                            onChange={(e) => setName(e.target.value)}
                                                            required
                                                        />
                                                    </div>

                                                    <div className="col-md-6">
                                                        <label className="form-label">
                                                            Email <Required />
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
                                                        <label className="form-label">Phone</label>
                                                        <input
                                                            className="form-control"
                                                            value={phone}
                                                            onChange={(e) => setPhone(e.target.value)}
                                                            placeholder="+855..."
                                                        />
                                                    </div>

                                                    <div className="col-md-6">
                                                        <label className="form-label">Subject</label>
                                                        <input
                                                            className="form-control"
                                                            value={subject}
                                                            onChange={(e) => setSubject(e.target.value)}
                                                            placeholder="e.g. Khmer Writing"
                                                        />
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        {/* Security */}
                                        <div className="card border mb-3">
                                            <div className="card-header d-flex align-items-center gap-2">
                                                <Icon icon="mdi:lock" />
                                                <h6 className="mb-0">Security</h6>
                                            </div>
                                            <div className="card-body">
                                                <div className="row gy-3">
                                                    <div className="col-md-6">
                                                        <label className="form-label">New Password</label>
                                                        <input
                                                            type="password"
                                                            className="form-control"
                                                            placeholder="Leave empty to keep current"
                                                            value={password}
                                                            onChange={(e) => setPassword(e.target.value)}
                                                        />
                                                        <div className="form-text">
                                                            At least 6 characters.
                                                        </div>
                                                    </div>

                                                    <div className="col-md-6">
                                                        <label className="form-label">Confirm New Password</label>
                                                        <input
                                                            type="password"
                                                            className="form-control"
                                                            placeholder="Re-type new password"
                                                            value={confirmPassword}
                                                            onChange={(e) => setConfirmPassword(e.target.value)}
                                                        />
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        {/* Actions */}
                                        <div className="d-flex gap-2 flex-wrap">
                                            <button
                                                className="btn btn-primary"
                                                type="submit"
                                                disabled={submitting}
                                            >
                                                <Icon icon="mdi:content-save" className="me-6" />
                                                {submitting ? "Saving..." : "Save Changes"}
                                            </button>

                                            <button
                                                type="button"
                                                className="btn btn-outline-secondary"
                                                onClick={() => navigate("/school/teachers")}
                                                disabled={submitting}
                                            >
                                                Cancel
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </form>
                        )}
                    </div>
                </div>
            </div>

            {/* ✅ image-only preview */}
            {previewSrc && (
                <div
                    className="position-fixed top-0 start-0 w-100 h-100"
                    style={{
                        background: "rgba(0,0,0,0.75)",
                        zIndex: 1055,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        padding: 16,
                    }}
                    onClick={closePreview}
                    role="dialog"
                    aria-modal="true"
                >
                    <img
                        src={previewSrc}
                        alt="Preview"
                        style={{
                            maxWidth: "95vw",
                            maxHeight: "90vh",
                            borderRadius: 12,
                            cursor: "default",
                        }}
                        onClick={(e) => e.stopPropagation()}
                    />
                </div>
            )}
        </SchoolLayout>
    );
}
