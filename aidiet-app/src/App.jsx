import { BrowserRouter, Routes, Route, Link, useLocation, Navigate } from 'react-router-dom';
import { House, CalendarBlank, ShoppingCart, ChartLineUp, User } from '@phosphor-icons/react';
import { AuthProvider, useAuth } from './context/AuthContext';

import Dashboard from './pages/Dashboard';
import Plan from './pages/Plan';
import Shopping from './pages/Shopping';
import Progress from './pages/Progress';
import Profile from './pages/Profile';
import Wizard from './pages/Wizard';

const TabBar = () => {
  const location = useLocation();
  
  const tabs = [
    { path: '/', label: 'Главная', Icon: House },
    { path: '/plan', label: 'План', Icon: CalendarBlank },
    { path: '/shopping', label: 'Покупки', Icon: ShoppingCart },
    { path: '/progress', label: 'Прогресс', Icon: ChartLineUp },
    { path: '/profile', label: 'Профиль', Icon: User }
  ];

  return (
    <nav className="absolute bottom-0 left-0 right-0 h-[84px] bg-white border-t border-divider flex justify-around pb-safe pt-3 z-[100]">
      {tabs.map(({ path, label, Icon }) => {
        const isActive = location.pathname === path;
        return (
          <Link 
            key={path} 
            to={path} 
            className={`flex flex-col items-center gap-1 flex-1 transition-colors active:text-primary ${isActive ? 'text-primary' : 'text-text-tertiary'}`}
          >
            <Icon size={24} weight={isActive ? 'fill' : 'regular'} />
            <span className="text-[10px] font-semibold">{label}</span>
          </Link>
        );
      })}
    </nav>
  );
};

const AppLayout = () => {
  const location = useLocation();
  const { loading } = useAuth();

  // Splash пока грузится сессия
  if (loading) {
    return (
      <div className="app-frame bg-surface flex flex-col items-center justify-center gap-4">
        <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-orange-400 to-orange-600 flex items-center justify-center shadow-lg animate-pulse">
          <span className="text-2xl font-extrabold text-white tracking-tight">AI</span>
        </div>
        <p className="text-[14px] font-semibold text-text-mut">Загружаем твой план...</p>
      </div>
    );
  }

  return (
    <div className="app-frame bg-surface">
      {/* Content Area */}
      <div className="flex-1 overflow-y-auto pb-[100px] hide-scrollbar relative bg-bg-main">
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/plan" element={<Plan />} />
          <Route path="/shopping" element={<Shopping />} />
          <Route path="/progress" element={<Progress />} />
          <Route path="/profile" element={<Profile />} />
          <Route path="/wizard" element={<Wizard />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </div>

      {location.pathname !== '/wizard' && <TabBar />}
    </div>
  );
};

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <AppLayout />
      </AuthProvider>
    </BrowserRouter>
  );
}
