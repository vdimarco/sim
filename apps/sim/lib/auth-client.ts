import { useContext } from 'react'
import { stripeClient } from '@better-auth/stripe/client'
import {
  customSessionClient,
  emailOTPClient,
  genericOAuthClient,
  organizationClient,
} from 'better-auth/client/plugins'
import { createAuthClient } from 'better-auth/react'
import type { auth } from '@/lib/auth'
import { env, getEnv } from '@/lib/env'
import { isProd } from '@/lib/environment'
import { SessionContext, type SessionHookResult } from '@/lib/session/session-context'

export function getBaseURL() {
  // Prefer browser origin when available (avoids hardcoding in client bundles)
  if (typeof window !== 'undefined' && window.location?.origin) {
    return window.location.origin
  }

  // Resolve common environment-based hosts (server-side or during SSR)
  const vercelEnv = env.VERCEL_ENV
  const vercelUrl = getEnv('NEXT_PUBLIC_VERCEL_URL')
  const appUrl = getEnv('NEXT_PUBLIC_APP_URL')
  const betterAuthUrl = env.BETTER_AUTH_URL

  // Explicit Vercel environments
  if (vercelEnv === 'preview' || vercelEnv === 'development') {
    if (vercelUrl) return `https://${vercelUrl}`
  }
  if (vercelEnv === 'production') {
    if (betterAuthUrl) return betterAuthUrl
    if (appUrl) return appUrl
    if (vercelUrl) return `https://${vercelUrl}`
  }

  // Generic resolution for self-hosted or non-Vercel environments
  if (betterAuthUrl) return betterAuthUrl
  if (appUrl) return appUrl
  if (vercelUrl) return `https://${vercelUrl}`

  // Sensible defaults
  if (env.NODE_ENV === 'development') return 'http://localhost:3000'
  return 'http://localhost:3000'
}

export const client = createAuthClient({
  baseURL: getBaseURL(),
  plugins: [
    emailOTPClient(),
    genericOAuthClient(),
    customSessionClient<typeof auth>(),
    // Only include Stripe client in production
    ...(isProd
      ? [
          stripeClient({
            subscription: true, // Enable subscription management
          }),
        ]
      : []),
    organizationClient(),
  ],
})

export function useSession(): SessionHookResult {
  const ctx = useContext(SessionContext)
  if (!ctx) {
    throw new Error(
      'SessionProvider is not mounted. Wrap your app with <SessionProvider> in app/layout.tsx.'
    )
  }
  return ctx
}

export const { useActiveOrganization } = client

export const useSubscription = () => {
  return {
    list: client.subscription?.list,
    upgrade: client.subscription?.upgrade,
    cancel: client.subscription?.cancel,
    restore: client.subscription?.restore,
  }
}

export const { signIn, signUp, signOut } = client
