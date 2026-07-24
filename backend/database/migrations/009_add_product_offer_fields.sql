-- Поля для карточки-предложения "сюрприз-бокс": старая цена (для зачёркнутой
-- цены на фронте), теги состава (Халяль/Без глютена/Мучное и т.п.) и окно
-- самовывоза (обычно последние часы перед закрытием точки).
ALTER TABLE products
  ADD COLUMN IF NOT EXISTS original_price NUMERIC,
  ADD COLUMN IF NOT EXISTS tags TEXT[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS pickup_start VARCHAR(5),
  ADD COLUMN IF NOT EXISTS pickup_end VARCHAR(5);
