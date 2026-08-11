import React, { useState, useEffect } from "react";
import { Icon } from "@iconify/react";
import { Link, useNavigate } from "react-router-dom";
import SchoolLayout from "../../masterLayout/SchoolLayout";
import API from "../../../../helper/api";
import { useAuth } from "../../../../context/AuthContext";

export default function StudentCreate() {
    const { user } = useAuth();
    const navigate = useNavigate();

    const [firstName, setFirstName] = useState("");
    const [lastName, setLastName] = useState("");
    const [age, setAge] = useState("");
    const [gender, setGender] = useState("male");
    const [dateOfBirth, setDateOfBirth] = useState("");
    const [email, setEmail] = useState("");
    const [phone, setPhone] = useState("");
    const [parentFirstName, setParentFirstName] = useState("");
    const [parentLastName, setParentLastName] = useState("");
    const [address, setAddress] = useState("");
    const [enrollmentYear, setEnrollmentYear] = useState("");
    const [password, setPassword] = useState("");
    const [confirmPassword, setConfirmPassword] = useState("");
    const [uploadedImage, setUploadedImage] = useState(null);
    const [avatarBase64, setAvatarBase64] = useState(null);

    const [error, setError] = useState("");

    useEffect(() => {
        setEnrollmentYear(new Date().getFullYear().toString());
    }, []);

    const handleFileChange = (e) => {
        const file = e.target.files?.[0];
        if (!file) return;

        if (!file.type.startsWith("image/")) {
            setError("Please select a valid image file");
            return;
        }

        if (file.size > 5 * 1024 * 1024) {
            setError("Image size should be less than 5MB");
            return;
        }

        const reader = new FileReader();
        reader.onloadend = () => {
            setUploadedImage({
                src: reader.result,
            });
            setAvatarBase64(reader.result);
        };

        reader.readAsDataURL(file);
        e.target.value = "";
    };


    const removeImage = () => {
        if (uploadedImage) URL.revokeObjectURL(uploadedImage.src);
        setUploadedImage(null);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError("");

        // Validation
        if (!firstName.trim() || !lastName.trim()) {
            setError("First name and last name are required");
            return;
        }

        if (!age || parseInt(age) < 1) {
            setError("Please enter a valid age");
            return;
        }

        if (!dateOfBirth) {
            setError("Date of birth is required");
            return;
        }

        if (!email.trim()) {
            setError("Email address is required");
            return;
        }

        if (!/\S+@\S+\.\S+/.test(email.trim())) {
            setError("Please enter a valid email address");
            return;
        }

        if (password !== confirmPassword) {
            setError("Passwords do not match");
            return;
        }

        if (password.length < 6) {
            setError("Password must be at least 6 characters long");
            return;
        }

        try {
            const payload = {
                first_name: firstName.trim(),
                last_name: lastName.trim(),
                age,
                date_of_birth: dateOfBirth,
                gender,
                email: email.trim(),
                password,
                enrollment_year: enrollmentYear,
            };

            if (phone.trim()) payload.phone = phone.trim();
            if (parentFirstName) payload.parent_first_name = parentFirstName.trim();
            if (parentLastName) payload.parent_last_name = parentLastName.trim();
            if (address) payload.address = address.trim();
            if (avatarBase64) payload.avatar = avatarBase64;


            await API.post("/school/students", payload, {
                headers: { "Content-Type": "multipart/form-data" },
            });

            navigate("/school/students", {
                state: {
                    success: `Student "${firstName} ${lastName}" created successfully!`,
                },
            });

        } catch (err) {
            console.error("Create student error:", err);
            setError(
                err?.response?.data?.errors?.first_name?.[0] ||
                err?.response?.data?.errors?.last_name?.[0] ||
                err?.response?.data?.errors?.phone?.[0] ||
                err?.response?.data?.errors?.email?.[0] ||
                err?.response?.data?.errors?.password?.[0] ||
                err?.response?.data?.message ||
                "Failed to create student. Please try again."
            );
        }
    };

    const resetForm = () => {
        setFirstName("");
        setLastName("");
        setAge("");
        setGender("male");
        setDateOfBirth("");
        setEmail("");
        setPhone("");
        setParentFirstName("");
        setParentLastName("");
        setAddress("");
        setPassword("");
        setConfirmPassword("");
        removeImage();
        setEnrollmentYear(new Date().getFullYear().toString());
        setError("");
    };

    const Required = () => <span className="text-danger ms-1">*</span>;

    return (
        <SchoolLayout>
            <div className="col-lg-12">
                <div className="card">
                    <div className="card-header d-flex justify-content-between align-items-center">
                        <h3 className="card-title mb-0">Create New Student</h3>
                        <Link to="/school/students" className="d-flex align-items-center btn btn-secondary">
                            <Icon icon="mdi:arrow-left" className="me-3" />
                            Back to Students
                        </Link>
                    </div>

                    <div className="card-body">
                        {error && (
                            <div className="alert alert-danger">
                                <Icon icon="mdi:alert-circle" className="me-2" />
                                {error}
                            </div>
                        )}

                        <form className="row gy-4" onSubmit={handleSubmit}>
                            <div className="col-md-4">
                                <div className="card h-100">
                                    <div className="card-header bg-light">
                                        <h6 className="mb-0">Profile Picture</h6>
                                    </div>
                                    <div className="card-body text-center d-flex flex-column justify-content-center gap-2">
                                        <div className="mb-3">
                                            {uploadedImage ? (
                                                <div className="position-relative mx-auto" style={{ width: '150px', height: '150px' }}>
                                                    <button
                                                        type="button"
                                                        onClick={removeImage}
                                                        className="position-absolute top-0 end-0 z-1 text-danger btn btn-sm btn-light"
                                                        style={{ margin: '5px' }}
                                                    >
                                                        <Icon icon="radix-icons:cross-2" />
                                                    </button>
                                                    <img
                                                        className="w-100 h-100 object-fit-cover rounded-circle border"
                                                        src={uploadedImage.src}
                                                        alt="Preview"
                                                    />
                                                </div>
                                            ) : (
                                                <div className="mx-auto rounded-circle border d-flex align-items-center justify-content-center bg-light overflow-hidden"
                                                    style={{ width: '150px', height: '150px' }}>
                                                    <Icon
                                                        icon="mdi:account-circle"
                                                        className="text-secondary"
                                                        width="100%"
                                                        height="100%"
                                                    />
                                                </div>
                                            )}
                                        </div>

                                        <label className="d-flex align-items-center justify-content-center btn btn-outline-primary w-100">
                                            <Icon icon="solar:camera-outline" className="me-3" />
                                            Upload Photo
                                            <input
                                                type="file"
                                                hidden
                                                onChange={handleFileChange}
                                                accept="image/*"
                                            />
                                        </label>
                                        <small className="text-muted d-block">
                                            JPG or PNG, max 5MB
                                        </small>
                                    </div>
                                </div>
                            </div>

                            <div className="col-md-8">
                                <div className="card mb-4">
                                    <div className="card-header bg-light">
                                        <h6 className="d-flex align-content-center mb-0">
                                            <Icon icon="mdi:account-school" className="me-3" />
                                            Student Information
                                        </h6>
                                    </div>
                                    <div className="card-body">
                                        <div className="row g-3">
                                            <div className="col-md-6">
                                                <label className="form-label">
                                                    First Name <Required />
                                                </label>
                                                <input
                                                    name="first_name"
                                                    className="form-control"
                                                    placeholder="Enter student's first name"
                                                    value={firstName}
                                                    onChange={(e) => setFirstName(e.target.value)}
                                                    required
                                                />
                                            </div>

                                            <div className="col-md-6">
                                                <label className="form-label">
                                                    Last Name <Required />
                                                </label>
                                                <input
                                                    name="last_name"
                                                    className="form-control"
                                                    placeholder="Enter student's last name"
                                                    value={lastName}
                                                    onChange={(e) => setLastName(e.target.value)}
                                                    required
                                                />
                                            </div>

                                            <div className="col-md-3">
                                                <label className="form-label">
                                                    Age <Required />
                                                </label>
                                                <input
                                                    name="age"
                                                    type="number"
                                                    className="form-control"
                                                    placeholder="e.g., 10"
                                                    value={age}
                                                    onChange={(e) => setAge(e.target.value)}
                                                    min="1"
                                                    max="25"
                                                    required
                                                />
                                            </div>

                                            <div className="col-md-3">
                                                <label className="form-label">
                                                    Gender <Required />
                                                </label>
                                                <select
                                                    className="form-control"
                                                    value={gender}
                                                    onChange={(e) => setGender(e.target.value)}
                                                    required
                                                >
                                                    <option value="male">Male</option>
                                                    <option value="female">Female</option>
                                                </select>
                                            </div>

                                            <div className="col-md-6">
                                                <label className="form-label">
                                                    Date of Birth <Required />
                                                </label>
                                                <input
                                                    name="date"
                                                    type="date"
                                                    className="form-control"
                                                    value={dateOfBirth}
                                                    onChange={(e) => setDateOfBirth(e.target.value)}
                                                    max={new Date().toISOString().split('T')[0]}
                                                    required
                                                />
                                            </div>

                                            <div className="col-md-6">
                                                <label className="form-label">
                                                    Email <Required />
                                                </label>
                                                <input
                                                    name="email"
                                                    type="email"
                                                    className="form-control"
                                                    placeholder="student@example.com"
                                                    value={email}
                                                    onChange={(e) => setEmail(e.target.value)}
                                                    required
                                                />
                                                <small className="text-muted">Used for login and must be unique</small>
                                            </div>

                                            <div className="col-md-6">
                                                <label className="form-label">Enrollment Year</label>
                                                <input
                                                    name="year"
                                                    type="number"
                                                    className="form-control"
                                                    placeholder="e.g., 2024"
                                                    value={enrollmentYear}
                                                    onChange={(e) => setEnrollmentYear(e.target.value)}
                                                    min="2000"
                                                    max="2100"
                                                />
                                                <small className="text-muted">Year student enrolled in school</small>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div className="col-12">
                                <div className="card mb-4">
                                    <div className="card-header bg-light">
                                        <h6 className="d-flex align-content-center mb-0">
                                            <Icon icon="mdi:account-group" className="me-3" />
                                            Parent Information
                                        </h6>
                                    </div>
                                    <div className="card-body">
                                        <div className="row g-3">
                                            <div className="col-md-4">
                                                <label className="form-label">Parent First Name</label>
                                                <input
                                                    name="first_name"
                                                    className="form-control"
                                                    placeholder="Parent's first name"
                                                    value={parentFirstName}
                                                    onChange={(e) => setParentFirstName(e.target.value)}
                                                />
                                            </div>

                                            <div className="col-md-4">
                                                <label className="form-label">Parent Last Name</label>
                                                <input
                                                    name="last_name"
                                                    className="form-control"
                                                    placeholder="Parent's last name"
                                                    value={parentLastName}
                                                    onChange={(e) => setParentLastName(e.target.value)}
                                                />
                                            </div>

                                            <div className="col-md-4">
                                                <label className="form-label">Phone Number</label>
                                                <input
                                                    name="khphone"
                                                    type="tel"
                                                    className="form-control"
                                                    placeholder="e.g., 0123456789"
                                                    value={phone}
                                                    onChange={(e) => setPhone(e.target.value)}
                                                />
                                                <small className="text-muted">Optional contact number</small>
                                            </div>

                                            <div className="col-12">
                                                <label className="form-label">Address</label>
                                                <textarea
                                                    className="form-control"
                                                    placeholder="Full residential address"
                                                    rows="2"
                                                    value={address}
                                                    onChange={(e) => setAddress(e.target.value)}
                                                />
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div className="col-12">
                                <div className="card mb-4">
                                    <div className="card-header bg-light">
                                        <h6 className="d-flex align-content-center mb-0">
                                            <Icon icon="mdi:lock" className="me-3" />
                                            Account Credentials
                                        </h6>
                                    </div>
                                    <div className="card-body">
                                        <div className="row g-3">
                                            <div className="col-md-6">
                                                <label className="form-label">
                                                    Password <Required />
                                                </label>
                                                <input
                                                    type="password"
                                                    className="form-control"
                                                    placeholder="Minimum 6 characters"
                                                    value={password}
                                                    onChange={(e) => setPassword(e.target.value)}
                                                    required
                                                />
                                                <small className="text-muted">For student login</small>
                                            </div>

                                            <div className="col-md-6">
                                                <label className="form-label">
                                                    Confirm Password <Required />
                                                </label>
                                                <input
                                                    type="password"
                                                    className="form-control"
                                                    placeholder="Re-enter password"
                                                    value={confirmPassword}
                                                    onChange={(e) => setConfirmPassword(e.target.value)}
                                                    required
                                                />
                                                <small className="text-muted">Must match the password above</small>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div className="col-12">
                                <div className="d-flex justify-content-end align-items-end gap-2">
                                    <button className="d-flex align-items-center btn btn-primary" type="submit">
                                        <Icon icon="mdi:plus" className="me-3" />
                                        <div>Create Student</div>
                                    </button>
                                    <button
                                        type="button"
                                        className="d-flex align-items-center btn btn-secondary"
                                        onClick={resetForm}
                                    >
                                        <Icon icon="mdi:refresh" className="me-3" />
                                        Reset Form
                                    </button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </SchoolLayout>
    );
}