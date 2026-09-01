import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import type { Session, User } from '@supabase/supabase-js';
import { supabase } from '@/lib/supabase';
import { api } from '@/lib/api';

type Profile = {
  id: string;
  handle: string;
  display_name: string;
  avatar_url: string | null;
  home_base: string | null;
  bio: string | null;
  xp_total: number;
  explorer_level: number;
  streak_days: number;
};

type AuthContextValue = {
  session: Session | null;
  user: User | null;
  profile: Profile | null;
  loading: boolean;
  signUp: (email: string, password: string, displayName: string) => Promise<{ error: string | null }>;
  signIn: (email: string, password: string) => Promise<{ error: string | null }>;
  signOut: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);

  async function loadProfile(_userId: string, retries = 3): Promise<Profile | null> {
    for (let attempt = 0; attempt < retries; attempt++) {
      try {
        const { profile } = await api.getProfile();
        if (profile) {
          setProfile(profile as Profile);
          return profile as Profile;
        }
      } catch {
        // retry
      }
      if (attempt < retries - 1) {
        await new Promise((resolve) => setTimeout(resolve, 300 * (attempt + 1)));
      }
    }
    setProfile(null);
    return null;
  }

  useEffect(() => {
    let cancelled = false;

    supabase.auth.getSession().then(({ data, error }) => {
      if (cancelled) return;
      if (error) {
        setLoading(false);
        return;
      }
      setSession(data.session);
      if (data.session) {
        loadProfile(data.session.user.id).finally(() => {
          if (!cancelled) setLoading(false);
        });
      } else {
        setLoading(false);
      }
    }).catch(() => {
      if (!cancelled) setLoading(false);
    });

    const { data: sub } = supabase.auth.onAuthStateChange((_event, newSession) => {
      (async () => {
        setSession(newSession);
        if (newSession) {
          await loadProfile(newSession.user.id);
        } else {
          setProfile(null);
        }
        setLoading(false);
      })();
    });

    return () => {
      cancelled = true;
      sub.subscription.unsubscribe();
    };
  }, []);

  async function signUp(email: string, password: string, displayName: string): Promise<{ error: string | null }> {
    try {
      const { data, error } = await supabase.auth.signUp({ email, password });
      if (error) return { error: error.message };
      if (data.user) {
        await new Promise((resolve) => setTimeout(resolve, 500));
        try {
          await api.updateProfile({ display_name: displayName });
        } catch {
          console.warn('Profile display_name update failed, trigger may have handled it.');
        }
        await loadProfile(data.user.id);
      }
      return { error: null };
    } catch {
      return { error: 'Could not connect. Please check your connection and try again.' };
    }
  }

  async function signIn(email: string, password: string): Promise<{ error: string | null }> {
    try {
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      return { error: error ? error.message : null };
    } catch {
      return { error: 'Could not connect. Please check your connection and try again.' };
    }
  }

  async function signOut() {
    await supabase.auth.signOut();
    setProfile(null);
  }

  return (
    <AuthContext.Provider value={{ session, user: session?.user ?? null, profile, loading, signUp, signIn, signOut }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider');
  return ctx;
}
