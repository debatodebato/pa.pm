import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './context/AuthContext'
import ProtectedRoute from './components/Auth/ProtectedRoute'
import Login from './components/Auth/Login'
import './index.css'

const Dashboard = () => {
  const { user, signOut } = useAuth()

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 py-4 flex justify-between items-center">
          <h1 className="text-2xl font-bold text-gray-900">point a.</h1>
          <div className="flex items-center gap-4">
            <span className="text-sm text-gray-600">{user?.email}</span>
            <button
              onClick={signOut}
              className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 text-sm"
            >
              Sign Out
            </button>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 py-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">Welcome to point a. PM System</h2>
        <p className="text-gray-600">Phase 2 build in progress. Views coming next:</p>
        <ul className="list-disc list-inside text-gray-600 mt-2">
          <li>Kanban board (drag tasks across Status columns)</li>
          <li>List view (sortable, filterable)</li>
          <li>Calendar view (due dates)</li>
          <li>Allowlist manager (Admins/Leaders only)</li>
        </ul>
      </div>
    </div>
  )
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route
            path="/"
            element={
              <ProtectedRoute>
                <Dashboard />
              </ProtectedRoute>
            }
          />
          <Route path="*" element={<Navigate to="/" />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  </React.StrictMode>,
)
