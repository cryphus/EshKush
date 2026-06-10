-- Migration 004: OAuth провайдеры (Яндекс, ВКонтакте)
--
-- Добавляем колонки для хранения идентификаторов OAuth-пользователей.
-- VARCHAR(50) для обоих, так как Yandex возвращает ID как строку.

ALTER TABLE users ADD COLUMN IF NOT EXISTS yandex_id VARCHAR(50) UNIQUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS vk_id      VARCHAR(50) UNIQUE;

CREATE INDEX IF NOT EXISTS users_yandex_id_idx ON users(yandex_id);
CREATE INDEX IF NOT EXISTS users_vk_id_idx     ON users(vk_id);
