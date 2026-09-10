CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE TABLE IF NOT EXISTS operators(id TEXT PRIMARY KEY, display_name TEXT NOT NULL, active BOOLEAN NOT NULL DEFAULT TRUE, created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS cases(id UUID PRIMARY KEY, operator_id TEXT NOT NULL REFERENCES operators(id), classification TEXT NOT NULL CHECK(classification IN ('positive','negative','inconclusive')), confidence DOUBLE PRECISION NOT NULL CHECK(confidence BETWEEN 0 AND 1), latitude DOUBLE PRECISION, longitude DOUBLE PRECISION, captured_at TIMESTAMPTZ NOT NULL, model_version TEXT NOT NULL, app_version TEXT NOT NULL, sync_status TEXT NOT NULL DEFAULT 'synced', created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS evidence(case_id UUID PRIMARY KEY REFERENCES cases(id) ON DELETE CASCADE, image_sha256 TEXT NOT NULL, payload_sha256 TEXT NOT NULL, image_size BIGINT, image_mime TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS audit_log(id BIGSERIAL PRIMARY KEY, case_id UUID REFERENCES cases(id) ON DELETE CASCADE, operator_id TEXT, action TEXT NOT NULL, details JSONB NOT NULL DEFAULT '{}'::jsonb, created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE INDEX IF NOT EXISTS idx_cases_captured_at ON cases(captured_at DESC);
CREATE INDEX IF NOT EXISTS idx_cases_classification ON cases(classification);
CREATE INDEX IF NOT EXISTS idx_audit_case ON audit_log(case_id, created_at DESC);
INSERT INTO operators(id,display_name) VALUES ('demo-operator','Demo Operator') ON CONFLICT DO NOTHING;
