-- 饮食管家：数据库结构（PostgreSQL）
-- 在云服务后台的 SQL 控制台里执行一次即可。
--
-- 设计说明：这是一个「家庭自用、免登录」的应用，所有数据行用同一个
-- owner_id 归集（默认 'demo-family'，与 index.html 里的 FAMILY_ID 对应）。
-- 因此下面的策略允许匿名读写；如果要做多用户版本，请改成
-- auth.uid() 相关的策略，勿直接照搬。

-- 1. 健康档案（姓名、年龄、饮食阶段、过敏等，存成 JSONB 便于扩展）
CREATE TABLE IF NOT EXISTS health_profiles (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  owner_id   TEXT NOT NULL DEFAULT 'demo-family',
  content    JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. 每日菜谱（按日期缓存，AI 生成的 JSON）
CREATE TABLE IF NOT EXISTS meal_plans (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  owner_id   TEXT NOT NULL DEFAULT 'demo-family',
  plan_date  TEXT NOT NULL,
  content    JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. 症状记录（问过 AI 的内容 + 判断结果 + 分级，复诊时可给医生看）
CREATE TABLE IF NOT EXISTS symptom_logs (
  id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  owner_id     TEXT NOT NULL DEFAULT 'demo-family',
  symptom_text TEXT NOT NULL,
  advice_text  TEXT,
  severity     TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. 体重记录
CREATE TABLE IF NOT EXISTS weight_logs (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  owner_id   TEXT NOT NULL DEFAULT 'demo-family',
  weight_kg  NUMERIC(5,1) NOT NULL,
  weigh_date TEXT NOT NULL,
  note       TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 行级安全：四张表都开启，策略统一按 owner_id 归集
ALTER TABLE health_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_plans      ENABLE ROW LEVEL SECURITY;
ALTER TABLE symptom_logs    ENABLE ROW LEVEL SECURITY;
ALTER TABLE weight_logs     ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE health_profiles TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE meal_plans      TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE symptom_logs    TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE weight_logs     TO authenticated, anon;

CREATE POLICY health_profiles_family ON health_profiles FOR ALL TO authenticated, anon
  USING (owner_id = 'demo-family') WITH CHECK (owner_id = 'demo-family');
CREATE POLICY meal_plans_family ON meal_plans FOR ALL TO authenticated, anon
  USING (owner_id = 'demo-family') WITH CHECK (owner_id = 'demo-family');
CREATE POLICY symptom_logs_family ON symptom_logs FOR ALL TO authenticated, anon
  USING (owner_id = 'demo-family') WITH CHECK (owner_id = 'demo-family');
CREATE POLICY weight_logs_family ON weight_logs FOR ALL TO authenticated, anon
  USING (owner_id = 'demo-family') WITH CHECK (owner_id = 'demo-family');
