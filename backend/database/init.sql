DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM ('guest', 'user', 'business', 'support', 'admin');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'point_category') THEN
        CREATE TYPE point_category AS ENUM ('shop', 'restaurant', 'cafe', 'other');
    END IF;
END
$$;

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    sum_co2 INTEGER DEFAULT 0,
    money INTEGER DEFAULT 0,
    number VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL,
    favorite_ids INTEGER[] DEFAULT '{}',
    role user_role DEFAULT 'user',
    purchases TEXT[] DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS points (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    category point_category NOT NULL,
    rating DECIMAL(3,2) DEFAULT 0.0,
    city VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    products TEXT[] NOT NULL,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    point_id INTEGER REFERENCES points(id) ON DELETE CASCADE,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS users_username_idx ON users(username);
CREATE INDEX IF NOT EXISTS users_email_idx ON users(email);
CREATE INDEX IF NOT EXISTS points_city_idx ON points(city);
CREATE INDEX IF NOT EXISTS points_category_idx ON points(category);
CREATE INDEX IF NOT EXISTS orders_user_id_idx ON orders(user_id);
CREATE INDEX IF NOT EXISTS orders_point_id_idx ON orders(point_id);


