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
            <div className="d-flex flex-column gap-4">
                {/* Header Card */}
                <div className="card border-0 shadow-sm radius-12 p-3 bg-white">
                    <div className="d-flex align-items-center justify-content-between flex-wrap gap-3">
                        <div className="d-flex align-items-center gap-3">
                            <button
                                type="button"
                                className="btn btn-sm btn-outline-secondary d-flex align-items-center gap-1 radius-8"
                                onClick={() => navigate(-1)}
                            >
                                <Icon icon="mdi:arrow-left" /> Back
                            </button>
                            <div>
                                <h5 className="mb-0 fw-bold text-dark">Edit Teacher Profile</h5>
                                <small className="text-muted">Update instructor details and credentials for {name || "Teacher"}</small>
                            </div>
                        </div>

                        <div className="d-flex gap-2">
                            <Link to={`/school/teachers/${id}`} className="btn btn-sm btn-outline-info d-flex align-items-center gap-1 radius-8">
                                <Icon icon="mdi:eye" /> View Profile
                            </Link>
                            <Link to="/school/teachers" className="btn btn-sm btn-outline-primary d-flex align-items-center gap-1 radius-8">
                                <Icon icon="mdi:format-list-bulleted" /> All Teachers
                            </Link>
                        </div>
                    </div>
                </div>

                {error && (
                    <div className="alert alert-danger alert-dismissible fade show radius-12 mb-0" role="alert">
                        <Icon icon="mdi:alert-circle-outline" className="me-2 text-lg" />
                        {error}
                        <button type="button" className="btn-close" onClick={() => setError("")} />
                    </div>
                )}

                {loading ? (
                    <div className="d-flex justify-content-center align-items-center py-5" style={{ minHeight: "300px" }}>
                        <div className="spinner-border text-primary" role="status">
                            <span className="visually-hidden">Loading teacher details...</span>
                        </div>
                    </div>
                ) : (
                    <form onSubmit={handleSubmit}>
                        <div className="row g-4">
                            {/* Left Column: Avatar Photo & Info */}
                            <div className="col-12 col-lg-4">
                                <div className="card border-0 shadow-sm radius-12 bg-white h-100 p-4 d-flex flex-column align-items-center text-center">
                                    <h6 className="fw-bold text-dark w-100 text-start mb-3">Teacher Photo</h6>

                                    <div className="position-relative mb-3">
                                        <div className="w-120-px h-120-px rounded-circle overflow-hidden bg-light border d-flex align-items-center justify-content-center shadow-sm">
                                            {previewImageSrc ? (
                                                <img src={previewImageSrc} alt="Preview" className="w-100 h-100 object-fit-cover" />
                                            ) : (
                                                <Icon icon="mdi:account" className="text-secondary text-5xl opacity-50" />
                                            )}
                                        </div>
                                        {uploadedImage && (
                                            <button
                                                type="button"
                                                className="btn btn-sm btn-danger rounded-circle p-1 position-absolute top-0 end-0 shadow-sm"
                                                onClick={removeNewImage}
                                                title="Remove New Photo"
                                            >
                                                <Icon icon="mdi:close" className="text-white text-xs d-block" />
                                            </button>
                                        )}
                                    </div>

                                    <label className="btn btn-outline-primary btn-sm radius-8 cursor-pointer mb-2">
                                        <Icon icon="mdi:camera" className="me-1" /> Change Photo
                                        <input type="file" accept="image/*" className="d-none" onChange={handleFileChange} />
                                    </label>
                                    <small className="text-muted text-xs">JPG, PNG or GIF up to 5MB</small>

                                    <div className="mt-4 p-3 bg-light radius-8 w-100 text-start">
                                        <div className="d-flex align-items-center gap-2 text-primary fw-bold text-xs mb-1">
                                            <Icon icon="mdi:information-outline" /> Account Info
                                        </div>
                                        <p className="text-muted text-xs mb-0">
                                            Modifying email address will update the login credentials for this teacher account.
                                        </p>
                                    </div>
                                </div>
                            </div>

                            {/* Right Column: Edit Form */}
                            <div className="col-12 col-lg-8">
                                <div className="card border-0 shadow-sm radius-12 bg-white p-4 d-flex flex-column gap-4">
                                    <div>
                                        <h6 className="fw-bold text-dark mb-3 pb-2 border-bottom">Personal Information</h6>
                                        <div className="row g-3">
                                            <div className="col-12 col-md-6">
                                                <label className="form-label text-xs fw-semibold">
                                                    Full Name <Required />
                                                </label>
                                                <input
                                                    type="text"
                                                    className="form-control form-control-sm radius-8"
                                                    value={name}
                                                    onChange={(e) => setName(e.target.value)}
                                                    required
                                                />
                                            </div>

                                            <div className="col-12 col-md-6">
                                                <label className="form-label text-xs fw-semibold">
                                                    Email Address <Required />
                                                </label>
                                                <input
                                                    type="email"
                                                    className="form-control form-control-sm radius-8"
                                                    value={email}
                                                    onChange={(e) => setEmail(e.target.value)}
                                                    required
                                                />
                                            </div>

                                            <div className="col-12 col-md-6">
                                                <label className="form-label text-xs fw-semibold">Phone Number</label>
                                                <input
                                                    type="text"
                                                    className="form-control form-control-sm radius-8"
                                                    value={phone}
                                                    onChange={(e) => setPhone(e.target.value)}
                                                />
                                            </div>

                                            <div className="col-12 col-md-6">
                                                <label className="form-label text-xs fw-semibold">Subject / Department</label>
                                                <input
                                                    type="text"
                                                    className="form-control form-control-sm radius-8"
                                                    value={subject}
                                                    onChange={(e) => setSubject(e.target.value)}
                                                />
                                            </div>
                                        </div>
                                    </div>

                                    <div>
                                        <div className="d-flex align-items-center justify-content-between mb-3 pb-2 border-bottom">
                                            <h6 className="fw-bold text-dark mb-0">Reset Password (Optional)</h6>
                                            <small className="text-muted">Leave blank to keep current password</small>
                                        </div>
                                        <div className="row g-3">
                                            <div className="col-12 col-md-6">
                                                <label className="form-label text-xs fw-semibold">New Password</label>
                                                <div className="position-relative">
                                                    <input
                                                        type={showPassword ? "text" : "password"}
                                                        className="form-control form-control-sm radius-8 pe-5"
                                                        placeholder="Leave empty to keep unchanged"
                                                        value={password}
                                                        onChange={(e) => setPassword(e.target.value)}
                                                    />
                                                    <button
                                                        type="button"
                                                        className="btn btn-sm btn-link position-absolute top-50 end-0 translate-middle-y text-muted pe-3 text-decoration-none"
                                                        onClick={() => setShowPassword(!showPassword)}
                                                    >
                                                        <Icon icon={showPassword ? "mdi:eye-off" : "mdi:eye"} />
                                                    </button>
                                                </div>
                                            </div>

                                            <div className="col-12 col-md-6">
                                                <label className="form-label text-xs fw-semibold">Confirm New Password</label>
                                                <input
                                                    type={showPassword ? "text" : "password"}
                                                    className="form-control form-control-sm radius-8"
                                                    placeholder="Re-enter new password"
                                                    value={confirmPassword}
                                                    onChange={(e) => setConfirmPassword(e.target.value)}
                                                />
                                            </div>
                                        </div>
                                    </div>

                                    {/* Form Actions */}
                                    <div className="d-flex align-items-center justify-content-end gap-2 pt-3 border-top">
                                        <Link to="/school/teachers" className="btn btn-sm btn-light radius-8 px-3">
                                            Cancel
                                        </Link>
                                        <button type="submit" className="btn btn-sm btn-primary radius-8 px-4 d-flex align-items-center gap-1" disabled={submitting}>
                                            {submitting ? (
                                                <>
                                                    <span className="spinner-border spinner-border-sm me-1" role="status" /> Saving...
                                                </>
                                            ) : (
                                                <>
                                                    <Icon icon="mdi:check" /> Save Changes
                                                </>
                                            )}
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </form>
                )}
            </div>
        </SchoolLayout>
    );
}
