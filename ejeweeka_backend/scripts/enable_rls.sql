-- scripts/enable_rls.sql
-- Этот скрипт включает Row-Level Security (RLS) на всех таблицах схемы public.
-- Запуск этого скрипта защитит вашу БД Supabase от внешнего несанкционированного доступа (через anon key).
-- Важно: бэкенд FastAPI использует подключение через SQLAlchemy с ролью postgres,
-- которая автоматически обходит RLS, поэтому создание дополнительных политик (Policies) не требуется,
-- если клиенты Flutter не обращаются к Supabase напрямую через REST API.

DO $$ 
DECLARE 
  t record;
BEGIN 
  FOR t IN 
    SELECT tablename FROM pg_tables WHERE schemaname = 'public' 
  LOOP 
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', t.tablename); 
  END LOOP; 
END $$;

-- Чтобы проверить, что RLS включен:
-- SELECT relname, relrowsecurity FROM pg_class WHERE relnamespace = 'public'::regnamespace AND relkind = 'r';
