import { useState } from 'react';
import { ArrowRight, Compass, Eye, EyeOff, Loader2, Mail, Lock, UserRound } from 'lucide-react';
import { useAuth } from '@/lib/auth';

export function AuthPage() {
  const { signIn, signUp } = useAuth();
  const [mode, setMode] = useState<'login' | 'signup'>('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const submit = async (event: React.FormEvent) => {
    event.preventDefault();
    setError(null);
    setSubmitting(true);
    if (mode === 'signup' && !displayName.trim()) {
      setError('Please tell us your name.');
      setSubmitting(false);
      return;
    }
    const result = mode === 'login'
      ? await signIn(email.trim(), password)
      : await signUp(email.trim(), password, displayName.trim());
    setSubmitting(false);
    if (result.error) setError(result.error);
  };

  const switchMode = () => {
    setMode(mode === 'login' ? 'signup' : 'login');
    setError(null);
  };

  return (
    <div className="auth-page">
      <div className="auth-panel">
        <div className="auth-brand">
          <span className="brand-symbol"><Compass size={18} /></span>
          <span>roamwell</span>
        </div>
        <div className="auth-copy">
          <span className="eyebrow">{mode === 'login' ? 'Welcome back' : 'Join roamwell'}</span>
          <h1>{mode === 'login' ? <>Pick up where<br /><em>you left off.</em></> : <>Plan trips that<br /><em>fit you.</em></>}</h1>
          <p>{mode === 'login' ? 'Your journeys, saved trips, and XP are waiting.' : 'Save plans, earn XP, and discover what locals actually do.'}</p>
        </div>
        <form className="auth-form" onSubmit={submit}>
          {mode === 'signup' && (
            <label className="auth-field">
              <span>Display name</span>
              <div className="input-wrap">
                <UserRound size={17} />
                <input
                  type="text"
                  value={displayName}
                  onChange={(e) => setDisplayName(e.target.value)}
                  placeholder="Jordan Davis"
                  autoComplete="name"
                />
              </div>
            </label>
          )}
          <label className="auth-field">
            <span>Email</span>
            <div className="input-wrap">
              <Mail size={17} />
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@example.com"
                autoComplete="email"
                required
              />
            </div>
          </label>
          <label className="auth-field">
            <span>Password</span>
            <div className="input-wrap">
              <Lock size={17} />
              <input
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder={mode === 'login' ? 'Your password' : 'At least 6 characters'}
                autoComplete={mode === 'login' ? 'current-password' : 'new-password'}
                minLength={6}
                required
              />
              <button type="button" className="password-toggle" onClick={() => setShowPassword(!showPassword)} aria-label={showPassword ? 'Hide password' : 'Show password'}>
                {showPassword ? <EyeOff size={17} /> : <Eye size={17} />}
              </button>
            </div>
          </label>
          {error && <p className="auth-error">{error}</p>}
          <button type="submit" className="primary-button full auth-submit" disabled={submitting}>
            {submitting ? <Loader2 size={18} className="spin" /> : <>{mode === 'login' ? 'Sign in' : 'Create account'} <ArrowRight size={17} /></>}
          </button>
        </form>
        <p className="auth-switch">
          {mode === 'login' ? "Don't have an account?" : 'Already have one?'}
          <button onClick={switchMode}>{mode === 'login' ? 'Sign up' : 'Log in'}</button>
        </p>
      </div>
    </div>
  );
}
