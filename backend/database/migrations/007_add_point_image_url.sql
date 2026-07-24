-- Реальное фото заведения (точки). Раньше фото было только у товаров;
-- теперь у points тоже есть поле под фотографию самого заведения.
ALTER TABLE points ADD COLUMN IF NOT EXISTS image_url VARCHAR(255);
