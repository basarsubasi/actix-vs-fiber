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

// ============================================================================
// Strongly-typed heavy payload structures for optimized parsing
// ============================================================================

/// User preferences
#[derive(Debug, Deserialize, Serialize)]
pub struct UserPrefs {
    pub lang: String,
    pub tz: String,
    pub flags: Vec<bool>,
}

/// User information within the payload
#[derive(Debug, Deserialize, Serialize)]
pub struct User {
    pub id: i64,
    pub name: String,
    pub prefs: UserPrefs,
}

/// Item in the shopping cart/order
#[derive(Debug, Deserialize, Serialize)]
pub struct Item {
    pub sku: String,
    pub qty: i32,
    pub price: f64,
}

/// Main payload section
#[derive(Debug, Deserialize, Serialize)]
pub struct Payload {
    pub user: User,
    pub items: Vec<Item>,
}

/// Headers in metadata
#[derive(Debug, Deserialize, Serialize)]
pub struct MetadataHeaders {
    pub ua: String,
    pub accept: Vec<String>,
}

/// Metadata section
#[derive(Debug, Deserialize, Serialize)]
pub struct Metadata {
    pub trace: String,
    pub ts: i64,
    pub headers: MetadataHeaders,
}

/// Bar nested within NestedData
#[derive(Debug, Deserialize, Serialize)]
pub struct BarData {
    pub k1: String,
    pub k2: String,
}

/// X object in nested array
#[derive(Debug, Deserialize, Serialize)]
pub struct XObj {
    pub x: i32,
}

/// Data within first nested array element
#[derive(Debug, Deserialize, Serialize)]
pub struct NestedDataLevel1 {
    pub foo: Vec<i32>,
    pub bar: BarData,
}

/// Data within second nested array element  
#[derive(Debug, Deserialize, Serialize)]
pub struct NestedDataLevel2 {
    pub numbers: Vec<i32>,
    pub obj: Vec<XObj>,
}

/// Generic nested element (using enum for different levels)
#[derive(Debug, Deserialize, Serialize)]
#[serde(untagged)]
pub enum NestedElement {
    Level1 { level: i32, data: NestedDataLevel1 },
    Level2 { level: i32, data: NestedDataLevel2 },
}

/// Request payload for heavy JSON operations - strongly typed
#[derive(Debug, Deserialize, Serialize)]
pub struct HeavyPayload {
    pub payload: Payload,
    pub metadata: Metadata,
    pub nested_array: Vec<NestedElement>,
    pub tags: Vec<String>,
}

/// Full DB record for heavy_data table
/// Note: DB stores as JSONB, so we use serde_json::Value for storage
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
