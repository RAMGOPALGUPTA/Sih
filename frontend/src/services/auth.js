const SESSION_KEY = 'field-evidence-session'
const DEMO_OPERATOR = {
  operatorId: 'A-17',
  name: 'Ram Gupta',
  role: 'Field Officer',
}

function storage(remember) {
  return remember ? localStorage : sessionStorage
}

export function getSession() {
  const raw = localStorage.getItem(SESSION_KEY) || sessionStorage.getItem(SESSION_KEY)
  if (!raw) return null
  try {
    return JSON.parse(raw)
  } catch {
    return null
  }
}

export function isAuthenticated() {
  return Boolean(getSession())
}

export async function login({ operatorId, password, remember = true }) {
  const apiBase = import.meta.env.VITE_API_URL
  const demoMode = String(import.meta.env.VITE_DEMO_MODE ?? 'true') !== 'false'

  if (!demoMode && apiBase) {
    const response = await fetch(apiBase.replace(/\/$/, '') + '/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ operator_id: operatorId, password }),
    })
    if (!response.ok) {
      const payload = await response.json().catch(() => ({}))
      throw new Error(payload.detail || 'Invalid operator credentials.')
    }
    const payload = await response.json()
    const target = storage(remember)
    target.setItem(SESSION_KEY, JSON.stringify({
      token: payload.access_token || payload.token,
      operatorId: payload.operator_id || operatorId,
      name: payload.name || operatorId,
      role: payload.role || 'Field Officer',
    }))
    return payload
  }

  // Prototype-only local auth. This is intentionally not a production credential store.
  // Any non-empty password works in demo mode so the frontend can be reviewed before
  // the FastAPI authentication endpoint is connected.
  if (password.trim().length < 4) {
    throw new Error('Demo password must be at least 4 characters.')
  }
  const session = { ...DEMO_OPERATOR, operatorId }
  storage(remember).setItem(SESSION_KEY, JSON.stringify(session))
  return session
}

export function logout() {
  localStorage.removeItem(SESSION_KEY)
  sessionStorage.removeItem(SESSION_KEY)
}

export function authHeaders() {
  const session = getSession()
  return session?.token ? { Authorization: `Bearer ${session.token}` } : {}
}
