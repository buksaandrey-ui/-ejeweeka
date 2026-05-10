-- Zero-Knowledge Architecture
-- Медицинские данные пользователей хранятся ТОЛЬКО на устройстве.
-- Сервер работает в Stateless-режиме: входящие медицинские JSON
-- уничтожаются сразу после генерации плана.
-- Подписки управляются через RevenueCat.

-- Расширения
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";

-- ============================================
-- АНОНИМНЫЕ ПОЛЬЗОВАТЕЛИ И ПОДПИСКИ
-- ============================================

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  anonymous_uuid UUID UNIQUE NOT NULL,  -- генерируется на устройстве
  subscription_status VARCHAR(20) DEFAULT 'free',
    -- значения: free | trial | black | gold | group_gold
  subscription_expires_at TIMESTAMPTZ,
  revenuecat_user_id VARCHAR(255),  -- для связи с RevenueCat
  plan_generation_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_seen_at TIMESTAMPTZ DEFAULT NOW()
  -- ВАЖНО: нет полей name, email, phone, health_data
);

CREATE TABLE group_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID UNIQUE NOT NULL,
  leader_anonymous_uuid UUID REFERENCES users(anonymous_uuid),
  encrypted_group_name BYTEA,  -- зашифровано, сервер не читает
  max_members INTEGER DEFAULT 4,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES group_subscriptions(group_id),
  member_anonymous_uuid UUID REFERENCES users(anonymous_uuid),
  encrypted_blob BYTEA,  -- зашифрованные данные участника
  blob_updated_at TIMESTAMPTZ DEFAULT NOW(),
  joined_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- АНАЛИТИКА AI (Без ПД)
-- ============================================

CREATE TABLE plan_generation_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  anonymous_uuid UUID REFERENCES users(anonymous_uuid),
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  climate_zone VARCHAR(20),  -- можно хранить, не идентифицирует
  plan_hash VARCHAR(64)  -- SHA-256 от плана, для дедупликации
  -- ВАЖНО: входной JSON медицинских данных НЕ хранится
);

CREATE TABLE push_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  anonymous_uuid VARCHAR(255) NOT NULL,
  device_token VARCHAR(500) NOT NULL,
  platform VARCHAR(10) DEFAULT 'ios',
  pref_meals BOOLEAN DEFAULT true,
  pref_water BOOLEAN DEFAULT true,
  pref_vitamins BOOLEAN DEFAULT true,
  pref_medications BOOLEAN DEFAULT true,
  pref_workouts BOOLEAN DEFAULT true,
  pref_weekly_report BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_push_devices_uuid ON push_devices(anonymous_uuid);

-- ============================================
-- СПРАВОЧНИКИ ПРОДУКТОВ И РЕЦЕПТОВ (Публичные)
-- ============================================

CREATE TABLE ingredients (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(255) NOT NULL,
    category        VARCHAR(100),
    calories_100g   NUMERIC(7,2),
    protein_100g    NUMERIC(7,2),
    fat_100g        NUMERIC(7,2),
    carbs_100g      NUMERIC(7,2),
    price_rub       NUMERIC(10,2),
    allergens       TEXT[],
    is_available    BOOLEAN DEFAULT true,
    created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE dishes (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name             VARCHAR(255) NOT NULL,
    description      TEXT,
    cuisine          VARCHAR(100),
    meal_types       TEXT[],
    calories         NUMERIC(7,1),
    protein          NUMERIC(7,1),
    fat              NUMERIC(7,1),
    carbs            NUMERIC(7,1),
    cooking_time_min SMALLINT,
    dietary_tags     TEXT[],
    allergens        TEXT[],
    recipe_steps     JSONB,
    created_at       TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE dish_ingredients (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dish_id       UUID NOT NULL REFERENCES dishes(id) ON DELETE CASCADE,
    ingredient_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    amount_grams  NUMERIC(7,1)
);

CREATE TABLE supplement_interactions (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_a_name      VARCHAR(255) NOT NULL,
    item_b_name      VARCHAR(255) NOT NULL,
    interaction_type VARCHAR(50) NOT NULL,
    severity         VARCHAR(20),
    description      TEXT,
    created_at       TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- БАЗА ЗНАНИЙ И ВРАЧИ (RAG)
-- ============================================

CREATE TABLE doctors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    specialization VARCHAR(100) NOT NULL,
    channel_url VARCHAR(500),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE doctor_materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    title VARCHAR(500) NOT NULL,
    source_url VARCHAR(500),
    source_type VARCHAR(50) DEFAULT 'video',
    transcription_status VARCHAR(30) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE transcriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    material_id UUID NOT NULL REFERENCES doctor_materials(id) ON DELETE CASCADE,
    full_text TEXT NOT NULL,
    summary TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE knowledge_chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transcription_id UUID NOT NULL REFERENCES transcriptions(id) ON DELETE CASCADE,
    doctor_id UUID NOT NULL REFERENCES doctors(id),
    chunk_index INTEGER NOT NULL,
    chunk_text TEXT NOT NULL,
    tags TEXT[],
    embedding vector(768),
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_chunks_embedding ON knowledge_chunks USING ivfflat(embedding vector_cosine_ops) WITH (lists = 100);

-- ============================================
-- ТРИГГЕРЫ (updated_at)
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated
    BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_group_members_updated
    BEFORE UPDATE ON group_members FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ----------------------------------------------------
-- КЭШИРОВАНИЕ ДЛЯ ИИ (Optimization Layer)
-- ----------------------------------------------------

CREATE TABLE recipe_image_cache (
    id SERIAL PRIMARY KEY,
    ingredients_hash VARCHAR(64) UNIQUE NOT NULL,
    recipe_title VARCHAR(255) NOT NULL,
    image_url VARCHAR(500) NOT NULL
);
CREATE INDEX idx_recipe_image_hash ON recipe_image_cache(ingredients_hash);

CREATE TABLE grocery_prices (
    id SERIAL PRIMARY KEY,
    country VARCHAR(50) NOT NULL,
    city VARCHAR(50) NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    base_price FLOAT NOT NULL,
    premium_price FLOAT NOT NULL,
    currency VARCHAR(10) NOT NULL,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_grocery_search ON grocery_prices(country, city, product_name);
