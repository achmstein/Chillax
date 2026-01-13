import type { AuthProviderProps } from 'react-oidc-context'

// OIDC configuration for Keycloak
// In development, Keycloak runs on http://localhost:8080
// In production, this should be configured via environment variables
const keycloakUrl = import.meta.env.VITE_KEYCLOAK_URL || 'http://localhost:8080'
const realm = import.meta.env.VITE_KEYCLOAK_REALM || 'chillax'
const adminUrl = import.meta.env.VITE_ADMIN_URL || 'http://localhost:5173'

export const oidcConfig: AuthProviderProps = {
  authority: `${keycloakUrl}/realms/${realm}`,
  client_id: 'admin-panel',
  redirect_uri: `${adminUrl}/auth/callback`,
  post_logout_redirect_uri: adminUrl,
  response_type: 'code',
  scope: 'openid profile email roles orders rooms catalog',
  automaticSilentRenew: true,
  loadUserInfo: true,
  onSigninCallback: () => {
    // Remove the code and state from the URL after successful sign-in
    window.history.replaceState({}, document.title, window.location.pathname)
  },
}
