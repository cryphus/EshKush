-- Migration 003: Telegram-авторизация + логин/пароль без обязательного email/phone
--
-- Что делаем:
--   1. Снимаем NOT NULL с users.email / users.number / users.password
--      (для Telegram-only пользователей эти поля заполняются позже или никогда).
--   2. Добавляем колонки для идентификации пользователя Телеграма:
--        - telegram_id  (PK Телеграма, UNIQUE)
--        - telegram_username
--        - first_name / last_name (из профиля Телеграма)
--   3. Создаём таблицу одноразовых токенов telegram_auth_tokens
--      для flow: frontend → /auth/telegram/initiate → bot (/start <token>) →
--      bot → /auth/telegram/complete → frontend (polling /auth/telegram/status).

-- 1. users: ослабляем ограничения на email/password/number ------------------

ALTER TABLE users ALTER COLUMN email    DROP NOT NULL;
ALTER TABLE users ALTER COLUMN password DROP NOT NULL;
ALTER TABLE users ALTER COLUMN number   DROP NOT NULL;

-- UNIQUE на email оставляем, но только для непустых значений.
-- Postgres уже позволяет несколько NULL в UNIQUE — отдельных правок не нужно.

ALTER TABLE users ADD COLUMN IF NOT EXISTS telegram_id       BIGINT     UNIQUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS telegram_username VARCHAR(64);
ALTER TABLE users ADD COLUMN IF NOT EXISTS first_name        VARCHAR(64);
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_name         VARCHAR(64);

CREATE INDEX IF NOT EXISTS users_telegram_id_idx ON users(telegram_id);

-- 2. Одноразовые токены telegram-авторизации --------------------------------

CREATE TABLE IF NOT EXISTS telegram_auth_tokens (
    token             VARCHAR(128) PRIMARY KEY,
    status            VARCHAR(20)  NOT NULL DEFAULT 'pending',
    user_id           INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    telegram_id       BIGINT,
    telegram_username VARCHAR(64),
    first_name        VARCHAR(64),
    last_name         VARCHAR(64),
    phone             VARCHAR(20),
    access_token      TEXT,
    refresh_token     TEXT,
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at        TIMESTAMP WITH TIME ZONE NOT NULL,
    completed_at      TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS telegram_auth_tokens_status_idx
    ON telegram_auth_tokens(status);

CREATE INDEX IF NOT EXISTS telegram_auth_tokens_expires_at_idx
    ON telegram_auth_tokens(expires_at);
