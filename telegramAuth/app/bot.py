import logging
import sys
import os
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS
import uuid
import asyncio
import requests
import json
import base64

# Добавляем корневую директорию в PYTHONPATH
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from telegram import Update, ReplyKeyboardMarkup, KeyboardButton, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes, CallbackQueryHandler
from config import TELEGRAM_BOT_TOKEN, BOT_USERNAME, WEBHOOK_HOST, WEBHOOK_SSL_CERT, BACKEND_URL, FLASK_PORT, TELEGRAM_SERVICE_SECRET
from app.database import (
    init_db, create_auth_session, get_active_session,
    deactivate_session, create_user, update_user_phone,
    get_user_by_token, get_user_by_id, get_user_by_phone
)

# Настройка логирования
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app, resources={
    r"/api/*": {
        "origins": ["*"],
        "methods": ["GET", "POST", "OPTIONS"],
        "allow_headers": ["Content-Type"]
    }
})

# Инициализация базы данных при запуске
init_db()

@app.route('/api/auth/telegram/initiate', methods=['POST', 'OPTIONS'])
def initiate_auth():
    if request.method == 'OPTIONS':
        return '', 200
        
    try:
        logger.info("Received request to initiate auth")
        token = str(uuid.uuid4())
        logger.info(f"Generated new token: {token}")
        
        logger.info("Attempting to create auth session...")
        create_auth_session(token)
        logger.info("Auth session created successfully")
        
        return jsonify({'token': token}), 200
    except Exception as e:
        logger.error(f"Error initiating auth: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/auth/telegram/check_user', methods=['POST'])
def check_user():
    try:
        data = request.get_json()
        phone_number = data.get('phoneNumber')

        if not phone_number:
            return jsonify({'error': 'Phone number is required'}), 400

        # Отправляем запрос в основной бекенд для проверки пользователя
        response = requests.post(
            f'{BACKEND_URL}/auth/check_user',
            json={'phoneNumber': phone_number},
            timeout=5
        )
        
        if response.status_code == 200:
            return response.json()
        else:
            return jsonify({
                'exists': False,
                'user': None
            })
            
    except Exception as e:
        logger.error(f"Error checking user: {str(e)}")
        return jsonify({'error': str(e)}), 500

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Обработчик команды /start"""
    try:
        user = update.effective_user
        args = context.args

        if not args:
            await update.message.reply_text(
                "Для авторизации перейдите по специальной ссылке из приложения."
            )
            return

        token = args[0]
        logger.info(f"Received token: {token}")
        
        session = get_active_session(token)
        if not session:
            await update.message.reply_text(
                "Недействительный или устаревший токен авторизации. "
                "Пожалуйста, вернитесь в приложение и попробуйте снова."
            )
            return

        # Создаем кнопку для отправки контакта
        keyboard = [[KeyboardButton("Поделиться контактом", request_contact=True)]]
        reply_markup = ReplyKeyboardMarkup(keyboard, one_time_keyboard=True)
        
        # Создаем пользователя
        create_user(
            user_id=user.id,
            first_name=user.first_name,
            last_name=user.last_name,
            token=token
        )
        
        await update.message.reply_text(
            "Для завершения авторизации, пожалуйста, поделитесь своим номером телефона.",
            reply_markup=reply_markup
        )
    except Exception as e:
        logger.error(f"Error in start command: {str(e)}")
        await update.message.reply_text(
            "Произошла ошибка. Пожалуйста, попробуйте позже."
        )

async def handle_contact(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Обработчик получения контакта"""
    try:
        logger.info("Получен контакт от пользователя")
        contact = update.message.contact
        user = update.effective_user
        
        if contact is None:
            logger.warning("Контакт не получен")
            await update.message.reply_text("Пожалуйста, поделитесь контактом")
            return

        user_id = user.id
        phone_number = contact.phone_number
        first_name = user.first_name
        last_name = user.last_name or ""

        logger.info(f"Обработка контакта: user_id={user_id}, phone={phone_number}")

        # Сохраняем данные пользователя в базу данных бота
        try:
            update_user_phone(user_id, phone_number)
            logger.info("Номер телефона успешно обновлен в базе данных бота")
        except Exception as e:
            logger.error(f"Ошибка при обновлении номера телефона: {e}")
            raise
        
        # Проверяем существование пользователя и логинимся (если существует)
        # через основной backend. Секретный заголовок доказывает бекенду,
        # что номер телефона подтверждён Telegram Contact API, а не введён
        # клиентом напрямую.
        try:
            logger.info("Отправка запроса на логин/проверку пользователя в бекенд")
            response = requests.post(
                f'{BACKEND_URL}/auth/telegram',
                json={
                    'phoneNumber': phone_number,
                    'firstName': first_name,
                    'lastName': last_name
                },
                headers={'X-Telegram-Service-Secret': TELEGRAM_SERVICE_SECRET},
                timeout=5
            )

            logger.info(f"Получен ответ: {response.status_code}")

            if response.status_code == 200:
                data = response.json()
                user_exists = data.get('exists', False)

                # Формируем данные для возврата в приложение.
                # Если пользователь уже существует — сразу передаём токены,
                # чтобы фронтенд мог войти без пароля.
                app_data = {
                    'phoneNumber': phone_number,
                    'firstName': first_name,
                    'lastName': last_name,
                    'exists': user_exists,
                }
                if user_exists:
                    app_data['accessToken'] = data.get('access_token')
                    app_data['refreshToken'] = data.get('refresh_token')

                # Кодируем данные в URL-safe base64 для передачи через deep link
                # (обычный base64 может содержать '+' и '/', которые ломают query string)
                encoded_data = base64.urlsafe_b64encode(json.dumps(app_data).encode()).decode()
                
                # Формируем deep link в приложение (используем APP_URL из конфига)
                from config import APP_URL
                deep_link = f"{APP_URL}/auth/telegram?data={encoded_data}"
                
                logger.info(f"Создан deep link: {deep_link}")

                # Telegram принимает URL инлайн-кнопок только по https (или
                # tg://, t.me). Для локальной разработки (http://localhost:...)
                # кнопка была бы отклонена API ("wrong http url"), поэтому
                # шлём ссылку обычным текстом — так работает с любой схемой.
                reply_markup = None
                if deep_link.startswith('https://'):
                    keyboard = [
                        [
                            InlineKeyboardButton(
                                "Вернуться в приложение",
                                url=deep_link
                            )
                        ]
                    ]
                    reply_markup = InlineKeyboardMarkup(keyboard)
                    link_line = ""
                else:
                    link_line = f"\n\nОткройте ссылку в браузере: {deep_link}"

                if user_exists:
                    # Если пользователь существует
                    await update.message.reply_text(
                        f"✅ Авторизация успешна!\n\n"
                        f"Теперь вы можете вернуться в приложение.{link_line}",
                        reply_markup=reply_markup
                    )
                else:
                    # Если пользователь не существует
                    await update.message.reply_text(
                        f"Здравствуйте, {first_name}!\n\n"
                        f"Для завершения регистрации в нашем сервисе, пожалуйста, "
                        f"укажите дополнительные данные в приложении.{link_line}",
                        reply_markup=reply_markup
                    )
            else:
                logger.error(f"Ошибка проверки пользователя: {response.status_code}")
                raise Exception(f"Ошибка проверки пользователя: {response.status_code}")
                
        except requests.exceptions.RequestException as e:
            logger.error(f"Ошибка при отправке запроса: {e}")
            raise Exception("Не удалось подключиться к серверу приложения")
        except Exception as e:
            logger.error(f"Ошибка при проверке пользователя: {e}")
            raise
        
    except Exception as e:
        logger.error(f"Критическая ошибка в обработчике контакта: {str(e)}")
        await update.message.reply_text(
            "Произошла ошибка при обработке вашего контакта. Пожалуйста, попробуйте позже или обратитесь в поддержку."
        )

async def handle_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Обработчик нажатия на кнопку"""
    try:
        query = update.callback_query
        await query.answer()
        
        if query.data.startswith('return_to_app_'):
            token = query.data.split('_')[-1]
            
            # Проверяем существование пользователя
            user = get_user_by_token(token)
            if not user:
                await query.message.reply_text(
                    "Ошибка: пользователь не найден. "
                    "Пожалуйста, вернитесь в приложение и начните процесс заново."
                )
                return
                
            # Формируем deep link
            app_data = {
                'token': token,
                'firstName': user['first_name'],
                'lastName': user['last_name'],
                'phoneNumber': user['phone_number']
            }
            
            from config import APP_URL
            deep_link = f"{APP_URL}/#/auth/telegram?data={json.dumps(app_data)}"
            
            # Отправляем сообщение с deep link
            await query.message.reply_text(
                f"Нажмите [здесь]({deep_link}), чтобы вернуться в приложение.",
                parse_mode='Markdown'
            )
            
            # Деактивируем сессию
            deactivate_session(token)
    except Exception as e:
        logger.error(f"Error handling callback: {str(e)}")
        await query.message.reply_text(
            "Произошла ошибка. Пожалуйста, попробуйте позже."
        )

def main():
    """Запуск бота и API"""
    try:
        # Создание приложения Telegram
        application = Application.builder().token(TELEGRAM_BOT_TOKEN).build()
        
        # Добавление обработчиков
        application.add_handler(CommandHandler("start", start))
        application.add_handler(MessageHandler(filters.CONTACT, handle_contact))
        application.add_handler(CallbackQueryHandler(handle_callback))
        
        # Запуск API в отдельном потоке
        import threading
        api_thread = threading.Thread(target=lambda: app.run(host='0.0.0.0', port=FLASK_PORT))
        api_thread.daemon = True
        api_thread.start()
        
        # Запуск бота в режиме polling
        application.run_polling()
    except Exception as e:
        logger.error(f"Error in main: {str(e)}")
        raise

if __name__ == '__main__':
    main() 