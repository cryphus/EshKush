
# EshKush - Инструкция по установке

## Пошаговая инструкция

### 1. Запуск проекта

docker-compose up --build(Дальше просто docker-compose up)


После успешного запуска вы увидите логи от:
- PostgreSQL (база данных)
- Backend (Dart сервер)
- Frontend (Flutter web)
- pgAdmin (интерфейс для БД)

### 2. Проверка работоспособности(в целом в докере все увидите)
Откройте в браузере:
- Frontend: http://localhost:8080
- pgAdmin (для просмотра БД): http://localhost:5050

### 3. Доступ к базе данных через pgAdmin
1. Откройте http://localhost:5050
2. Войдите в pgAdmin:
   - Email: admin@admin.com
   - Password: admin
3. Добавьте новый сервер:
   - Правый клик на "Servers" -> Register -> Server
   - Вкладка "General":
     - Name: EshKush (или любое другое)
   - Вкладка "Connection":
     - Host: postgres
     - Port: 5432
     - Database: flutter_auth
     - Username: postgres
     - Password: TQr132123

### 4. Остановка проекта или полная очистка (если что-то пошло не так)
# Выполнить в терминале:
docker-compose down

# Удаляем все тома (включая БД (без меня бд не трогать))
docker-compose down -v


### Просмотр логов

# Все логи

docker-compose logs

# Логи конкретного сервиса

docker-compose logs frontend
docker-compose logs backend
docker-compose logs postgres

