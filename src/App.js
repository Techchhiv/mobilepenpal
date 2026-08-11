import React from "react";
import { Routes, Route, Navigate } from "react-router-dom";
import RouteScrollToTop from "./helper/RouteScrollToTop";
import Gate from "./components/router/Gate";

// ---------- Public Pages ----------
import SignInPage from "./pages/SignInPage";
import SignUpPage from "./pages/SignUpPage";
import OAuthSuccess from "./helper/OAuthSuccess";
import AccessDeniedPage from "./pages/AccessDeniedPage";

// ---------- Admin Pages ----------
import AdminDashboardPage from "./pages/admin/AdminDashboardPage";
import AdminUsersPage from "./pages/admin/AdminUsersPage";
import AdminRolesPage from "./pages/admin/AdminRolesPage";
import AdminPermissionsPage from "./pages/admin/AdminPermissionsPage";
import ManageClientsPage from "./pages/admin/ManageClientsPage";
import ManagePaymentsPage from "./pages/admin/ManagePaymentsPage";
import SchoolPayments from "./pages/admin/SchoolPayments";
import SchoolSubscriptionsPage from "./pages/admin/Subscriptions/SchoolSubscriptionsPage";
import UserSubscriptionsPage from "./pages/admin/Subscriptions/UserSubscriptionsPage";
import AdminStudentList from "./pages/admin/Student/StudentList";
import AdminStudentCreate from "./pages/admin/Student/StudentCreate";
import AdminStudentEdit from "./pages/admin/Student/StudentEdit";
import AdminStudentView from "./pages/admin/Student/StudentView";

// ---------- School Pages ----------
import SchoolSignInLayer from "./pages/school/page/SchoolSignin";
import SchoolDashboard from "./pages/school/page/SchoolDashboard";
import SchoolProfilePage from "./pages/school/page/SchoolProfilePage";
import ManageTeacher from "./pages/school/page/ManageTeacher";
import SchoolUsersPage from "./pages/school/page/SchoolUsersPage";
import SchoolRolesPage from "./pages/school/page/SchoolRolesPage";
import SchoolPermissionsPage from "./pages/school/page/SchoolPermissionsPage";
import TeacherList from "./pages/school/page/Teacher/TeacherList";
import TeacherCreate from "./pages/school/page/Teacher/TeacherCreate";
import ClassRoomsList from "./pages/school/page/Classrooms/ClassRoomsList";
import StudentList from "./pages/school/page/Student/StudentList";
import StudentCreate from "./pages/school/page/Student/StudentCreate";
import StudentEdit from "./pages/school/page/Student/StudentEdit";
import ClassroomCreate from "./pages/school/page/Classrooms/ClassroomCreate";
import StudentView from "./pages/school/page/Student/StudentView";
import TeacherEdit from "./pages/school/page/Teacher/TeacherEdit";
import TeacherView from "./pages/school/page/Teacher/TeacherView";
import ClassroomView from "./pages/school/page/Classrooms/ClassromView";
import ClassroomEdit from "./pages/school/page/Classrooms/ClassroomEdit";
import ClassroomStudentProgress from "./pages/school/page/Classrooms/ClassroomStudentProgress";
import WorldList from "./pages/admin/World/WorldList";
import WorldView from "./pages/admin/World/WorldView";
import WorldEdit from "./pages/admin/World/WorldEdit";
import WorldCreate from "./pages/admin/World/WorldCreate";
import LevelList from "./pages/admin/Level/LevelList";
import LevelCreate from "./pages/admin/Level/LevelCreate";
import LevelView from "./pages/admin/Level/LevelView";
import LevelEdit from "./pages/admin/Level/LevelEdit";
import StageList from "./pages/admin/Stage/StageList";
import StageCreate from "./pages/admin/Stage/StageCreate";
import StageView from "./pages/admin/Stage/StageView";
import StageEdit from "./pages/admin/Stage/StageEdit";
import ExerciseList from "./pages/admin/Exercise/ExerciseList";
import ExerciseView from "./pages/admin/Exercise/ExerciseView";
import ExerciseEdit from "./pages/admin/Exercise/ExerciseEdit";
import ExerciseCreate from "./pages/admin/Exercise/ExerciseCreate";
import SchoolWorldList from "./pages/school/page/World/SchoolWorldList";
import SchoolWorldCreate from "./pages/school/page/World/SchoolWorldCreate";
import SchoolWorldView from "./pages/school/page/World/SchoolWorldView";
import SchoolWorldEdit from "./pages/school/page/World/SchoolWorldEdit";
import SchoolLevelList from "./pages/school/page/Level/SchoolLevelList";
import SchoolLevelEdit from "./pages/school/page/Level/SchoolLevelEdit";
import SchoolLevelView from "./pages/school/page/Level/SchoolLevelView";
import AdminSchoolReportsPage from "./pages/admin/AdminSchoolReportsPage";
import QuestionTemplateList from "./pages/admin/QuestionTemplate/QuestionTemplateList";
import QuestionTemplateCreate from "./pages/admin/QuestionTemplate/QuestionTemplateCreate";
import QuestionTemplateEdit from "./pages/admin/QuestionTemplate/QuestionTemplateEdit";
import AuditLogPage from "./pages/admin/AuditLogPage";

export default function App() {
  return (
    <>
      <RouteScrollToTop />
      <Routes>
        {/* ---------- Public Routes ---------- */}
        <Route path="/sign-in-admin" element={<SignInPage />} />
        <Route path="/sign-in-school" element={<SchoolSignInLayer />} />
        <Route path="/sign-up" element={<SignUpPage />} />
        <Route path="/oauth-success" element={<OAuthSuccess />} />
        <Route path="/access-denied" element={<AccessDeniedPage />} />

        {/* ---------- Admin Dashboard (all logged-in users) ---------- */}
        <Route
          path="/admin"
          element={
            <Gate>
              <AdminDashboardPage />
            </Gate>
          }
        />

        {/* ---------- Users / Roles / Permissions (Super Admin / Admin only) ---------- */}
        <Route
          element={
            <Gate
              anyPerm={["users.manage", "roles.manage", "permissions.manage"]}
            />
          }
        >
          <Route path="/admin/users" element={<AdminUsersPage />} />
          <Route path="/admin/roles" element={<AdminRolesPage />} />
          <Route path="/admin/permissions" element={<AdminPermissionsPage />} />
          <Route path="/admin/reports" element={<AdminSchoolReportsPage />} />
        </Route>

        {/* ---------- Manage Clients (Client Manager only) ---------- */}
        <Route element={<Gate anyPerm={["menu.manage_clients"]} />}>
          <Route path="/admin/schools" element={<ManageClientsPage />} />
        </Route>

        {/* ---------- Admin Student Management ---------- */}
        <Route
          element={
            <Gate
              anyPerm={[
                "student.view",
                "student.create",
                "student.update",
                "student.delete",
              ]}
            />
          }
        >
          <Route path="/admin/students" element={<AdminStudentList />} />
          <Route path="/admin/students/create" element={<AdminStudentCreate />} />
          <Route path="/admin/students/:id/edit" element={<AdminStudentEdit />} />
          <Route path="/admin/students/:id" element={<AdminStudentView />} />
        </Route>


        {/* ---------- Payments (Payment Manager only) ---------- */}
        <Route element={<Gate anyPerm={["menu.payments"]} />}>
          <Route path="/admin/payments" element={<ManagePaymentsPage />} />
          <Route
            path="/admin/schools/:schoolId/payments"
            element={<SchoolPayments />}
          />
        </Route>

        {/* ---------- Subscriptions ---------- */}
        <Route element={<Gate anyPerm={["menu.subscription"]} />}>
          <Route path="/admin/subscriptions/schools" element={<SchoolSubscriptionsPage />} />
          <Route path="/admin/subscriptions/users" element={<UserSubscriptionsPage />} />
        </Route>

        <Route
          element={
            <Gate
              anyPerm={[
                "worlds.view",
                "worlds.create",
                "worlds.delete",
                "world.view",
                "world.create",
                "world.delete",
              ]}
            />
          }
        >
          <Route path="/admin/worlds" element={<WorldList />} />
          <Route path="/admin/worlds/:id" element={<WorldView />} />
          <Route path="/admin/worlds/:id/edit" element={<WorldEdit />} />
          <Route path="/admin/worlds/create" element={<WorldCreate />} />
        </Route>

        <Route
          element={
            <Gate
              anyPerm={[
                "levels.view",
                "levels.create",
                "levels.delete",
                "level.view",
                "level.create",
                "level.delete",
              ]}
            />
          }
        >
          {/* <Route path="/admin/levels" element={<LevelList />} /> */}
          <Route path="/admin/levels/create" element={<LevelCreate />} />
          <Route path="/admin/levels/:id" element={<LevelView />} />
          <Route path="/admin/levels/:id/edit" element={<LevelEdit />} />
        </Route>

        <Route
          element={
            <Gate
              anyPerm={[
                "stages.view",
                "stages.create",
                "stages.delete",
                "stage.view",
                "stage.create",
                "stage.delete",
              ]}
            />
          }
        >
          <Route path="/admin/stages" element={<StageList />} />
          <Route path="/admin/stages/:id" element={<StageView />} />
          <Route path="/admin/stages/create" element={<StageCreate />} />
          <Route path="/admin/stages/:id/edit" element={<StageEdit />} />
        </Route>

        <Route
          element={
            <Gate
              anyPerm={[
                "exercises.view",
                "exercises.create",
                "exercises.update",
              ]}
            />
          }
        >
          <Route path="/admin/exercises" element={<ExerciseList />} />
          <Route path="/admin/exercises/create" element={<ExerciseCreate />} />
          <Route path="/admin/exercises/:id" element={<ExerciseView />} />
          <Route path="/admin/exercises/:id/edit" element={<ExerciseEdit />} />
        </Route>

        <Route
          element={
            <Gate
              anyPerm={[
                "question_templates.view",
                "question_templates.create",
                "question_templates.update",
              ]}
            />
          }
        >
          <Route path="/admin/question-templates" element={<QuestionTemplateList />} />
          <Route path="/admin/question-templates/create" element={<QuestionTemplateCreate />} />
          <Route path="/admin/question-templates/:id/edit" element={<QuestionTemplateEdit />} />
        </Route>

        <Route
          path="/school"
          element={
            <Gate>
              <SchoolDashboard />
            </Gate>
          }
        />
        <Route path="/school/profile" element={<SchoolProfilePage />} />

        {/* ---------- School Routes ---------- */}
        <Route
          element={
            <Gate
              anyPerm={["users.manage", "roles.manage", "permissions.manage"]}
            />
          }
        >
          <Route path="/school/users" element={<SchoolUsersPage />} />
          <Route path="/school/roles" element={<SchoolRolesPage />} />
          <Route
            path="/school/permissions"
            element={<SchoolPermissionsPage />}
          />
        </Route>
        <Route
          element={
            <Gate
              anyPerm={[
                "teachers.view",
                "teachers.update",
                "teachers.create",
                "classrooms.view",
                "classroom.view",
              ]}
            />
          }
        >
          <Route path="/school/teachers" element={<TeacherList />} />
          <Route path="/school/teachers/create" element={<TeacherCreate />} />
          <Route path="/school/teachers/:id" element={<TeacherView />} />
          <Route path="/school/teachers/:id/edit" element={<TeacherEdit />} />
        </Route>
        <Route
          element={
            <Gate
              anyPerm={["children.view", "children.create", "children.update"]}
            />
          }
        >
          <Route path="/school/students" element={<StudentList />} />
          <Route path="/school/students/create" element={<StudentCreate />} />
          <Route path="/school/students/:id" element={<StudentView />} />
          <Route path="/school/students/:id/edit" element={<StudentEdit />} />
        </Route>
        <Route
          element={
            <Gate
              anyPerm={[
                "classrooms.view",
                "classrooms.create",
                "classrooms.update",
              ]}
            />
          }
        >
          <Route path="/school/classrooms" element={<ClassRoomsList />} />
          <Route path="/school/classrooms/:id" element={<ClassroomView />} />
          <Route
            path="/school/classrooms/create"
            element={<ClassroomCreate />}
          />
          <Route
            path="/school/classrooms/:id/edit"
            element={<ClassroomEdit />}
          />
          <Route
            path="/school/classrooms/:classroomId/students/:studentId/progress"
            element={<ClassroomStudentProgress />}
          />
        </Route>
        <Route
          element={
            <Gate anyPerm={["worlds.view", "worlds.create", "worlds.update"]} />
          }
        >
          <Route path="/school/worlds" element={<SchoolWorldList />} />
          <Route path="/school/worlds/create" element={<SchoolWorldCreate />} />
          <Route path="/school/worlds/:id" element={<SchoolWorldView />} />
          <Route path="/school/worlds/:id/edit" element={<SchoolWorldEdit />} />

          <Route path="/school/levels/:id/edit" element={<SchoolLevelEdit />} />
          <Route path="/school/levels/:id" element={<SchoolLevelView />} />
        </Route>

        <Route path="/" element={<Navigate to="/sign-in-school" replace />} />

        {/* ---------- Super Admin: Audit Logs ---------- */}
        <Route
          path="/admin/audit-logs"
          element={
            <Gate>
              <AuditLogPage />
            </Gate>
          }
        />

        {/* ---------- Fallback ---------- */}
        <Route path="*" element={<Navigate to="/access-denied" replace />} />
      </Routes>
    </>
  );
}
