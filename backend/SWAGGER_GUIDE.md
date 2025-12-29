# 📚 Руководство по Swagger UI для EshKush API

## 🚀 Быстрый старт

### Доступ к Swagger UI

Swagger UI доступен по адресу: **http://localhost:8081**

Для доступа к API напрямую: **http://localhost:8080**

---

## 📖 Что такое Swagger UI?

Swagger UI - это интерактивная документация API, которая позволяет:
- ✅ Просматривать все доступные endpoints
- ✅ Тестировать запросы прямо из браузера
- ✅ Изучать структуру данных (schemas)
- ✅ Понимать параметры запросов и ответов

---

## 🎯 Основные возможности

### 1. Просмотр endpoints

Все endpoints разделены по **тегам (категориям)**:

| Тег | Описание | Примеры endpoints |
|-----|----------|-------------------|
| **Аутентификация** | Регистрация, вход, токены | `/auth/register`, `/auth/google`, `/auth/refresh` |
| **Точки** | Точки продажи | `/points`, `/points/{id}`, `/points/{id}/reviews` |
| **Продукты** | Каталог продуктов | `/products`, `/products/{id}` |
| **Заказы** | Управление заказами | `/orders`, `/orders/{id}`, `/orders/user/{userId}` |
| **Кеш** ⭐ | Управление кешем | `/cache/stats`, `/cache/clear`, `/cache/get/{key}` |
| **Пользователи** | Профили и избранное | `/user/profile`, `/users/{userId}/favorites` |
| **Уведомления** | Push-уведомления | `/notifications/user/{userId}`, `/notifications/unread/{userId}` |
| **Логи** | Логи действий | `/logs/user/{userId}`, `/logs/action/{actionType}` |
| **Изменения** | История изменений | `/changes`, `/changes/entity/{entityType}/{entityId}` |
| **Ошибки** | Логи ошибок | `/error-logs`, `/errors/severity/{severity}` |
| **Статистика** | Статистика партнеров | `/statistics/point/{pointId}` |
| **Избранное** | Избранные точки | `/favorites/user/{userId}` |

---

## 🔐 Аутентификация

### Как использовать JWT токены в Swagger

1. **Получите токен:**
   - Разверните раздел **"Аутентификация"**
   - Используйте endpoint `/auth/register` или `/auth/google`
   - Выполните запрос и скопируйте `access_token` из ответа

2. **Настройте авторизацию:**
   - Нажмите кнопку **"Authorize"** (🔒) в правом верхнем углу
   - В поле **bearerAuth** введите: `Bearer <ваш_токен>`
   - Нажмите **"Authorize"**, затем **"Close"**

3. **Теперь все защищенные endpoints доступны!**

### Пример токена:
```
Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 🧪 Тестирование endpoints

### Простой GET запрос

**Пример: Получить список точек**

1. Разверните раздел **"Точки"**
2. Найдите `GET /points`
3. Нажмите **"Try it out"**
4. Заполните параметры (опционально):
   - `latitude`: 55.7558
   - `longitude`: 37.6173
   - `radius`: 5000
   - `page`: 1
   - `limit`: 20
5. Нажмите **"Execute"**
6. Смотрите результат в разделе **"Responses"**

### POST запрос с телом

**Пример: Создать заказ**

1. Разверните раздел **"Заказы"**
2. Найдите `POST /orders`
3. Нажмите **"Try it out"**
4. Отредактируйте JSON в **Request body**:
```json
{
  "pointId": 1,
  "products": [
    {
      "productId": 5,
      "quantity": 2
    },
    {
      "productId": 10,
      "quantity": 1
    }
  ]
}
```
5. Нажмите **"Execute"**

---

## ⚡ Эндпоинты кеша (новые!)

### 📊 Статистика кеша
**GET `/cache/stats`**
```json
{
  "success": true,
  "data": {
    "keyspace": 5,
    "expired_keys": 0,
    "memory_usage": "in-memory",
    "cache_type": "memory",
    "errors": 0
  }
}
```

### 🗑️ Очистить весь кеш
**DELETE `/cache/clear`**
```json
{
  "success": true,
  "message": "Кеш очищен"
}
```

### 🔍 Очистить кеш по паттерну
**DELETE `/cache/clear/{pattern}`**

Пример: удалить все ключи точек
```
DELETE /cache/clear/points:*
```

### 💾 Получить значение
**GET `/cache/get/{key}`**

Пример:
```
GET /cache/get/points:all
```

Ответ:
```json
{
  "success": true,
  "key": "points:all",
  "value": [...],
  "exists": true
}
```

### ✏️ Установить значение
**POST `/cache/set`**
```json
{
  "key": "custom:key",
  "value": { "data": "example" },
  "ttl": 300
}
```

### 🔐 Статистика токенов
**GET `/cache/tokens/stats`**
```json
{
  "success": true,
  "data": {
    "total_tokens": 10,
    "blacklisted_tokens": 2,
    "cached_validations": 8
  }
}
```

### ❌ Инвалидировать токен
**POST `/cache/tokens/invalidate`**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "isRefreshToken": false
}
```

### 🚫 Инвалидировать все токены пользователя
**POST `/cache/tokens/invalidate-user`**
```json
{
  "userId": 123
}
```

### 🧹 Очистить истекшие токены
**POST `/cache/tokens/cleanup`**
```json
{
  "success": true,
  "message": "Истекшие токены очищены"
}
```

---

## 📋 Коды ответов

| Код | Описание |
|-----|----------|
| `200` | ✅ Успешный запрос |
| `201` | ✅ Ресурс создан |
| `400` | ❌ Неверные параметры запроса |
| `401` | ❌ Не авторизован (нужен токен) |
| `403` | ❌ Доступ запрещен |
| `404` | ❌ Ресурс не найден |
| `500` | ❌ Внутренняя ошибка сервера |

---

## 🎨 Структура данных (Schemas)

Swagger UI автоматически показывает структуру всех моделей:

### Основные модели:

**User** - Пользователь
```json
{
  "id": 1,
  "email": "user@example.com",
  "username": "john_doe",
  "role": "user",
  "phoneNumber": "+79001234567",
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

**Point** - Точка продажи
```json
{
  "id": 1,
  "name": "Точка на Арбате",
  "address": "ул. Арбат, д. 10",
  "latitude": 55.7522,
  "longitude": 37.5991,
  "rating": 4.5,
  "description": "Описание точки",
  "categories": [],
  "reviews": [],
  "partnerId": 5
}
```

**Product** - Продукт
```json
{
  "id": 1,
  "name": "Хлеб бородинский",
  "description": "Свежий хлеб",
  "price": 45.50,
  "categoryId": 2,
  "pointId": 1,
  "isAvailable": true
}
```

**Order** - Заказ
```json
{
  "id": 1,
  "userId": 10,
  "pointId": 5,
  "status": "pending",
  "totalAmount": 250.00,
  "createdAt": "2024-01-01T10:00:00Z"
}
```

---

## 🔧 Полезные фильтры

### Фильтр точек
```
GET /points?categoryId=1&minRating=4.0&sort=rating&order=desc&page=1&limit=20
```

### Фильтр заказов
```
GET /orders?status=completed&startDate=2024-01-01T00:00:00Z&endDate=2024-12-31T23:59:59Z
```

### Поиск продуктов
```
GET /products?search=хлеб&categoryId=2&page=1&limit=50
```

---

## 🐛 Отладка

### Просмотр запроса в Swagger UI

1. После выполнения запроса откройте **"Response"**
2. Прокрутите вверх до **"Request URL"**
3. Скопируйте URL для использования в других инструментах (Postman, curl)

### Пример curl команды
```bash
curl -X GET "http://localhost:8080/points?page=1&limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Пример PowerShell
```powershell
$headers = @{
  "Authorization" = "Bearer YOUR_TOKEN_HERE"
}
Invoke-RestMethod -Uri "http://localhost:8080/points" -Headers $headers -Method GET
```

---

## 📦 Экспорт документации

### Скачать OpenAPI spec

Доступен по адресу: **http://localhost:8081/swagger.json**

```bash
# Linux/Mac
wget http://localhost:8081/swagger.json -O api-spec.json

# Windows PowerShell
Invoke-WebRequest -Uri http://localhost:8081/swagger.json -OutFile api-spec.json
```

### Использование в Postman

1. Откройте Postman
2. **File → Import**
3. Вставьте URL: `http://localhost:8081/swagger.json`
4. Нажмите **"Import"**
5. Вся коллекция endpoints добавится автоматически!

---

## 🎯 Быстрые тесты

### Тест 1: Проверка кеша
```bash
# 1. Получить статистику
GET http://localhost:8080/cache/stats

# 2. Получить список точек (закешируется)
GET http://localhost:8080/points

# 3. Проверить, что появился ключ
GET http://localhost:8080/cache/get/points:all

# 4. Очистить кеш
DELETE http://localhost:8080/cache/clear

# 5. Проверить статистику снова
GET http://localhost:8080/cache/stats
```

### Тест 2: Проверка авторизации
```bash
# 1. Регистрация
POST http://localhost:8080/auth/register
{
  "email": "test@example.com",
  "username": "testuser",
  "password": "password123",
  "phoneNumber": "+79001234567"
}

# 2. Получить профиль (с токеном)
GET http://localhost:8080/user/profile
Authorization: Bearer <ваш_токен>
```

---

## 🚀 Производительность

### Кешируемые endpoints

| Endpoint | TTL | Инвалидация |
|----------|-----|-------------|
| `GET /points` | 30 мин | При изменении точек |
| `GET /products` | 30 мин | При изменении продуктов |
| `GET /users` | 15 мин | При изменении пользователей |
| `GET /cities` | 60 мин | При изменении городов |

### Производительность кеша

Из тестов:
- **Points**: 21ms → 15ms (ускорение 3.5x)
- **Products**: 64ms → 16ms (ускорение 4x)
- **Cities**: 54ms → 16ms (ускорение 3.4x)

---

## 🔗 Полезные ссылки

- **Swagger UI**: http://localhost:8081
- **Backend API**: http://localhost:8080
- **pgAdmin**: http://localhost:5050
- **Frontend**: http://localhost:3000
- **Nginx**: http://localhost:80
- **Redis**: localhost:6379

---

## 💡 Советы

1. **Используйте фильтр** в Swagger UI (поле поиска вверху) для быстрого нахождения endpoints
2. **Сохраняйте токены** - скопируйте токен после регистрации и храните в блокноте
3. **Проверяйте schemas** - нажимайте на модели в разделе "Schemas" внизу страницы
4. **Используйте примеры** - Swagger UI показывает примеры запросов и ответов
5. **Тестируйте сразу** - не нужен Postman, все можно протестировать прямо в браузере!

---

## 🆘 Проблемы?

### Swagger UI не загружается
```bash
# Перезапустить контейнер
docker-compose restart swagger
```

### 401 Unauthorized
- Проверьте токен в кнопке "Authorize"
- Убедитесь, что токен начинается с `Bearer `
- Получите новый токен через `/auth/register` или `/auth/google`

### CORS ошибки
- Swagger UI настроен с правильными CORS headers
- Если проблема сохраняется, проверьте `docker-compose.yml`

---

## 📝 Обновление документации

Для обновления Swagger документации:

1. Отредактируйте `backend/lib/config/swagger.json`
2. Пересоберите контейнер:
```bash
docker-compose build --no-cache swagger
docker-compose up -d swagger
```
3. Обновите страницу в браузере (Ctrl+F5)

---

## 🎉 Готово!

Теперь вы можете полноценно работать с API через Swagger UI!

**Удачного тестирования! 🚀**

