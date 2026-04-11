# EshKush — План развития проекта

> Последнее обновление: 2026-04-11 (Фаза 3 завершена)
> Статус: в разработке



---

## Фаза 1: Критические доработки фронтенда

Фронтенд сейчас на ~60%. Экраны существуют, но данные захардкожены. Без связки с API приложение нефункционально.

### 1.1 State Management ✅
- [x] Выбрать и подключить state manager — **Riverpod** (`flutter_riverpod: ^2.4.9`)
- [x] Создать провайдеры для: auth, profile, orders, products, points, favorites, cart, notifications

### 1.2 API-сервис ✅
- [x] Создать единый `ApiClient` на базе Dio с interceptors (auth token, refresh, error handling)
- [x] Реализовать сервисы: `OrderService`, `ProductService`, `PointService`, `ProfileService`, `FavoriteService`, `NotificationService`, `CartService`
- [x] Обработка ошибок: toast/snackbar при сетевых ошибках, 401 → refresh → retry

### 1.3 Привязка экранов к API ✅
- [x] `HomeScreen` — загрузка заказов пользователя, категорий
- [x] `OffersScreen` — загрузка продуктов/точек с пагинацией, фильтрация, поиск
- [x] `FavoritesScreen` — загрузка избранного с API, добавление/удаление
- [x] `ProfileScreen` — загрузка профиля (CO2, сбережения, покупки) с API
- [x] `CartScreen` — полный флоу: добавление, удаление, изменение количества, оформление заказа
- [x] `ProductPage` — загрузка деталей продукта, кнопка "Купить" → добавление в корзину/заказ

### 1.4 UX-улучшения ✅
- [x] Pull-to-refresh на списках
- [x] Skeleton/shimmer loading states
- [x] Empty states (нет заказов, нет избранного и т.д.)
- [x] Offline-индикатор (нет сети)

---

## Фаза 2: Платёжная система

Транзакции логируются, но реальной оплаты нет. Без этого приложение не может работать.

Вот это уже сделано/не сделано:

  √ Read Service.dart and OrderService.dart for routing/order flow
  √ Read init.sql for payment_transactions schema
  √ Migrate provider_transaction_id from int to text
  √ Add http package to backend dependencies
  √ Add YooKassa credentials to AppConfig and docker-compose
  √ Create YooKassaService with createPayment/getPayment/refundPayment
  √ Create PaymentGatewayService bridging YooKassa и PaymentTransactionsRepository
  √ Add PaymentGatewayController с /payments/create, /payments/webhook, /payments/refund

### 2.1 Интеграция платёжного шлюза
- [x] Выбрать провайдера: **ЮKassa** (Россия)
- [x] Backend: `YooKassaService` — тонкая обёртка над REST (createPayment / getPayment / refundPayment)
- [x] Backend: `PaymentGatewayService` — оркестратор (initiatePayment / handleWebhook / refund), связывает YooKassa и `PaymentTransactionsRepository`
- [x] Backend: webhook-эндпоинт `/payments/webhook` (публичный, защита shared-secret через `X-Webhook-Secret`)
- [x] Backend: `PaymentTransaction.provider_transaction_id` — TEXT, связан с id платежа YooKassa
- [ ] Production: заменить YOOKASSA_SHOP_ID/SECRET_KEY в `.env` на боевые, настроить YOOKASSA_RETURN_URL

### 2.2 Флоу оплаты на фронте
- [x] `PaymentApiService` — обёртка над `/payments/*` и `/payment-transactions/*`
- [x] `paymentProvider` (Riverpod) — состояние платежа, `initiate` + `startPolling`
- [x] `PaymentMethodScreen` — выбор карта/СБП, инициирует платёж, открывает `confirmation_url` через `url_launcher`
- [x] `PaymentWaitingScreen` — polling `/payment-transactions/order`, обработка успех/отказ/возврат
- [x] `OrderConfirmationScreen` — чек с деталями заказа и транзакции
- [x] Корзина: после checkout redirect на `PaymentMethodScreen(orders.first)` через `pushReplacement`
- [ ] Multi-point оплата (сейчас платим только за первый заказ из корзины)
- [ ] Deep link `eshkush://payments/return` для мгновенного подтверждения вместо polling

### 2.3 Возвраты
- [x] Backend: эндпоинт `POST /orders/{id}/refund` (авторизация по JWT, проверка владельца заказа)
- [x] Логика возврата: проверка статуса (pending/processing), срока (`REFUND_WINDOW_HOURS`), вызов `YooKassaService.refundPayment`, перевод заказа в `cancelled`
- [x] Frontend: `OrderApiService.refundOrder` + `OrdersNotifier.cancelOrder` с оптимистичным обновлением
- [x] Frontend: на `HomeScreen` в карточке активного заказа — `PopupMenuButton` с "Отменить заказ", `AlertDialog` подтверждения, snackbar об успехе/ошибке

---

## Фаза 3: Геолокация и карта

Координаты есть в БД, но не используются. Для Too Good To Go аналога карта — ключевой функционал.

### 3.1 Backend: геопоиск ✅
- [x] Добавить `earth_distance` + `cube` extensions в init.sql + GIST-индекс
  `points USING gist (ll_to_earth(latitude, longitude))`
- [x] `PointRepository.findNearby(lat, lon, radiusM, limit)` — возвращает
  `List<NearbyPoint>` с distance_m, отсортированные по возрастанию
- [x] `PointService.getPointsNearby` — валидация, clamp радиуса (макс. 50 км)
- [x] Эндпоинт `GET /points/nearby?lat&lon&radius&limit` (+ swagger)
- [x] `PointResponseDto` расширен опциональным `distance_m`

### 3.2 Frontend: карта ✅
- [x] Интегрировать Yandex MapKit (`yandex_mapkit: ^4.0.1`) + `geolocator` + `permission_handler`
- [x] Разрешения: ACCESS_FINE/COARSE_LOCATION в AndroidManifest,
  NSLocationWhenInUseUsageDescription в Info.plist
- [x] Meta-data `com.yandex.maps.MAPKIT_API_KEY` в манифесте + `YandexMapkitApiKey` в Info.plist
  (placeholder, заменить на боевой ключ перед релизом)
- [x] Инициализация `AndroidYandexMap.useAndroidViewSurface = false` в main.dart
- [x] Frontend `PointApiService.getNearby` + `nearbyPointsProvider` (family)
- [x] `Point` модель расширена опциональным `distanceM` + `distanceLabel` геттер
- [x] Виджет `PointsMap` (lib/widgets/points_map.dart) — YandexMap с маркерами,
  программно сгенерированными пинами, bottom sheet превью точки, кнопка "моя геолокация"
- [x] `OffersScreen` таб "Карта" подключён к `PointsMap`
- [x] Фильтр "Рядом" на `OffersScreen` (кнопка near_me) — Haversine-сортировка
  клиентской стороны + отображение distance на карточках
- [ ] Кластеризация маркеров на карте (оптимизация, когда точек станет много)

### 3.3 Production TODO
- [ ] Получить боевой Yandex MapKit API key (free tier, ~25k MAU)
  https://developer.tech.yandex.ru/services/
- [ ] Заменить `REPLACE_WITH_YANDEX_MAPKIT_API_KEY` в
  `android/app/src/main/AndroidManifest.xml` и `ios/Runner/Info.plist`

---

## Фаза 4: Push-уведомления и реальное время

Сейчас уведомления только in-app. Пользователь не узнает о новых предложениях, если не откроет приложение.

### 4.1 Push-уведомления
- [ ] Подключить Firebase Cloud Messaging (FCM)
- [ ] Backend: хранить device token пользователя
- [ ] Backend: сервис отправки push через FCM API
- [ ] Триггеры: новый заказ, смена статуса, промо-акции, напоминания

### 4.2 WebSocket (опционально)
- [ ] Backend: WebSocket endpoint для real-time обновлений
- [ ] Frontend: подписка на обновления заказа (статус в реальном времени)

---

## Фаза 5: Загрузка изображений

Сейчас изображения хранятся как URL-ссылки. Нет возможности загружать фото.

### 5.1 Файловое хранилище
- [ ] Выбрать: S3-совместимое хранилище (MinIO для self-hosted / AWS S3 / Yandex Object Storage)
- [ ] Backend: `FileUploadService` с методами `upload()`, `delete()`, `getUrl()`
- [ ] Backend: эндпоинт `POST /upload` (multipart/form-data)
- [ ] Ограничения: макс. размер файла, допустимые форматы (jpg, png, webp)
- [ ] Генерация thumbnails (опционально)

### 5.2 Использование во фронте
- [ ] Загрузка аватара пользователя
- [ ] Загрузка фото продуктов (для партнёров)
- [ ] Загрузка фото точки

---

## Фаза 6: Email-сервис

Нет email-уведомлений — критично для подтверждения регистрации и сброса пароля.

### 6.1 Интеграция
- [ ] Подключить SMTP-сервис (SendGrid / AWS SES / Mailgun)
- [ ] Backend: `EmailService` с шаблонами писем
- [ ] Письма: подтверждение email, сброс пароля, подтверждение заказа, чек

### 6.2 Сброс пароля
- [ ] Backend: `POST /auth/forgot-password` — генерация токена, отправка письма
- [ ] Backend: `POST /auth/reset-password` — валидация токена, смена пароля
- [ ] Frontend: экраны "Забыли пароль?" и "Новый пароль"

---

## Фаза 7: Админ-панель

Нет интерфейса для управления платформой.

### 7.1 Веб-панель
- [ ] Отдельное Flutter Web приложение или раздел в текущем (по роли admin)
- [ ] Дашборд: общая статистика (заказы, пользователи, выручка, рейтинг)
- [ ] Управление пользователями: список, блокировка, смена ролей
- [ ] Управление партнёрами: одобрение заявок, настройки
- [ ] Управление заказами: просмотр, отмена, возврат
- [ ] Управление продуктами/точками: модерация
- [ ] Просмотр логов: action_logs, error_logs, changes

### 7.2 Панель партнёра
- [ ] Дашборд партнёра: заказы, выручка, рейтинг
- [ ] Управление точками: добавление, редактирование, часы работы
- [ ] Управление продуктами: добавление, цена, наличие, фото
- [ ] Просмотр отзывов

---

## Фаза 8: Безопасность и production-readiness

### 8.1 Безопасность
- [ ] CORS: ограничить допустимые origins (убрать wildcard)
- [ ] Rate limiting: подключить на `/auth/*`, `/login` (уже есть библиотека)
- [ ] Секреты: вынести из docker-compose в `.env` файл (добавить в .gitignore)
- [ ] HTTPS: настроить SSL-сертификат в Nginx (Let's Encrypt)
- [ ] Валидация размера запросов (защита от DoS)

### 8.2 Мониторинг
- [ ] Health-check эндпоинт `GET /health` (статус БД, Redis, uptime)
- [ ] Подключить метрики (Prometheus) и дашборд (Grafana)
- [ ] Алерты на ошибки (Sentry / аналог)

### 8.3 CI/CD
- [ ] GitHub Actions: lint, test, build, deploy
- [ ] Автоматический деплой на staging при push в develop
- [ ] Автоматический деплой на production при merge в master

---

## Фаза 9: Тестирование

Покрытие тестами: 0%. Минимум — критические пути.

### 9.1 Backend
- [ ] Unit-тесты: сервисы (AuthService, OrderService, PromoCodeService)
- [ ] Интеграционные тесты: API-эндпоинты (auth flow, order flow)
- [ ] Тесты валидации: DTO, entities

### 9.2 Frontend
- [ ] Widget-тесты: ключевые экраны
- [ ] Integration-тесты: auth flow, order flow
- [ ] Golden-тесты (опционально): визуальная регрессия

---

## Фаза 10: Улучшения UX (после базового MVP)

- [ ] Полнотекстовый поиск (PostgreSQL FTS или Elasticsearch)
- [ ] Рекомендации "Для вас" (на основе истории заказов)
- [ ] Шеринг в соцсети
- [ ] Мультиязычность (i18n)
- [ ] Dark mode
- [ ] Onboarding-экраны для новых пользователей
- [ ] Система лояльности / бонусы

---

## Приоритеты

| Приоритет | Фазы | Обоснование |
|-----------|-------|-------------|
| Критический | 1, 2 | Без этого приложение не работает |
| Высокий | 3, 4, 5 | Ключевой функционал для Too Good To Go |
| Средний | 6, 7, 8 | Нужно для production |
| Базовый | 9, 10 | Качество и развитие |

---

## Порядок работы

```
Фаза 1 (фронт + API) → Фаза 2 (оплата) → Фаза 3 (карта) →
Фаза 8 (безопасность) → Фаза 4 (push) → Фаза 5 (фото) →
Фаза 6 (email) → Фаза 7 (админка) → Фаза 9 (тесты) → Фаза 10 (UX)
```
