import React, { useEffect, useState, useMemo } from "react";
import { Icon } from "@iconify/react";
import { Link } from "react-router-dom";

import API from "../../../helper/api";
import { useAuth } from "../../../context/AuthContext";
import MasterLayout from "../../../masterLayout/MasterLayout";
import AdminPageHeader from "../../../components/admin/common/AdminPageHeader";
import AdminErrorState from "../../../components/admin/common/AdminErrorState";
import AdminPagination from "../../../components/admin/common/AdminPagination";

const Trunc = ({ value, maxWidth = 260 }) => {
  const v = value ?? "—";
  return (
    <div className="text-truncate text-secondary-light" style={{ maxWidth }} title={String(v)}>
      {v}
    </div>
  );
};

const normalizeExercise = (e) => ({
  ...e,
  id: e?.id ?? "—",
  character_type: e?.character_type ?? "—",
  character: e?.character ?? "—",
  prompt: e?.prompt ?? "—",
  question: e?.question ?? "—",
  instruction: e?.instruction ?? "—",
  hint: e?.hint ?? "—",
  used_count: e?.used_count ?? e?.stage_exercises_count ?? "—",
  updated_at: e?.updated_at ?? null,
});

const prettyDate = (d) => {
  if (!d) return "—";
  const dt = new Date(d);
  if (Number.isNaN(dt.getTime())) return String(d);
  return dt.toLocaleDateString();
};

const ExerciseList = () => {
  const { hasPermission, hasAnyPermission } = useAuth();
  const canAnyAction = hasAnyPermission(["exercises.view", "exercises.update"]);

  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  // Filter state
  const [q, setQ] = useState("");
  const [characterType, setCharacterType] = useState("");
  const [character, setCharacter] = useState("");
  const [perPage, setPerPage] = useState(25);
  const [currentPage, setCurrentPage] = useState(1);

  const fetchExercises = async () => {
    setLoading(true);
    setError("");
    try {
      const params = { per_page: perPage };

      if (q.trim()) params.q = q.trim();
      if (characterType) params.character_type = characterType;
      if (character.trim()) params.character = character.trim();

      const res = await API.get("/admin/exercises", { params });
      const payload = res.data?.data ?? res.data;

      const raw = Array.isArray(payload?.exercises)
        ? payload.exercises
        : payload?.exercises?.data;

      const list = Array.isArray(raw) ? raw : [];
      setRows(list.map(normalizeExercise));
    } catch (err) {
      console.error("Fetch exercises failed:", err);
      setError(err?.response?.data?.message || "Failed to load exercises.");
      setRows([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const t = setTimeout(() => {
      fetchExercises();
    }, 350);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q, characterType, character, perPage]);

  const totalPages = Math.ceil(rows.length / 10) || 1;
  const paginatedRows = useMemo(() => {
    const start = (currentPage - 1) * 10;
    return rows.slice(start, start + 10);
  }, [rows, currentPage]);

  const handleClearFilters = () => {
    setQ("");
    setCharacterType("");
    setCharacter("");
    setCurrentPage(1);
  };

  return (
    <MasterLayout>
      <div className="py-12">
        <AdminPageHeader
          title="Exercise Management"
          subtitle="Manage learning exercises, prompts, character types, and hints"
          primaryAction={
            hasPermission("exercises.create")
              ? {
                  label: "Create Exercise",
                  to: "/admin/exercises/create",
                  icon: "mdi:plus",
                }
              : null
          }
        />

        {/* Filter and Search Bar */}
        <div className="card border radius-12 shadow-none mb-20">
          <div className="card-body p-16 d-flex flex-wrap align-items-center justify-content-between gap-16">
            <div className="d-flex flex-wrap align-items-center gap-12 flex-grow-1">
              <div className="input-group" style={{ maxWidth: "300px" }}>
                <span className="input-group-text bg-base text-secondary-light border-end-0 radius-8-left">
                  <Icon icon="mdi:magnify" width="18" />
                </span>
                <input
                  type="text"
                  className="form-control border-start-0 ps-0 radius-8-right"
                  placeholder="Search prompt, question, hint..."
                  value={q}
                  onChange={(e) => {
                    setQ(e.target.value);
                    setCurrentPage(1);
                  }}
                />
              </div>

              <select
                className="form-select w-auto radius-8"
                value={characterType}
                onChange={(e) => {
                  setCharacterType(e.target.value);
                  setCurrentPage(1);
                }}
              >
                <option value="">All Types</option>
                <option value="digits">digits</option>
                <option value="consonants">consonants</option>
                <option value="independent_vowels">independent_vowels</option>
                <option value="dependent_vowels">dependent_vowels</option>
              </select>

              <input
                type="text"
                className="form-control w-auto radius-8"
                style={{ width: "130px" }}
                placeholder="Char (e.g. ក)"
                value={character}
                onChange={(e) => {
                  setCharacter(e.target.value);
                  setCurrentPage(1);
                }}
              />

              {(q || characterType || character) && (
                <button
                  type="button"
                  className="btn btn-outline-secondary btn-sm radius-8 d-inline-flex align-items-center gap-6"
                  onClick={handleClearFilters}
                >
                  <Icon icon="mdi:filter-off-outline" />
                  <span>Clear Filters</span>
                </button>
              )}
            </div>

            <div className="text-secondary-light text-sm">
              Total: <strong>{rows.length}</strong> exercises
            </div>
          </div>
        </div>

        {error ? (
          <AdminErrorState message={error} onRetry={fetchExercises} />
        ) : (
          <div className="card border radius-12 shadow-none">
            <div className="card-body p-0">
              <div className="table-responsive">
                <table className="table bordered-table mb-0 align-middle">
                  <thead>
                    <tr>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">ID</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Type</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Character</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Prompt / Question</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Instruction / Hint</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16 text-center">Used</th>
                      <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16">Updated</th>
                      {canAnyAction && (
                        <th scope="col" className="text-xs text-uppercase fw-semibold py-12 px-16 text-center">Action</th>
                      )}
                    </tr>
                  </thead>

                  <tbody>
                    {loading ? (
                      Array.from({ length: 5 }).map((_, idx) => (
                        <tr key={idx}>
                          <td className="py-16 px-16"><div className="skeleton-loader py-10 w-100"></div></td>
                          <td className="py-16 px-16"><div className="skeleton-loader py-10 w-100"></div></td>
                          <td className="py-16 px-16"><div className="skeleton-loader py-10 w-100"></div></td>
                          <td className="py-16 px-16"><div className="skeleton-loader py-10 w-100"></div></td>
                          <td className="py-16 px-16"><div className="skeleton-loader py-10 w-100"></div></td>
                          <td className="py-16 px-16"><div className="skeleton-loader py-10 w-100"></div></td>
                          <td className="py-16 px-16"><div className="skeleton-loader py-10 w-100"></div></td>
                          {canAnyAction && <td className="py-16 px-16"><div className="skeleton-loader py-10 w-100"></div></td>}
                        </tr>
                      ))
                    ) : paginatedRows.length === 0 ? (
                      <tr>
                        <td colSpan={canAnyAction ? 8 : 7} className="text-center text-secondary-light py-40">
                          <Icon icon="mdi:script-text-off-outline" width="48" className="mb-12 opacity-50" />
                          <h6>No exercises found</h6>
                          <p className="text-xs text-secondary-light mb-0">Try adjusting your search query or filter options.</p>
                        </td>
                      </tr>
                    ) : (
                      paginatedRows.map((e) => (
                        <tr key={e.id} className="hover-bg-neutral-50 transition-1">
                          <td className="py-12 px-16 text-sm font-monospace text-secondary-light">#{e.id}</td>
                          <td className="py-12 px-16 text-sm">
                            <span className="badge bg-primary-50 text-primary-600 border border-primary-100 radius-4 text-xs">
                              {e.character_type}
                            </span>
                          </td>
                          <td className="py-12 px-16 text-sm fw-bold text-dark">{e.character}</td>
                          <td className="py-12 px-16 text-sm text-dark">
                            <Trunc value={e.prompt !== "—" ? e.prompt : e.question} maxWidth={380} />
                          </td>
                          <td className="py-12 px-16 text-sm text-secondary-light">
                            <Trunc value={e.instruction !== "—" ? e.instruction : e.hint} maxWidth={320} />
                          </td>
                          <td className="py-12 px-16 text-center text-sm fw-semibold text-dark">{e.used_count}</td>
                          <td className="py-12 px-16 text-sm text-secondary-light">{prettyDate(e.updated_at)}</td>

                          {canAnyAction && (
                            <td className="py-12 px-16 text-center align-middle">
                              <div className="d-inline-flex align-items-center gap-6">
                                {hasPermission("exercises.view") && (
                                  <Link
                                    to={`/admin/exercises/${e.id}`}
                                    className="w-32-px h-32-px radius-8 bg-primary-50 text-primary-600 d-inline-flex align-items-center justify-content-center"
                                    title="View Exercise"
                                  >
                                    <Icon icon="iconamoon:eye-light" />
                                  </Link>
                                )}

                                {hasPermission("exercises.update") && (
                                  <Link
                                    to={`/admin/exercises/${e.id}/edit`}
                                    className="w-32-px h-32-px radius-8 bg-success-50 text-success-600 d-inline-flex align-items-center justify-content-center"
                                    title="Edit Exercise"
                                  >
                                    <Icon icon="lucide:edit" />
                                  </Link>
                                )}
                              </div>
                            </td>
                          )}
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>

              {!loading && rows.length > 0 && (
                <div className="card-footer py-14 px-24 border-top d-flex align-items-center justify-content-between flex-wrap gap-12">
                  <div className="text-secondary-light text-xs font-semibold">
                    Showing {(currentPage - 1) * perPage + 1}–
                    {Math.min(currentPage * perPage, rows.length)} of {rows.length} entries
                  </div>
                  {totalPages > 1 && (
                    <div className="ms-auto">
                      <AdminPagination
                        page={currentPage}
                        totalPages={totalPages}
                        onPageChange={setCurrentPage}
                      />
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </MasterLayout>
  );
};

export default ExerciseList;
