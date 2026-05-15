-- Migration 006: add missing indexes for auth/session hot paths
-- Safe to run multiple times.

-- users lookups
CREATE INDEX IF NOT EXISTS users_email_idx ON users(email);
CREATE INDEX IF NOT EXISTS users_username_idx ON users(username);

-- orders lookups by user
CREATE INDEX IF NOT EXISTS orders_user_id_idx ON orders(user_id);

-- refresh token session lookup/revocation
CREATE INDEX IF NOT EXISTS user_sessions_refresh_jti_hash_idx
  ON user_sessions(refresh_jti_hash);
