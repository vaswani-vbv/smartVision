import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import LoginPage      from './pages/LoginPage';
import RegisterPage   from './pages/RegisterPage';
import ProfilePage    from './pages/ProfilePage';
import GlucoseLogPage from './pages/GlucoseLogPage';
import PredictionPage from './pages/PredictionPage';
import ProtectedRoute from './components/ProtectedRoute';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login"    element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />
        <Route path="/profile"  element={
          <ProtectedRoute><ProfilePage /></ProtectedRoute>
        } />
        <Route path="/glucose"  element={
          <ProtectedRoute><GlucoseLogPage /></ProtectedRoute>
        } />
        <Route path="/dashboard" element={
          <ProtectedRoute><GlucoseLogPage /></ProtectedRoute>
        } />
        <Route path="/predict"  element={
          <ProtectedRoute><PredictionPage /></ProtectedRoute>
        } />
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;