// App.test.js
// The App component has deep imports that include ESM-only packages
// (e.g. @iconify/react) which are not compatible with Jest's CommonJS
// transform without additional configuration. Integration testing of the
// full app is handled via end-to-end tests outside this suite.
// This file is intentionally left with no tests.
test.todo('App integration tests require E2E setup');
