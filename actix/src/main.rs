mod db;
mod handlers;
mod models;

use actix_web::{web, App, HttpServer};
use std::env;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Load .env file if present
    dotenvy::dotenv().ok();

    let database_url = env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgresql://postgres:postgres@localhost:5432/benchmark_database".to_string());

    let pool = db::create_pool(&database_url);

    println!("Starting server on port 3000...");

    HttpServer::new(move || {
        App::new()
            .app_data(web::Data::new(pool.clone()))
            // Hello endpoint
            .route("/hello", web::get().to(handlers::handle_hello))
            // JSON parsing only (no DB) for CPU-bound benchmarks
            .route("/parse_light", web::post().to(handlers::handle_parse_light_json))
            .route("/parse_heavy", web::post().to(handlers::handle_parse_heavy_json))
            // Light table operations
            .route("/read_light_db", web::get().to(handlers::handle_read_light_from_db))
            .route("/write_light_db", web::post().to(handlers::handle_write_light_to_db))
            // Heavy table operations
            .route("/read_heavy_db", web::get().to(handlers::handle_read_heavy_from_db))
            .route("/write_heavy_db", web::post().to(handlers::handle_write_heavy_to_db))
    })
    .backlog(8192)              // Increase pending connection queue
    .max_connection_rate(15000)  // Allow high connection rate
    .bind("0.0.0.0:3000")?
    .run()
    .await
}
