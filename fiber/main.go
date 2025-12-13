package main

import (
	"fmt"
	"os"
	"log"

	"github.com/gofiber/fiber/v2"
	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
)

func main() {
	// Load .env file if present
	godotenv.Load()

	connStr := os.Getenv("DATABASE_URL")
	if connStr == "" {
		connStr = "postgresql://postgres:postgres@localhost:5432/benchmark_database?sslmode=disable"
	}

	if _, err := initDB(connStr); err != nil {
		fmt.Printf("failed to initialize database: %v", err)
	}

	app := fiber.New()

	app.Get("/hello", handleHello)

	// JSON parsing only (no DB) for CPU-bound benchmarks
	app.Post("/parse_light", handleParseLightJson)
	app.Post("/parse_heavy", handleParseHeavyJson)

	// Light table operations
	app.Get("/read_light_db", handleReadLightFromDB)
	app.Post("/write_light_db", handleWriteLightToDB)

	// Heavy table operations
	app.Get("/read_heavy_db", handleReadHeavyFromDB)
	app.Post("/write_heavy_db", handleWriteHeavyToDB)
	log.Fatal(app.Listen(":3001"))
}
