DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM ('admin', 'partner', 'support', 'user', 'guest');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'point_category') THEN
        CREATE TYPE point_category AS ENUM ('shop', 'restaurant', 'cafe', 'other');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status') THEN
        CREATE TYPE order_status AS ENUM ('pending', 'processing', 'completed', 'cancelled');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method') THEN
        CREATE TYPE payment_method AS ENUM ('cash', 'card', 'creditCard', 'mobilePayment', 'other');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_transaction_status') THEN
        CREATE TYPE payment_transaction_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type') THEN
        CREATE TYPE notification_type AS ENUM ('otherUpdate', 'promotion', 'system');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'discount_type') THEN
        CREATE TYPE discount_type AS ENUM ('fixed', 'percentage');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'action_type') THEN
        CREATE TYPE action_type AS ENUM ('create', 'read', 'update', 'delete', 'login', 'logout', 'search', 'filter', 'other');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'history_status') THEN
        CREATE TYPE history_status AS ENUM ('pending', 'completed', 'cancelled');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'change_type') THEN
        CREATE TYPE change_type AS ENUM ('create', 'update', 'delete', 'restore');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'entity_type') THEN
        CREATE TYPE entity_type AS ENUM ('user', 'point', 'product', 'order', 'partner', 'category', 'promoCode', 'profile', 'other');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'session_status') THEN
        CREATE TYPE session_status AS ENUM ('active', 'expired', 'revoked');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'error_severity') THEN
        CREATE TYPE error_severity AS ENUM ('low', 'medium', 'high', 'critical');
    END IF;
END
$$;

-- Удаляем старые таблицы
DROP TABLE IF EXISTS point_reviews CASCADE;
DROP TABLE IF EXISTS promo_codes CASCADE;
DROP TABLE IF EXISTS error_logs CASCADE;
DROP TABLE IF EXISTS changes CASCADE;
DROP TABLE IF EXISTS order_actions CASCADE;
DROP TABLE IF EXISTS order_history CASCADE;
DROP TABLE IF EXISTS action_logs CASCADE;
DROP TABLE IF EXISTS payment_transactions CASCADE;
DROP TABLE IF EXISTS partner_statistics CASCADE;
DROP TABLE IF EXISTS partner_settings CASCADE;
DROP TABLE IF EXISTS token_blacklist CASCADE;
DROP TABLE IF EXISTS user_sessions CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS user_favorites CASCADE;
DROP TABLE IF EXISTS product_category_map CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS points CASCADE;
DROP TABLE IF EXISTS partners CASCADE;
DROP TABLE IF EXISTS cities CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Создаем таблицу users
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    number VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    role user_role NOT NULL DEFAULT 'user',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Создаем таблицу cities
CREATE TABLE cities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу partners
CREATE TABLE partners (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    name VARCHAR(100) NOT NULL,
    contact_person INTEGER NOT NULL,
    contact_email VARCHAR(100) NOT NULL,
    contact_phone VARCHAR(20) NOT NULL,
    contact_document VARCHAR(50) NOT NULL,
    max_discount DECIMAL(5,2) DEFAULT 0.0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу points
CREATE TABLE points (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    rating DECIMAL(3,2) DEFAULT 0.0,
    city_id INTEGER NOT NULL REFERENCES cities(id),
    products JSONB NOT NULL DEFAULT '{}',
    opening_hours VARCHAR(5) NOT NULL,
    closing_hours VARCHAR(5) NOT NULL,
    partner_id INTEGER NOT NULL REFERENCES partners(id),
    longitude DECIMAL(10,7) NOT NULL,
    latitude DECIMAL(10,7) NOT NULL,
    tags JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Создаем таблицу point_categories
CREATE TABLE point_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу point_category_map
CREATE TABLE point_category_map (
    point_id INTEGER NOT NULL REFERENCES points(id) ON DELETE CASCADE,
    category_id INTEGER NOT NULL REFERENCES point_categories(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (point_id, category_id)
);

-- Создаем таблицу orders
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    point_id INTEGER NOT NULL REFERENCES points(id),
    products_id INTEGER[] NOT NULL,
    date TIMESTAMP WITH TIME ZONE NOT NULL,
    status order_status NOT NULL DEFAULT 'pending',
    total_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Создаем таблицу categories
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу product_categories (под модель ProductCategory)
CREATE TABLE product_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу products (под модель Product)
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    image_url VARCHAR(255),
    partner_id INTEGER NOT NULL REFERENCES partners(id),
    point_id INTEGER NOT NULL REFERENCES points(id),
    weight DECIMAL(10, 2) NOT NULL DEFAULT 0.0,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Создаем таблицу product_category_map
CREATE TABLE product_category_map (
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    category_id INTEGER NOT NULL REFERENCES product_categories(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (product_id, category_id)
);

-- Создаем таблицу user_favorites
CREATE TABLE user_favorites (
    user_id INTEGER NOT NULL REFERENCES users(id),
    point_id INTEGER NOT NULL REFERENCES points(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, point_id)
);

-- Создаем таблицу reviews
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    point_id INTEGER NOT NULL REFERENCES points(id),
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу notifications (под модель Notification)
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    message TEXT NOT NULL,
    type notification_type NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    metadata JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE
);

-- Создаем таблицу profiles
CREATE TABLE profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    avatar_url TEXT,
    bio TEXT,
    sum_co2 INTEGER DEFAULT 0,
    saved_money DECIMAL(10,2) DEFAULT 0.0,
    count_buy INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) NOT NULL,
    refresh_jti_hash VARCHAR(64) NOT NULL,
    device_info TEXT,
    ip_address VARCHAR(45),
    status session_status NOT NULL DEFAULT 'active',
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_active TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Blacklist отозванных JWT jti (logout/terminate). Создана для отзыва токенов.
CREATE TABLE token_blacklist (
    jti_hash VARCHAR(64) PRIMARY KEY,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS token_blacklist_expires_at_idx ON token_blacklist(expires_at);

CREATE TABLE partner_settings (
    id SERIAL PRIMARY KEY,
    partner_id INTEGER NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
    branding_color VARCHAR(20) NOT NULL DEFAULT '#000000',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу partner_statistics (под модель PartnerStatistics)
CREATE TABLE partner_statistics (
    id SERIAL PRIMARY KEY,
    partner_id INTEGER NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
    point_id INTEGER NOT NULL REFERENCES points(id) ON DELETE CASCADE,
    total_orders INTEGER NOT NULL DEFAULT 0,
    total_revenue DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total_cancel INTEGER NOT NULL DEFAULT 0,
    average_rating DECIMAL(3,2) NOT NULL DEFAULT 0,
    total_reviews INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Создаем таблицу payment_transactions (под модель PaymentTransactions)
CREATE TABLE payment_transactions (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    order_price DECIMAL(10, 2) NOT NULL DEFAULT 0,
    status payment_transaction_status NOT NULL DEFAULT 'completed',
    payment_method payment_method NOT NULL DEFAULT 'other',
    provider_transaction_id INTEGER NOT NULL,
    transaction_date TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE action_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    action_type action_type NOT NULL,
    entity_type entity_type NOT NULL,
    entity_id INTEGER NOT NULL,
    details TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45) NOT NULL,
    user_agent TEXT,
    location TEXT,
    is_success BOOLEAN NOT NULL DEFAULT TRUE,
    error_message TEXT,
    metadata JSONB
);

-- Создаем таблицу order_history (под модель OrderHistory)
CREATE TABLE order_history (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    point_id INTEGER NOT NULL REFERENCES points(id),
    user_id INTEGER NOT NULL REFERENCES users(id),
    order_date TIMESTAMP WITH TIME ZONE NOT NULL,
    completion_date TIMESTAMP WITH TIME ZONE,
    total_sum DECIMAL(10,2) NOT NULL DEFAULT 0.0,
    status history_status NOT NULL DEFAULT 'pending',
    receipt_link TEXT,
    discount_applied DECIMAL(10,2),
    promo_code_used TEXT,
    co2_saved INTEGER DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу order_actions
CREATE TABLE order_actions (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    action_type action_type NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу changes (под модель Changes)
CREATE TABLE changes (
    id SERIAL PRIMARY KEY,
    entity_type entity_type NOT NULL,
    entity_id INTEGER NOT NULL,
    change_type change_type NOT NULL,
    field_name VARCHAR(100) NOT NULL,
    old_value TEXT,
    new_value TEXT,
    changed_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    comment TEXT,
    is_reverted BOOLEAN NOT NULL DEFAULT FALSE,
    reverted_at TIMESTAMP WITH TIME ZONE,
    reverted_by INTEGER REFERENCES users(id)
);

-- Создаем таблицу error_logs (под модель ErrorLogs)
CREATE TABLE error_logs (
    id SERIAL PRIMARY KEY,
    severity error_severity NOT NULL,
    message TEXT NOT NULL,
    error_code TEXT NOT NULL,
    stack_trace TEXT NOT NULL,
    time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved BOOLEAN NOT NULL DEFAULT FALSE,
    module TEXT,
    user_id INTEGER REFERENCES users(id),
    additional_info TEXT,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by TEXT
);

-- Создаем таблицу promo_codes
CREATE TABLE promo_codes (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    min_order_sum DECIMAL(10,2) NOT NULL DEFAULT 0,
    discount_type discount_type NOT NULL,
    discount_value DECIMAL(10,2) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    usage_limit INTEGER,
    current_usage INTEGER NOT NULL DEFAULT 0,
    applicable_products INTEGER[],
    applicable_points INTEGER[],
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE point_reviews (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    point_id INTEGER NOT NULL REFERENCES points(id),
    rating DECIMAL(2,1) NOT NULL CHECK (rating >= 0 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS users_username_idx ON users(username);
CREATE INDEX IF NOT EXISTS users_email_idx ON users(email);
CREATE INDEX IF NOT EXISTS points_city_id_idx ON points(city_id);
CREATE INDEX IF NOT EXISTS points_partner_id_idx ON points(partner_id);
CREATE INDEX IF NOT EXISTS orders_user_id_idx ON orders(user_id);
CREATE INDEX IF NOT EXISTS orders_point_id_idx ON orders(point_id);
CREATE INDEX IF NOT EXISTS orders_status_idx ON orders(status);
CREATE INDEX IF NOT EXISTS partners_user_id_idx ON partners(user_id);
CREATE INDEX IF NOT EXISTS products_partner_id_idx ON products(partner_id);
CREATE INDEX IF NOT EXISTS product_category_map_product_id_idx ON product_category_map(product_id);
CREATE INDEX IF NOT EXISTS product_category_map_category_id_idx ON product_category_map(category_id);
CREATE INDEX IF NOT EXISTS user_favorites_user_id_idx ON user_favorites(user_id);
CREATE INDEX IF NOT EXISTS user_favorites_point_id_idx ON user_favorites(point_id);
CREATE INDEX IF NOT EXISTS reviews_user_id_idx ON reviews(user_id);
CREATE INDEX IF NOT EXISTS reviews_point_id_idx ON reviews(point_id);
CREATE INDEX IF NOT EXISTS notifications_user_id_idx ON notifications(user_id);
CREATE INDEX IF NOT EXISTS notifications_is_read_idx ON notifications(is_read);
CREATE INDEX IF NOT EXISTS profiles_user_id_idx ON profiles(user_id);
CREATE INDEX IF NOT EXISTS user_sessions_user_id_idx ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS user_sessions_token_idx ON user_sessions(token);
CREATE INDEX IF NOT EXISTS user_sessions_refresh_jti_hash_idx ON user_sessions(refresh_jti_hash);
CREATE INDEX IF NOT EXISTS user_sessions_expires_at_idx ON user_sessions(expires_at);
CREATE INDEX IF NOT EXISTS partner_settings_partner_id_idx ON partner_settings(partner_id);
CREATE INDEX IF NOT EXISTS partner_statistics_partner_id_idx ON partner_statistics(partner_id);
CREATE INDEX IF NOT EXISTS payment_transactions_order_id_idx ON payment_transactions(order_id);
CREATE INDEX IF NOT EXISTS action_logs_user_id_idx ON action_logs(user_id);
CREATE INDEX IF NOT EXISTS action_logs_entity_type_idx ON action_logs(entity_type);
CREATE INDEX IF NOT EXISTS order_history_order_id_idx ON order_history(order_id);
CREATE INDEX IF NOT EXISTS order_history_user_id_idx ON order_history(user_id);
CREATE INDEX IF NOT EXISTS order_history_point_id_idx ON order_history(point_id);
CREATE INDEX IF NOT EXISTS order_history_status_idx ON order_history(status);
CREATE INDEX IF NOT EXISTS order_actions_order_id_idx ON order_actions(order_id);
CREATE INDEX IF NOT EXISTS order_actions_action_type_idx ON order_actions(action_type);
CREATE INDEX IF NOT EXISTS changes_entity_type_idx ON changes(entity_type);
CREATE INDEX IF NOT EXISTS changes_entity_id_idx ON changes(entity_id);
CREATE INDEX IF NOT EXISTS error_logs_severity_idx ON error_logs(severity);
CREATE INDEX IF NOT EXISTS point_reviews_user_id_idx ON point_reviews(user_id);
CREATE INDEX IF NOT EXISTS point_reviews_point_id_idx ON point_reviews(point_id);
CREATE INDEX IF NOT EXISTS promo_codes_code_idx ON promo_codes(code);
CREATE INDEX IF NOT EXISTS promo_codes_is_active_idx ON promo_codes(is_active);
CREATE INDEX IF NOT EXISTS promo_codes_dates_idx ON promo_codes(start_date, end_date);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();


