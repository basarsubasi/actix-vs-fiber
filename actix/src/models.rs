use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// Request payload for light JSON operations
#[derive(Debug, Deserialize, Serialize)]
pub struct LightData {
    pub key: String,
    pub value: String,
}

/// Full DB record for light_data table
#[derive(Debug, Serialize)]
pub struct LightRecord {
    pub id: i64,
    pub key: String,
    pub value: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Request payload for heavy JSON operations
#[derive(Debug, Deserialize, Serialize)]
pub struct HeavyPayload {
    pub payload: serde_json::Value,
    pub metadata: serde_json::Value,
    pub nested_array: serde_json::Value,
    pub tags: Vec<String>,
}

/// Full DB record for heavy_data table
#[derive(Debug, Serialize)]
pub struct HeavyRecord {
    pub id: i64,
    pub payload: serde_json::Value,
    pub metadata: serde_json::Value,
    pub nested_array: serde_json::Value,
    pub tags: Vec<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
