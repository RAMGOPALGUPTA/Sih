import React, { useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { login } from '../services/auth.js'

export function Login() {
  const navigate = useNavigate()
  const location = useLocation()
  const [operatorId, setOperatorId] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [remember, setRemember] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')
    if (!operatorId.trim() || !password) {
      setError('Enter your operator ID and password.')
      return
    }
    setBusy(true)
    try {
      await login({ operatorId: operatorId.trim(), password, remember })
      const target = location.state?.from?.pathname || '/'
      navigate(target, { replace: true })
    } catch (err) {
      setError(err.message || 'Sign-in failed.')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="auth-screen">
      <div className="auth-gridline" />
      <div className="auth-panel">
        <div className="auth-brand">
          <div className="brand-mark">FE</div>
          <div>
            <div className="brand-name">Field Evidence</div>
            <div className="brand-sub">SIH26231 / SECURE CONSOLE</div>
          </div>
        </div>

        <div className="auth-kicker">OPERATOR ACCESS</div>
        <h1>Enter the<br /><em>field console.</em></h1>
        <p className="auth-copy">Authenticate before creating, reviewing, or sealing a field-test record.</p>

        <form className="auth-form" onSubmit={handleSubmit}>
          <label>
            <span>OPERATOR ID</span>
            <input autoComplete="username" value={operatorId} onChange={e => setOperatorId(e.target.value)} placeholder="e.g. A-17" />
          </label>

          <label>
            <span>PASSWORD</span>
            <div className="password-wrap">
              <input autoComplete="current-password" type={showPassword ? 'text' : 'password'} value={password} onChange={e => setPassword(e.target.value)} placeholder="Enter password" />
              <button type="button" onClick={() => setShowPassword(v => !v)}>{showPassword ? 'HIDE' : 'SHOW'}</button>
            </div>
          </label>

          <div className="auth-options">
            <label className="remember-option">
              <input type="checkbox" checked={remember} onChange={e => setRemember(e.target.checked)} />
              <span>Keep me signed in</span>
            </label>
            <span className="auth-status">LOCAL SESSION READY</span>
          </div>

          {error && <div className="auth-error">{error}</div>}

          <button className="auth-submit" disabled={busy}>{busy ? 'Authenticating…' : 'Authenticate →'}</button>
        </form>

        <div className="auth-foot">
          <span>Authorized operators only</span>
          <span>Prototype authentication</span>
        </div>
      </div>

      <div className="auth-visual">
        <div className="radar-ring ring-a" />
        <div className="radar-ring ring-b" />
        <div className="radar-ring ring-c" />
        <div className="auth-crosshair">+</div>
        <div className="auth-telemetry telemetry-one">FIELD NODE / A-17</div>
        <div className="auth-telemetry telemetry-two">CHAIN / ARMED</div>
        <div className="auth-telemetry telemetry-three">SHA-256 / READY</div>
        <div className="auth-visual-copy">
          <span>SECURE FIELD ACCESS</span>
          <strong>Capture.<br />Interpret.<br />Seal.</strong>
        </div>
      </div>
    </div>
  )
}
