import { createContext, useContext, useState, useEffect } from 'react';
import { supabase } from '../lib/supabaseClient';
import { useStore } from '../store/useStore';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [session, setSession] = useState(null);
  const [loading, setLoading] = useState(true);
  const updateUser = useStore(state => state.updateUser);

  useEffect(() => {
    // 1. Получить текущую сессию при загрузке
    supabase.auth.getSession().then(({ data: { session: existingSession } }) => {
      if (existingSession) {
        setSession(existingSession);
        loadProfileFromDB(existingSession.user.id);
        setLoading(false);
      } else {
        // Нет сессии → анонимный вход (без PII)
        signInAnonymously();
      }
    });

    // 2. Подписаться на изменения сессии
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, newSession) => {
        setSession(newSession);
        if ((event === 'SIGNED_IN' || event === 'INITIAL_SESSION') && newSession?.user) {
          await loadProfileFromDB(newSession.user.id);
        }
      }
    );

    return () => subscription.unsubscribe();
  }, []);

  // Анонимный вход — никаких персональных данных
  const signInAnonymously = async () => {
    try {
      const { data, error } = await supabase.auth.signInAnonymously();
      if (error) {
        console.warn('Anonymous auth failed:', error.message);
      } else if (data.session) {
        setSession(data.session);
        await loadProfileFromDB(data.session.user.id);
      }
    } catch (err) {
      console.warn('Auth unavailable (offline?):', err.message);
    } finally {
      setLoading(false);
    }
  };

  // Загрузка профиля из Supabase → Zustand
  const loadProfileFromDB = async (userId) => {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();

      if (data && !error) {
        updateUser({
          nickname: data.nickname || '',
          gender: data.gender || 'female',
          age: data.age || 28,
          weight: data.weight || 70,
          height: data.height || 165,
          activity_level: data.activity_level || 'light',
          goal: data.goal || 'balance',
          tier: data.tier || 'free',
          onboarding_complete: data.onboarding_complete || false,
          avatar_url: data.avatar_url || null,
          trial_ends_at: data.trial_ends_at || null,
        });
      }
    } catch (err) {
      console.warn('Profile load failed (offline?):', err.message);
    }
  };

  // Выход (сброс анонимной сессии)
  const signOut = async () => {
    await supabase.auth.signOut();
    updateUser({
      nickname: '', gender: 'female', age: 28, weight: 70,
      height: 165, activity_level: 'light', goal: 'balance',
      tier: 'free', onboarding_complete: false,
    });
  };

  const value = {
    session,
    user: session?.user ?? null,
    loading,
    signOut,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
};
