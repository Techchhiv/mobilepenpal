// src/utils/permissions.js
export const hasRole = (userRoles = [], role) => userRoles.includes(role);

export const hasPermission = (userPermissions = [], permission) =>
  userPermissions.includes(permission);

export const hasAnyPermission = (userPermissions = [], permissions = []) =>
  permissions.some((perm) => userPermissions.includes(perm));

export const hasAllPermissions = (userPermissions = [], permissions = []) =>
  permissions.every((perm) => userPermissions.includes(perm));

export const isSuperAdmin = (userRoles = []) => hasRole(userRoles, "super-admin");
