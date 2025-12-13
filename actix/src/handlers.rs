use actix_web::{web, HttpResponse, Responder};
use deadpool_postgres::Pool;
use chrono::{DateTime, Utc};

use crate::models::{HeavyPayload, HeavyRecord, LightData, LightRecord};

/// GET /hello - Returns "hello world"
pub async fn handle_hello() -> impl Responder {
    "hello world"
}

/// POST /parse_light - Parse light JSON (no DB)
pub async fn handle_parse_light_json(payload: web::Json<LightData>) -> impl Responder {
    let _ = payload.into_inner();
    HttpResponse::Ok().json(serde_json::json!({"parsed": true}))
}

/// POST /parse_heavy - Parse heavy JSON (no DB)
pub async fn handle_parse_heavy_json(payload: web::Json<HeavyPayload>) -> impl Responder {
    let _ = payload.into_inner();
    HttpResponse::Ok().json(serde_json::json!({"parsed": true}))
}

/// GET /read_light_db - Read from light_data table
pub async fn handle_read_light_from_db(
    pool: web::Data<Pool>,
    query: web::Query<ReadLightQuery>,
) -> impl Responder {
    let key = query.key.as_deref().unwrap_or("key_1");

    let client = match pool.get().await {
        Ok(c) => c,
        Err(e) => return HttpResponse::InternalServerError().body(e.to_string()),
    };

    let row = match client
        .query_opt(
            "SELECT id, key, value, created_at, updated_at FROM light_data WHERE key = $1 LIMIT 1",
            &[&key],
        )
        .await
    {
        Ok(Some(row)) => row,
        Ok(None) => return HttpResponse::NotFound().body("light record not found"),
        Err(e) => return HttpResponse::InternalServerError().body(e.to_string()),
    };

    let record = LightRecord {
        id: row.get::<_, i64>("id"),
        key: row.get::<_, String>("key"),
        value: row.get::<_, String>("value"),
        created_at: row.get::<_, DateTime<Utc>>("created_at"),
        updated_at: row.get::<_, DateTime<Utc>>("updated_at"),
    };

    HttpResponse::Ok().json(record)
}

#[derive(serde::Deserialize)]
pub struct ReadLightQuery {
    pub key: Option<String>,
}

/// POST /write_light_db - Write to light_data table
pub async fn handle_write_light_to_db(
    pool: web::Data<Pool>,
    payload: web::Json<LightData>,
) -> impl Responder {
    let data = payload.into_inner();

    let client = match pool.get().await {
        Ok(c) => c,
        Err(e) => return HttpResponse::InternalServerError().body(e.to_string()),
    };

    let row = match client
        .query_one(
            "INSERT INTO light_data (key, value) VALUES ($1, $2) RETURNING id, created_at, updated_at",
            &[&data.key, &data.value],
        )
        .await
    {
        Ok(row) => row,
        Err(e) => return HttpResponse::InternalServerError().body(e.to_string()),
    };

    let record = LightRecord {
        id: row.get::<_, i64>("id"),
        key: data.key,
        value: data.value,
        created_at: row.get::<_, DateTime<Utc>>("created_at"),
        updated_at: row.get::<_, DateTime<Utc>>("updated_at"),
    };

    HttpResponse::Ok().json(record)
}

/// GET /read_heavy_db - Read from heavy_data table
pub async fn handle_read_heavy_from_db(
    pool: web::Data<Pool>,
    query: web::Query<ReadHeavyQuery>,
) -> impl Responder {
    let id = query.id.unwrap_or(1);

    let client = match pool.get().await {
        Ok(c) => c,
        Err(e) => return HttpResponse::InternalServerError().body(e.to_string()),
    };

    let row = match client
        .query_opt(
            "SELECT id, payload, metadata, nested_array, tags, created_at, updated_at FROM heavy_data WHERE id = $1",
            &[&(id as i64)],
        )
        .await
    {
        Ok(Some(row)) => row,
        Ok(None) => return HttpResponse::NotFound().body("heavy record not found"),
        Err(e) => return HttpResponse::InternalServerError().body(e.to_string()),
    };

    let record = HeavyRecord {
        id: row.get::<_, i64>("id"),
        payload: row.get::<_, serde_json::Value>("payload"),
        metadata: row.get::<_, serde_json::Value>("metadata"),
        nested_array: row.get::<_, serde_json::Value>("nested_array"),
        tags: row.get::<_, Vec<String>>("tags"),
        created_at: row.get::<_, DateTime<Utc>>("created_at"),
        updated_at: row.get::<_, DateTime<Utc>>("updated_at"),
    };

    HttpResponse::Ok().json(record)
}

#[derive(serde::Deserialize)]
pub struct ReadHeavyQuery {
    pub id: Option<i32>,
}

/// POST /write_heavy_db - Write to heavy_data table
pub async fn handle_write_heavy_to_db(
    pool: web::Data<Pool>,
    payload: web::Json<HeavyPayload>,
) -> impl Responder {
    let data = payload.into_inner();

    // Convert typed structs to serde_json::Value for JSONB storage
    let payload_json = serde_json::to_value(&data.payload).unwrap();
    let metadata_json = serde_json::to_value(&data.metadata).unwrap();
    let nested_array_json = serde_json::to_value(&data.nested_array).unwrap();

    let client = match pool.get().await {
        Ok(c) => c,
        Err(e) => return HttpResponse::InternalServerError().body(e.to_string()),
    };

    let row = match client
        .query_one(
            "INSERT INTO heavy_data (payload, metadata, nested_array, tags) VALUES ($1, $2, $3, $4) RETURNING id, created_at, updated_at",
            &[&payload_json, &metadata_json, &nested_array_json, &data.tags],
        )
        .await
    {
        Ok(row) => row,
        Err(e) => return HttpResponse::InternalServerError().body(e.to_string()),
    };

    let record = HeavyRecord {
        id: row.get::<_, i64>("id"),
        payload: payload_json,
        metadata: metadata_json,
        nested_array: nested_array_json,
        tags: data.tags,
        created_at: row.get::<_, DateTime<Utc>>("created_at"),
        updated_at: row.get::<_, DateTime<Utc>>("updated_at"),
    };

    HttpResponse::Ok().json(record)
}
