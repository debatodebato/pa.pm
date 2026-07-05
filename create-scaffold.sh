#!/bin/bash

# Creates the full scaffold structure in the current directory
# Run this from your pa-pm-system folder: bash create-scaffold.sh

set -e

echo "Creating pa-pm-system scaffold structure..."

# Create directories
mkdir -p backend/src/{routes,middleware,services,utils}
mkdir -p frontend/src/{components/{Auth,Dashboard,Projects,Tasks,Admin,Common},pages,services,hooks,context}
mkdir -p database

# Backend files
cat > backend/.env.example << 'BACKEND_ENV'
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-key

# Slack Webhooks (one per Section)
SLACK_WEBHOOK_DESIGN=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
SLACK_WEBHOOK_CONTENT=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
SLACK_WEBHOOK_STUDIO=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
SLACK_WEBHOOK_DEV=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
SLACK_WEBHOOK_CX=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
SLACK_WEBHOOK_LEARNING_DESIGN=https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# Server
NODE_ENV=development
PORT=3001

# Logging (optional)
LOG_LEVEL=info
BACKEND_ENV

cat > backend/package.json << 'BACKEND_PKG'
{
  "name": "pa-pm-backend",
  "version": "0.1.0",
  "description": "point a. PM system backend",
  "type": "module",
  "main": "src/server.js",
  "scripts": {
    "dev": "node --watch src/server.js",
    "start": "node src/server.js",
    "lint": "eslint src/",
    "format": "prettier --write src/"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "@supabase/supabase-js": "^2.38.4"
  },
  "devDependencies": {
    "eslint": "^8.48.0",
    "prettier": "^3.0.3"
  }
}
BACKEND_PKG

cat > backend/src/server.js << 'BACKEND_SERVER'
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:5173',
  credentials: true
}));
app.use(express.json());

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} ${req.method} ${req.path}`);
  next();
});

// Health check route
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Routes (to be imported once built)
// import authRoutes from './routes/auth.js';
// import projectRoutes from './routes/projects.js';
// import taskRoutes from './routes/tasks.js';
// import allowlistRoutes from './routes/allowlist.js';
// 
// app.use('/api/auth', authRoutes);
// app.use('/api/projects', projectRoutes);
// app.use('/api/tasks', taskRoutes);
// app.use('/api/allowlist', allowlistRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV}`);
});
BACKEND_SERVER

# Frontend files
cat > frontend/.env.example << 'FRONTEND_ENV'
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_API_URL=http://localhost:3001
FRONTEND_ENV

cat > frontend/package.json << 'FRONTEND_PKG'
{
  "name": "pa-pm-frontend",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "lint": "eslint src/",
    "format": "prettier --write src/",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.15.0",
    "@supabase/supabase-js": "^2.38.4",
    "axios": "^1.5.0",
    "lucide-react": "^0.276.0",
    "@radix-ui/react-dialog": "^1.1.1",
    "@radix-ui/react-select": "^2.0.0",
    "date-fns": "^2.30.0",
    "react-big-calendar": "^1.8.5"
  },
  "devDependencies": {
    "@types/react": "^18.2.20",
    "@types/react-dom": "^18.2.7",
    "@vitejs/plugin-react": "^4.1.0",
    "vite": "^4.4.9",
    "tailwindcss": "^3.3.3",
    "postcss": "^8.4.28",
    "autoprefixer": "^10.4.15",
    "eslint": "^8.48.0",
    "eslint-plugin-react": "^7.33.2",
    "prettier": "^3.0.3"
  }
}
FRONTEND_PKG

cat > frontend/src/services/supabaseClient.js << 'FRONTEND_SUPABASE'
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    storage: window.localStorage,
    autoRefreshToken: true,
    detectSessionInUrl: true
  }
});

export default supabase;
FRONTEND_SUPABASE

cat > frontend/src/context/AuthContext.jsx << 'FRONTEND_AUTH'
import React, { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from '../services/supabaseClient';

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const checkAuth = async () => {
      try {
        const { data: { session }, error: sessionError } = await supabase.auth.getSession();
        if (sessionError) throw sessionError;
        if (session?.user) {
          setUser(session.user);
          const { data: profileData, error: profileError } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', session.user.id)
            .single();
          if (profileError && profileError.code !== 'PGRST116') {
            throw profileError;
          }
          setProfile(profileData);
        }
      } catch (err) {
        console.error('Auth check failed:', err);
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    checkAuth();

    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (session?.user) {
        setUser(session.user);
        const { data: profileData } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', session.user.id)
          .single();
        setProfile(profileData);
      } else {
        setUser(null);
        setProfile(null);
      }
    });

    return () => {
      subscription?.unsubscribe();
    };
  }, []);

  const signInWithGoogle = async () => {
    try {
      setError(null);
      const { error: signInError } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: window.location.origin
        }
      });
      if (signInError) throw signInError;
    } catch (err) {
      console.error('Sign in failed:', err);
      setError(err.message);
      throw err;
    }
  };

  const signOut = async () => {
    try {
      setError(null);
      const { error: signOutError } = await supabase.auth.signOut();
      if (signOutError) throw signOutError;
      setUser(null);
      setProfile(null);
    } catch (err) {
      console.error('Sign out failed:', err);
      setError(err.message);
      throw err;
    }
  };

  const isAdmin = profile?.is_admin ?? false;
  const isLeader = profile?.role === 'leader';
  const isContributor = profile?.role === 'contributor';
  const isViewer = profile?.role === 'viewer';

  return (
    <AuthContext.Provider value={{
      user,
      profile,
      loading,
      error,
      signInWithGoogle,
      signOut,
      isAdmin,
      isLeader,
      isContributor,
      isViewer,
      isAuthenticated: !!user
    }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};
FRONTEND_AUTH

cat > frontend/src/components/Auth/Login.jsx << 'FRONTEND_LOGIN'
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

const Login = () => {
  const navigate = useNavigate();
  const { signInWithGoogle, error } = useAuth();
  const [isLoading, setIsLoading] = useState(false);

  const handleGoogleSignIn = async () => {
    try {
      setIsLoading(true);
      await signInWithGoogle();
    } catch (err) {
      console.error('Sign in error:', err);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="w-full max-w-md">
        <div className="bg-white rounded-lg shadow-lg p-8">
          <div className="text-center mb-8">
            <h1 className="text-3xl font-bold text-gray-900 mb-2">point a.</h1>
            <p className="text-gray-600">Project Management System</p>
          </div>

          <div className="space-y-4">
            <button
              onClick={handleGoogleSignIn}
              disabled={isLoading}
              className="w-full flex items-center justify-center gap-3 px-4 py-3 bg-white border border-gray-300 rounded-lg text-gray-900 font-medium hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              <svg className="w-5 h-5" viewBox="0 0 24 24">
                <path fill="currentColor" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
                <path fill="currentColor" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
                <path fill="currentColor" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" />
                <path fill="currentColor" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
              </svg>
              {isLoading ? 'Signing in...' : 'Sign in with Google'}
            </button>
          </div>

          {error && (
            <div className="mt-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
              {error}
            </div>
          )}

          <p className="mt-6 text-center text-xs text-gray-500">
            Sign in with your @pointacademy.com email address
          </p>
        </div>
      </div>
    </div>
  );
};

export default Login;
FRONTEND_LOGIN

cat > frontend/src/components/Auth/ProtectedRoute.jsx << 'FRONTEND_PROTECTED'
import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

const ProtectedRoute = ({ children, requiredRole = null }) => {
  const { isAuthenticated, loading, profile } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  if (!profile) {
    return <Navigate to="/login" replace />;
  }

  if (requiredRole) {
    const userRole = profile.is_admin ? 'admin' : profile.role;
    const allowedRoles = Array.isArray(requiredRole) ? requiredRole : [requiredRole];
    
    if (!allowedRoles.includes(userRole)) {
      return (
        <div className="min-h-screen flex items-center justify-center bg-gray-50">
          <div className="text-center">
            <h1 className="text-2xl font-bold text-gray-900 mb-2">Access Denied</h1>
            <p className="text-gray-600">You don't have permission to access this page.</p>
          </div>
        </div>
      );
    }
  }

  return children;
};

export default ProtectedRoute;
FRONTEND_PROTECTED

# Database files
cat > database/allowed-emails-migration.sql << 'DATABASE_MIGRATION'
-- New table: allowed_emails (manual email allowlist, managed by Admins)
create table allowed_emails (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  added_by uuid references profiles(id),
  created_at timestamptz not null default now(),
  notes text
);

-- Enable RLS on allowed_emails
alter table allowed_emails enable row level security;

-- Policy: Admins and Leaders can manage the allowlist
create policy "admins_leaders_manage_allowlist" on allowed_emails for all using (
  (select is_admin from profiles where id = auth.uid())
  or
  (select role from profiles where id = auth.uid()) = 'leader'
);

-- Policy: All authenticated users can view (for reference)
create policy "users_view_allowlist" on allowed_emails for select using (
  auth.role() = 'authenticated'
);

-- Helper function: check if email is in allowlist
create or replace function is_email_allowed(p_email text)
returns boolean as $$
  select exists (
    select 1 from allowed_emails where email = p_email
  );
$$ language sql security definer stable;

-- Add column to profiles table for tracking allowlist acceptance
alter table profiles add column role text default 'contributor' 
  check (role in ('admin', 'leader', 'contributor', 'viewer'));
DATABASE_MIGRATION

echo "✓ Scaffold created successfully!"
echo ""
echo "Next steps:"
echo "1. cd pa-pm-system"
echo "2. git add ."
echo "3. git commit -m 'add scaffold: backend, frontend, database'"
echo "4. git push -u origin main"
echo ""
echo "Then install dependencies:"
echo "5. cd backend && npm install && cd .."
echo "6. cd frontend && npm install && cd .."
