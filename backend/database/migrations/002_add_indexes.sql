-- Migration 002: Add performance indexes
-- Applied idempotently via CREATE INDEX IF NOT EXISTS

-- products.point_id — used by getProductsByPointId (no index in initial schema)
CREATE INDEX IF NOT EXISTS products_point_id_idx ON products(point_id);

-- orders.user_id — used by getUserOrders
CREATE INDEX IF NOT EXISTS orders_user_id_idx ON orders(user_id);

-- orders.status — used by getAllOrders filtered by status
CREATE INDEX IF NOT EXISTS orders_status_idx ON orders(status);

-- point_reviews.point_id — used by getPointReviews + avg rating CTE
CREATE INDEX IF NOT EXISTS point_reviews_point_id_idx ON point_reviews(point_id);

-- token_blacklist.expires_at — used by cleanupExpiredTokens
CREATE INDEX IF NOT EXISTS token_blacklist_expires_at_idx ON token_blacklist(expires_at);

-- user_sessions.user_id — used by terminateAllUserSessions
CREATE INDEX IF NOT EXISTS user_sessions_user_id_idx ON user_sessions(user_id);
