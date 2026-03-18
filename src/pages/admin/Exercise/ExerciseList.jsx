import React, { useEffect, useRef, useState } from "react";
import $ from "jquery";
import "datatables.net-dt/js/dataTables.dataTables.js";
import { Icon } from "@iconify/react";
import { Link } from "react-router-dom";

import API from "../../../helper/api";
import { useAuth } from "../../../context/AuthContext";
import MasterLayout from "../../../masterLayout/MasterLayout";

const Trunc = ({ value, maxWidth = 260 }) => {
  const v = value ?? "—";
  return (
    <div className="text-truncate" style={{ maxWidth }} title={String(v)}>
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

  const dtRef = useRef(null);

  const canAnyAction = hasAnyPermission(["exercises.view", "exercises.update"]);

  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);

  // filters (auto fetch)
  const [q, setQ] = useState("");
  const [characterType, setCharacterType] = useState("");
  const [character, setCharacter] = useState("");

  // API fetch size (what you wanted)
  const [perPage, setPerPage] = useState(25);

  const fetchExercises = async () => {
    setLoading(true);
    try {
      const params = { per_page: perPage };

      if (q.trim()) params.q = q.trim();
      if (characterType) params.character_type = characterType;
      if (character.trim()) params.character = character.trim();

      const res = await API.get("/admin/exercises", { params });
      const payload = res.data?.data ?? res.data;

      // paginator or array
      const raw = Array.isArray(payload?.exercises)
        ? payload.exercises
        : payload?.exercises?.data;

      const list = Array.isArray(raw) ? raw : [];
      setRows(list.map(normalizeExercise));
    } catch (err) {
      console.error("Fetch exercises failed:", err);
      setRows([]);
    } finally {
      setLoading(false);
    }
  };

  // initial load
  useEffect(() => {
    fetchExercises();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // auto-refetch when perPage changes
  useEffect(() => {
    fetchExercises();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [perPage]);

  // debounce fetch when filters change (so typing doesn't spam API)
  useEffect(() => {
    const t = setTimeout(() => {
      fetchExercises();
    }, 350);

    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q, characterType, character]);

  // DataTable init/re-init
  useEffect(() => {
    // destroy previous datatable before re-init
    if (dtRef.current) {
      dtRef.current.destroy();
      dtRef.current = null;
    }

    // Only init when data loaded (or even when empty so table UI stays consistent)
    if (!loading) {
      const t = setTimeout(() => {
        dtRef.current = $("#exerciseTable").DataTable({
          destroy: true,
          pageLength: 10,
          scrollX: true,
          scrollCollapse: true,
          autoWidth: true,
          order: [[0, "desc"]], // default sort (click header to toggle)
          columnDefs: [
            { targets: 0, width: "80px" },   // ID
            { targets: 1, width: "150px" },  // Type
            { targets: 2, width: "120px" },  // Character
            { targets: 3, width: "320px" },  // Prompt/Question
            { targets: 4, width: "260px" },  // Instruction/Hint
            { targets: 5, width: "120px" },  // Used
            { targets: 6, width: "140px" },  // Updated
            ...(canAnyAction ? [{ targets: 7, width: "140px" }] : []),
          ],
        });
      }, 0);

      return () => clearTimeout(t);
    }

    return () => {
      if (dtRef.current) {
        dtRef.current.destroy();
        dtRef.current = null;
      }
    };
  }, [rows, loading, canAnyAction]);

  return (
    <MasterLayout>
      <div className="card basic-data-table">
        <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
          <h5 className="mb-0">Exercises</h5>

          <div className="d-flex gap-2 flex-wrap">
            {hasPermission("exercises.create") && (
              <Link to="/admin/exercises/create">
                <button
                  type="button"
                  className="d-flex align-items-center btn btn-primary-600 radius-3 px-20 py-11"
                >
                  <Icon icon="mdi:plus" className="me-8" />
                  Create
                </button>
              </Link>
            )}
          </div>
        </div>

        <div className="card-body">
          {/* Filters (no reset, auto fetch) */}
          <div className="mb-3">
            <div className="row g-2 align-items-end">
              <div className="col-12 col-md-4">
                <label className="form-label mb-1">Search</label>
                <div className="input-group">
                  <span className="input-group-text">
                    <Icon icon="mdi:magnify" />
                  </span>
                  <input
                    className="form-control"
                    placeholder="prompt, question, instruction, hint..."
                    value={q}
                    onChange={(e) => setQ(e.target.value)}
                  />
                </div>
              </div>

              <div className="col-12 col-md-3">
                <label className="form-label mb-1">Character Type</label>
                <select
                  className="form-control"
                  value={characterType}
                  onChange={(e) => setCharacterType(e.target.value)}
                >
                  <option value="">All</option>
                  <option value="digits">digits</option>
                  <option value="consonants">consonants</option>
                  <option value="independent_vowels">independent_vowels</option>
                  <option value="dependent_vowels">dependent_vowels</option>
                </select>
              </div>

              <div className="col-12 col-md-2">
                <label className="form-label mb-1">Character</label>
                <input
                  className="form-control"
                  placeholder="e.g., ក"
                  value={character}
                  onChange={(e) => setCharacter(e.target.value)}
                />
              </div>

              {/* per_page selector */}
              <div className="col-12 col-md-1">
                <label className="form-label mb-1">Show</label>
                <select
                  className="form-control"
                  value={perPage}
                  onChange={(e) => setPerPage(parseInt(e.target.value, 10))}
                  title="API per_page"
                >
                  <option value={25}>25</option>
                  <option value={50}>50</option>
                  <option value={100}>100</option>
                </select>
              </div>

              <div className="col-12 col-md-2 text-end">
                {loading && (
                  <div className="text-muted small d-inline-flex align-items-center gap-2">
                    <span className="spinner-border spinner-border-sm" />
                    Loading...
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Table */}
          <div className="table-responsive">
            <table className="table bordered-table mb-0" id="exerciseTable" data-page-length={10}>
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Type</th>
                  <th>Character</th>
                  <th>Prompt / Question</th>
                  <th>Instruction / Hint</th>
                  <th className="text-center">Used</th>
                  <th>Updated</th>
                  {canAnyAction && <th className="text-center">Action</th>}
                </tr>
              </thead>

              <tbody>
                {!loading && rows.length === 0 ? (
                  <tr>
                    <td colSpan={canAnyAction ? 8 : 7} className="text-center">
                      No exercises found
                    </td>
                  </tr>
                ) : (
                  rows.map((e) => (
                    <tr key={e.id}>
                      <td>{e.id}</td>

                      <td>
                        <span className="badge bg-light text-dark">{e.character_type}</span>
                      </td>

                      <td className="fw-semibold">{e.character}</td>

                      <td>
                        <Trunc value={e.prompt !== "—" ? e.prompt : e.question} maxWidth={420} />
                      </td>

                      <td>
                        <Trunc value={e.instruction !== "—" ? e.instruction : e.hint} maxWidth={360} />
                      </td>

                      <td className="text-center">{e.used_count}</td>

                      <td>{prettyDate(e.updated_at)}</td>

                      {canAnyAction && (
                        <td className="text-center align-middle">
                          {hasPermission("exercises.view") && (
                            <Link
                              to={`/admin/exercises/${e.id}`}
                              className="w-32-px h-32-px me-8 bg-primary-light text-primary-600 rounded-circle d-inline-flex align-items-center justify-content-center"
                              title="View"
                            >
                              <Icon icon="iconamoon:eye-light" />
                            </Link>
                          )}

                          {hasPermission("exercises.update") && (
                            <Link
                              to={`/admin/exercises/${e.id}/edit`}
                              className="w-32-px h-32-px me-8 bg-success-focus text-success-main rounded-circle d-inline-flex align-items-center justify-content-center"
                              title="Edit"
                            >
                              <Icon icon="lucide:edit" />
                            </Link>
                          )}
                        </td>
                      )}
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          {/* DataTables will render pagination/footer automatically */}
        </div>
      </div>
    </MasterLayout>
  );
};

export default ExerciseList;
