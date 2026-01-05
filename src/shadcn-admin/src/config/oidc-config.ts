import type { AuthProviderProps } from 'react-oidc-context'

// OIDC configuration for Identity.API
// In development, the Identity.API runs on https://localhost:5243
// In production, this should be configured via environment variables
const identityUrl = import.meta.env.VITE_IDENTITY_URL || 'https://localhost:5243'
const adminUrl = import.meta.env.VITE_ADMIN_URL || 'http://localhost:5173'

export const oidcConfig: AuthProviderProps = {
  authority: identityUrl,
  client_id: 'chillax-admin',
  redirect_uri: `${adminUrl}/signin-callback`,
  post_logout_redirect_uri: adminUrl,
  response_type: 'code',
  scope: 'openid profile email orders rooms catalog',
  automaticSilentRenew: true,
  loadUserInfo: true,
  onSigninCallback: () => {
    // Remove the code and state from the URL after successful sign-in
    window.history.replaceState({}, document.title, window.location.pathname)
  },
}
