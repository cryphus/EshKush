-- JWT access tokens exceed VARCHAR(255); expand to TEXT.
ALTER TABLE user_sessions ALTER COLUMN token TYPE TEXT;
