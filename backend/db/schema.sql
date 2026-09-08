-- SIH26231 — Digital Companion for Field Drug Testing
-- PostgreSQL schema for the server-side case/evidence/audit store.
-- ML output is a presumptive field-test interpretation, not definitive laboratory confirmation.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE case_status AS ENUM (
    'draft',
    'analyzed',
    'queued',
    'synced',
    'reviewed',
    'closed'
);

CREATE TYPE classification_result AS ENUM (
    'positive',
    'negative',
    'inconclusive'
);

CREATE TYPE sync_status AS ENUM (
    'pending',
    'synced',
    'failed'
);

CREATE TABLE operators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    operator_code VARCHAR(100) NOT NULL UNIQUE,
    display_name VARCHAR(200),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE cases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_case_id VARCHAR(100) NOT NULL UNIQUE,
    operator_id UUID NOT NULL REFERENCES operators(id),
    status case_status NOT NULL DEFAULT 'draft',
    captured_at TIMESTAMPTZ NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    location_accuracy_m DOUBLE PRECISION,
    kit_type VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT cases_latitude_range CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
    CONSTRAINT cases_longitude_range CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180),
    CONSTRAINT cases_accuracy_nonnegative CHECK (location_accuracy_m IS NULL OR location_accuracy_m >= 0)
);

CREATE TABLE test_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL UNIQUE REFERENCES cases(id) ON DELETE CASCADE,
    classification classification_result NOT NULL,
    confidence DOUBLE PRECISION NOT NULL,
    model_version VARCHAR(100) NOT NULL,
    calibration_method VARCHAR(100),
    image_quality_score DOUBLE PRECISION,
    reference_card_detected BOOLEAN,
    strip_roi_detected BOOLEAN,
    preprocessing_metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
    analyzed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT test_results_confidence_range CHECK (confidence BETWEEN 0 AND 1),
    CONSTRAINT test_results_quality_range CHECK (image_quality_score IS NULL OR image_quality_score BETWEEN 0 AND 1)
);

CREATE TABLE evidence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL UNIQUE REFERENCES cases(id) ON DELETE CASCADE,
    image_sha256 CHAR(64) NOT NULL,
    canonical_payload_sha256 CHAR(64) NOT NULL,
    image_storage_key TEXT,
    canonical_payload JSONB NOT NULL,
    captured_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT evidence_image_sha256_hex CHECK (image_sha256 ~ '^[0-9a-fA-F]{64}$'),
    CONSTRAINT evidence_payload_sha256_hex CHECK (canonical_payload_sha256 ~ '^[0-9a-fA-F]{64}$')
);

CREATE TABLE sync_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
    client_case_id VARCHAR(100) NOT NULL,
    status sync_status NOT NULL DEFAULT 'pending',
    attempt_count INTEGER NOT NULL DEFAULT 0,
    last_error TEXT,
    queued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    synced_at TIMESTAMPTZ,
    CONSTRAINT sync_queue_attempt_nonnegative CHECK (attempt_count >= 0)
);

CREATE TABLE audit_log (
    id BIGSERIAL PRIMARY KEY,
    case_id UUID REFERENCES cases(id) ON DELETE SET NULL,
    operator_id UUID REFERENCES operators(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    event_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    details JSONB NOT NULL DEFAULT '{}'::JSONB
);

CREATE INDEX idx_cases_operator_id ON cases(operator_id);
CREATE INDEX idx_cases_status ON cases(status);
CREATE INDEX idx_cases_captured_at ON cases(captured_at DESC);
CREATE INDEX idx_test_results_classification ON test_results(classification);
CREATE INDEX idx_evidence_image_sha256 ON evidence(image_sha256);
CREATE INDEX idx_sync_queue_status ON sync_queue(status);
CREATE INDEX idx_audit_log_case_id_event_at ON audit_log(case_id, event_at DESC);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER operators_set_updated_at
BEFORE UPDATE ON operators
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER cases_set_updated_at
BEFORE UPDATE ON cases
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Optional seed operator for local development only.
-- INSERT INTO operators (operator_code, display_name)
-- VALUES ('DEMO-001', 'Demo Operator')
-- ON CONFLICT (operator_code) DO NOTHING;
