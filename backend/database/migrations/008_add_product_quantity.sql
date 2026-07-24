-- Остаток товара на складе. Когда он равен 0, товар нельзя купить —
-- фронтенд отображает его серым и блокирует добавление в корзину.
ALTER TABLE products ADD COLUMN IF NOT EXISTS quantity INT NOT NULL DEFAULT 20;
