// Auth helper functions for Maestro tests

/**
 * Login with email and password
 */
export function loginWithEmail(email: string, password: string): Record<string, any> {
  return {
    intent: [
      {
        tapOn: { text: 'Email', optional: true },
      },
      {
        tapOn: { text: 'Sign in', optional: true },
      },
      {
        tapOn: { id: 'input-email', optional: true },
      },
      {
        inputText: { text: email, id: 'email' },
      },
      {
        inputText: { text: password, id: 'password' },
      },
      {
        tapOn: { text: 'Sign in', optional: true },
      },
    ],
  };
}

/**
 * Logout helper
 */
export function logout(): Record<string, any> {
  return {
    intent: [
      {
        tapOn: { text: 'Profile', optional: true },
      },
      {
        scrollUntilVisible: { element: { text: 'Logout' } },
      },
      {
        tapOn: { text: 'Logout' },
      },
      {
        tapOn: { text: 'Confirm', optional: true },
      },
    ],
  };
}

/**
 * Wait for login screen to appear
 */
export function waitForLoginScreen(): Record<string, any> {
  return {
    waitForAppToIdle: {},
  };
}
