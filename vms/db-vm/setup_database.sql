-- PostgreSQL Database Setup for Actix vs Fiber Benchmark
-- Creates database, tables for light and heavy read/write operations

-- Connect to default postgres database first
\c postgres

-- Drop and recreate database (for clean setup)
DROP DATABASE IF EXISTS benchmark_database;
CREATE DATABASE benchmark_database;

-- Connect to the new database
\c benchmark_database

-- ============================================================================
-- LIGHT TABLE - For simple read/write operations
-- ============================================================================
-- Small records with minimal columns
-- Used for: /read_mem, /write_mem, /read_db, /write_db
CREATE TABLE light_data (
    id BIGSERIAL PRIMARY KEY,
    key VARCHAR(100) NOT NULL,
    value VARCHAR(1000) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for fast lookups by key
CREATE INDEX idx_light_data_key ON light_data(key);
CREATE INDEX idx_light_data_created_at ON light_data(created_at);

-- ============================================================================
-- HEAVY TABLE - For complex read/write operations with large JSON
-- ============================================================================
-- Large records with JSON data
-- Used for: /read_heavy, /write_heavy
CREATE TABLE heavy_data (
    id BIGSERIAL PRIMARY KEY,
    payload JSONB NOT NULL,
    metadata JSONB,
    nested_array JSONB,
    tags TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for JSONB queries
CREATE INDEX idx_heavy_data_payload ON heavy_data USING GIN (payload);
CREATE INDEX idx_heavy_data_metadata ON heavy_data USING GIN (metadata);
CREATE INDEX idx_heavy_data_tags ON heavy_data USING GIN (tags);
CREATE INDEX idx_heavy_data_created_at ON heavy_data(created_at);

-- ============================================================================
-- SEED DATA - Insert some initial records for read operations
-- ============================================================================

-- Seed light_data with 1000 records
INSERT INTO light_data (key, value)
SELECT 
    'key_' || generate_series,
    'value_' || md5(random()::text)
FROM generate_series(1, 1000);

-- Seed heavy_data with 100 records (large JSON payloads)
INSERT INTO heavy_data (payload, metadata, nested_array, tags)
SELECT 
    jsonb_build_object(
        'id', generate_series,
        'name', 'Record ' || generate_series,
        'description', md5(random()::text),
        'data', jsonb_build_object(
            'field1', random() * 1000,
            'field2', md5(random()::text),
            'field3', array_agg(i)
        ),
        'nested', jsonb_build_object(
            'level1', jsonb_build_object(
                'level2', jsonb_build_object(
                    'level3', array_agg(jsonb_build_object('item', i, 'value', random()))
                )
            )
        )
    ),
    jsonb_build_object(
        'timestamp', CURRENT_TIMESTAMP,
        'version', 1,
        'source', 'seed_data'
    ),
    jsonb_build_array(
        jsonb_build_object('index', 0, 'data', array_agg(i)),
        jsonb_build_object('index', 1, 'data', array_agg(i * 2)),
        jsonb_build_object('index', 2, 'data', array_agg(i * 3))
    ),
    ARRAY['tag1', 'tag2', 'benchmark', 'seed_' || generate_series]
FROM generate_series(1, 100), generate_series(1, 10) AS i
GROUP BY generate_series;

-- ============================================================================
-- FUNCTIONS - Auto-update updated_at timestamp
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for auto-updating timestamps
CREATE TRIGGER update_light_data_updated_at
    BEFORE UPDATE ON light_data
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_heavy_data_updated_at
    BEFORE UPDATE ON heavy_data
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VACUUM AND ANALYZE - Optimize tables
-- ============================================================================

VACUUM ANALYZE light_data;
VACUUM ANALYZE heavy_data;

-- ============================================================================
-- SUMMARY
-- ============================================================================

SELECT 'Database setup complete!' AS status;
SELECT 'light_data records: ' || COUNT(*) FROM light_data;
SELECT 'heavy_data records: ' || COUNT(*) FROM heavy_data;