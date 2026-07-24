import sqlite3
import logging
from datetime import datetime, timedelta
import os

# Настройка логирования
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# Путь к базе данных
DATABASE_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'auth.db')

def get_db_connection():
    """Создает соединение с базой данных"""
    conn = sqlite3.connect(DATABASE_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    """Инициализация базы данных"""
    try:
        logger.info(f"Initializing database at: {DATABASE_PATH}")
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Таблица для сессий авторизации
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS auth_sessions (
                token TEXT PRIMARY KEY,
                user_id INTEGER,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                expires_at TIMESTAMP,
                is_active BOOLEAN DEFAULT TRUE
            )
        ''')
        
        # Таблица для пользователей
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS users (
                user_id INTEGER PRIMARY KEY,
                first_name TEXT,
                last_name TEXT,
                phone_number TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                token TEXT,
                FOREIGN KEY (token) REFERENCES auth_sessions(token)
            )
        ''')
        
        conn.commit()
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"Error initializing database: {str(e)}")
        raise
    finally:
        conn.close()

def create_auth_session(token: str, user_id: int = None):
    """Создание новой сессии авторизации"""
    try:
        logger.info(f"Creating auth session with token: {token}")
        conn = get_db_connection()
        cursor = conn.cursor()
        
        expires_at = datetime.now() + timedelta(minutes=15)
        
        cursor.execute('''
            INSERT INTO auth_sessions (token, user_id, expires_at, is_active)
            VALUES (?, ?, ?, TRUE)
        ''', (token, user_id, expires_at))
        
        conn.commit()
        logger.info("Auth session created successfully")
    except Exception as e:
        logger.error(f"Error creating auth session: {str(e)}")
        raise
    finally:
        conn.close()

def get_active_session(token: str):
    """Получение активной сессии по токену"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT * FROM auth_sessions 
            WHERE token = ? 
            AND is_active = TRUE 
            AND expires_at > datetime('now')
        ''', (token,))
        
        session = cursor.fetchone()
        return dict(session) if session else None
    except Exception as e:
        logger.error(f"Error getting active session: {str(e)}")
        raise
    finally:
        conn.close()

def create_user(user_id: int, first_name: str, last_name: str, token: str):
    """Создание пользователя или обновление его данных, если Telegram-пользователь
    уже проходил авторизацию раньше (повторный /start — обычный сценарий,
    не должен приводить к UNIQUE constraint failed по user_id)."""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute('''
            INSERT INTO users (user_id, first_name, last_name, token)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(user_id) DO UPDATE SET
                first_name = excluded.first_name,
                last_name = excluded.last_name,
                token = excluded.token
        ''', (user_id, first_name, last_name, token))

        conn.commit()
        logger.info(f"User {user_id} created/updated successfully")
    except Exception as e:
        logger.error(f"Error creating user: {str(e)}")
        raise
    finally:
        conn.close()

def update_user_phone(user_id: int, phone_number: str):
    """Обновление номера телефона пользователя"""
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            UPDATE users 
            SET phone_number = ? 
            WHERE user_id = ?
        ''', (phone_number, user_id))
        
        conn.commit()
        logger.info(f"Phone number updated for user {user_id}")
    except Exception as e:
        logger.error(f"Error updating phone number: {str(e)}")
        raise
    finally:
        if conn:
            conn.close()

def get_user_by_id(user_id: int):
    """Получение пользователя по ID"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute('SELECT * FROM users WHERE user_id = ?', (user_id,))
        user = cursor.fetchone()
        return dict(user) if user else None
    except Exception as e:
        logger.error(f"Error getting user by ID: {str(e)}")
        raise
    finally:
        conn.close()

def get_user_by_token(token: str):
    """Получение пользователя по токену"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute('SELECT * FROM users WHERE token = ?', (token,))
        user = cursor.fetchone()
        return dict(user) if user else None
    except Exception as e:
        logger.error(f"Error getting user by token: {str(e)}")
        raise
    finally:
        conn.close()

def deactivate_session(token: str):
    """Деактивация сессии авторизации"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            UPDATE auth_sessions 
            SET is_active = FALSE 
            WHERE token = ?
        ''', (token,))
        
        conn.commit()
        logger.info(f"Session {token} deactivated")
    except Exception as e:
        logger.error(f"Error deactivating session: {str(e)}")
        raise
    finally:
        conn.close()

def get_user_by_phone(phone_number):
    """Получить пользователя по номеру телефона"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT * FROM users 
            WHERE phone_number = ?
        ''', (phone_number,))
        
        user = cursor.fetchone()
        conn.close()
        
        if user:
            return {
                'user_id': user[0],
                'first_name': user[1],
                'last_name': user[2],
                'phone_number': user[3]
            }
        return None
        
    except Exception as e:
        logger.error(f"Error getting user by phone: {str(e)}")
        return None

def clear_database():
    """Очистка всех таблиц в базе данных"""
    try:
        logger.info("Clearing database...")
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Удаляем все записи из таблиц
        cursor.execute('DELETE FROM auth_sessions')
        cursor.execute('DELETE FROM users')
        
        conn.commit()
        logger.info("Database cleared successfully")
    except Exception as e:
        logger.error(f"Error clearing database: {str(e)}")
        raise
    finally:
        conn.close()

if __name__ == '__main__':
    init_db()
    clear_database()