import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { supabase } from '../lib/supabaseClient';

const ACTIVITY_MULTIPLIERS = {
  none: 1.2,
  light: 1.375,
  moderate: 1.55,
  high: 1.725
};

export const useStore = create(
  persist(
    (set, get) => ({
  // Core Data
  user: {
    nickname: '',
    gender: 'female',
    age: 28,
    weight: 70,
    height: 165,
    activity_level: 'light',
    goal: 'balance',
    tier: 'free',
    onboarding_complete: false,
    avatar_url: null,
    trial_ends_at: null,
  },
  
  // Local Meal Plan Data (Zero-Knowledge)
  mealPlan: null, // Holds the generated 1-day or 7-day plan
  
  // Day Progress (Mock)
  dayProgress: {
    consumedCalories: 860,
    consumedProtein: 42,
    consumedFat: 28,
    consumedCarbs: 110,
    consumedFiber: 12
  },

  // Actions
  updateUser: (newData) => set((state) => ({ 
    user: { ...state.user, ...newData } 
  })),
  
  setMealPlan: (plan) => set({ mealPlan: plan }),

  addMeal: (macros) => set((state) => ({
    dayProgress: {
      consumedCalories: state.dayProgress.consumedCalories + (macros.calories || 0),
      consumedProtein: state.dayProgress.consumedProtein + (macros.protein || 0),
      consumedFat: state.dayProgress.consumedFat + (macros.fat || 0),
      consumedCarbs: state.dayProgress.consumedCarbs + (macros.carbs || 0),
      consumedFiber: state.dayProgress.consumedFiber + (macros.fiber || 0)
    }
  })),

  // Sync non-medical profile data to Supabase (Zero-Knowledge)
  saveProfile: async () => {
    const user = get().user;
    const { data: { session } } = await supabase.auth.getSession();
    
    if (!session?.user) return;

    // We only sync subscription-related data. 
    // Medical data (age, weight, goal) stays ONLY in this local store.
    const { error } = await supabase
      .from('profiles')
      .update({
        tier: user.tier,
        updated_at: new Date().toISOString(),
      })
      .eq('id', session.user.id);

    if (error) console.error('saveProfile error:', error);
  },

  // Getters / Computed logic
  getMetrics: () => {
    const user = get().user;
    const heightInMeters = (user.height || 165) / 100;
    const bmi = (user.weight || 70) / (heightInMeters * heightInMeters);
    let bmr = 10 * (user.weight || 70) + 6.25 * (user.height || 165) - 5 * (user.age || 28);
    bmr += (user.gender === 'male' ? 5 : -161);
    const tdee = bmr * (ACTIVITY_MULTIPLIERS[user.activity_level] || 1.375);
    
    let targetCalories = tdee;
    if (user.goal === 'weight_loss') targetCalories = tdee * 0.8;
    if (user.goal === 'muscle_gain') targetCalories = tdee * 1.1;
    targetCalories = Math.round(targetCalories);

    const pPct = 0.3, fPct = 0.3, cPct = 0.4;
    return {
      bmi: Number(bmi.toFixed(1)),
      bmr: Math.round(bmr),
      tdee: Math.round(tdee),
      targetCalories,
      targetMacros: {
        protein: Math.round((targetCalories * pPct) / 4),
        fat: Math.round((targetCalories * fPct) / 9),
        carbs: Math.round((targetCalories * cPct) / 4),
        fiber: 30
      }
    };
  }
}),
{
  name: 'aidiet-storage',
}
));
