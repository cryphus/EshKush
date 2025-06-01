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
        CREATE TYPE payment_method AS ENUM ('card', 'cash', 'google_pay', 'apple_pay');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_transaction_status') THEN
        CREATE TYPE payment_transaction_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type') THEN
        CREATE TYPE notification_type AS ENUM ('info', 'warning', 'error', 'success');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'discount_type') THEN
        CREATE TYPE discount_type AS ENUM ('percentage', 'fixed', 'free_shipping');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'action_type') THEN
        CREATE TYPE action_type AS ENUM ('create', 'update', 'delete', 'login', 'logout');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'history_status') THEN
        CREATE TYPE history_status AS ENUM ('active', 'archived', 'deleted');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'change_type') THEN
        CREATE TYPE change_type AS ENUM ('field_update', 'relation_update', 'status_change');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'entity_type') THEN
        CREATE TYPE entity_type AS ENUM ('user', 'order', 'product', 'partner', 'category');
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
DROP TABLE IF EXISTS user_sessions CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS user_favorites CASCADE;
DROP TABLE IF EXISTS product_category_map CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
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
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
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
    description TEXT,
    logo_url TEXT,
    website_url TEXT,
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
    opening_hours TIME NOT NULL,
    closing_hours TIME NOT NULL,
    partner_id INTEGER NOT NULL REFERENCES partners(id),
    longitude DECIMAL(10,7) NOT NULL,
    latitude DECIMAL(10,7) NOT NULL,
    tags JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу orders
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    point_id INTEGER NOT NULL REFERENCES points(id),
    date TIMESTAMP WITH TIME ZONE NOT NULL,
    status order_status NOT NULL DEFAULT 'pending',
    total_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу categories
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу products
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    image_url VARCHAR(255),
    partner_id INTEGER NOT NULL REFERENCES partners(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу order_items
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу product_category_map
CREATE TABLE product_category_map (
    product_id INTEGER NOT NULL REFERENCES products(id),
    category_id INTEGER NOT NULL REFERENCES categories(id),
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

-- Создаем таблицу notifications
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    title VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу profiles
CREATE TABLE profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу user_sessions
CREATE TABLE user_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) NOT NULL,
    device_info TEXT,
    ip_address VARCHAR(45),
    status session_status NOT NULL DEFAULT 'active',
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу partner_settings
CREATE TABLE partner_settings (
    id SERIAL PRIMARY KEY,
    partner_id INTEGER NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
    setting_key VARCHAR(50) NOT NULL,
    setting_value TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(partner_id, setting_key)
);

-- Создаем таблицу partner_statistics
CREATE TABLE partner_statistics (
    id SERIAL PRIMARY KEY,
    partner_id INTEGER NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
    total_orders INTEGER DEFAULT 0,
    total_revenue DECIMAL(10, 2) DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу payment_transactions
CREATE TABLE payment_transactions (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    status payment_transaction_status NOT NULL DEFAULT 'pending',
    payment_method payment_method NOT NULL,
    transaction_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу action_logs
CREATE TABLE action_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    action_type action_type NOT NULL,
    entity_type entity_type NOT NULL,
    entity_id INTEGER NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу order_history
CREATE TABLE order_history (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    status history_status NOT NULL DEFAULT 'active',
    changes TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу order_actions
CREATE TABLE order_actions (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    action_type action_type NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу changes
CREATE TABLE changes (
    id SERIAL PRIMARY KEY,
    entity_type entity_type NOT NULL,
    entity_id INTEGER NOT NULL,
    change_type change_type NOT NULL,
    field_name VARCHAR(100) NOT NULL,
    old_value TEXT,
    new_value TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу error_logs
CREATE TABLE error_logs (
    id SERIAL PRIMARY KEY,
    severity error_severity NOT NULL,
    message TEXT NOT NULL,
    stack_trace TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу promo_codes
CREATE TABLE promo_codes (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    discount_type discount_type NOT NULL,
    discount_value DECIMAL(10, 2) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Создаем таблицу point_reviews
CREATE TABLE point_reviews (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    point_id INTEGER NOT NULL REFERENCES points(id),
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
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
CREATE INDEX IF NOT EXISTS order_items_order_id_idx ON order_items(order_id);
CREATE INDEX IF NOT EXISTS order_items_product_id_idx ON order_items(product_id);
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
CREATE INDEX IF NOT EXISTS partner_settings_partner_id_idx ON partner_settings(partner_id);
CREATE INDEX IF NOT EXISTS partner_statistics_partner_id_idx ON partner_statistics(partner_id);
CREATE INDEX IF NOT EXISTS payment_transactions_order_id_idx ON payment_transactions(order_id);
CREATE INDEX IF NOT EXISTS action_logs_user_id_idx ON action_logs(user_id);
CREATE INDEX IF NOT EXISTS action_logs_entity_type_idx ON action_logs(entity_type);
CREATE INDEX IF NOT EXISTS order_history_order_id_idx ON order_history(order_id);
CREATE INDEX IF NOT EXISTS order_actions_order_id_idx ON order_actions(order_id);
CREATE INDEX IF NOT EXISTS changes_entity_type_idx ON changes(entity_type);
CREATE INDEX IF NOT EXISTS changes_entity_id_idx ON changes(entity_id);
CREATE INDEX IF NOT EXISTS error_logs_severity_idx ON error_logs(severity);
CREATE INDEX IF NOT EXISTS point_reviews_user_id_idx ON point_reviews(user_id);
CREATE INDEX IF NOT EXISTS point_reviews_point_id_idx ON point_reviews(point_id);

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


