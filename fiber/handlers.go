package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"time"
	"github.com/lib/pq"

	"github.com/gofiber/fiber/v2"
)

func ctxWithTimeout() (context.Context, context.CancelFunc) {
	return context.WithTimeout(context.Background(), 2*time.Second)
}

func handleHello(c *fiber.Ctx) error {
	return c.SendString("hello world")
}

func handleParseLightJson(c *fiber.Ctx) error {
	var payload lightData
	if err := c.BodyParser(&payload); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid light json")
	}
	return c.JSON(fiber.Map{"parsed": true})
}

func handleParseHeavyJson(c *fiber.Ctx) error {
	var payload heavyPayload
	if err := json.Unmarshal(c.Body(), &payload); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid heavy json")
	}
	return c.JSON(fiber.Map{"parsed": true})
}

func handleReadLightFromDB(c *fiber.Ctx) error {
	key := c.Query("key", "key_1")

	ctx, cancel := ctxWithTimeout()
	defer cancel()

	const q = `SELECT id, key, value, created_at, updated_at FROM light_data WHERE key = $1 LIMIT 1`
	var rec lightRecord
	if err := db.QueryRowContext(ctx, q, key).Scan(&rec.ID, &rec.Key, &rec.Value, &rec.CreatedAt, &rec.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return fiber.NewError(fiber.StatusNotFound, "light record not found")
		}
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}

	return c.JSON(rec)
}

func handleWriteLightToDB(c *fiber.Ctx) error {
	var payload lightData
	if err := c.BodyParser(&payload); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid light json")
	}

	ctx, cancel := ctxWithTimeout()
	defer cancel()

	const q = `INSERT INTO light_data (key, value) VALUES ($1, $2) RETURNING id, created_at, updated_at`
	var rec lightRecord
	rec.Key = payload.Key
	rec.Value = payload.Value

	if err := db.QueryRowContext(ctx, q, payload.Key, payload.Value).Scan(&rec.ID, &rec.CreatedAt, &rec.UpdatedAt); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}

	return c.JSON(rec)
}

func handleReadHeavyFromDB(c *fiber.Ctx) error {
	id := c.QueryInt("id", 1)

	ctx, cancel := ctxWithTimeout()
	defer cancel()

	const q = `SELECT id, payload, metadata, nested_array, tags, created_at, updated_at FROM heavy_data WHERE id = $1`
	var rec heavyRecord
	if err := db.QueryRowContext(ctx, q, id).Scan(&rec.ID, &rec.Payload, &rec.Metadata, &rec.Nested, pq.Array(&rec.Tags), &rec.CreatedAt, &rec.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return fiber.NewError(fiber.StatusNotFound, "heavy record not found")
		}
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}

	return c.JSON(rec)
}

func handleWriteHeavyToDB(c *fiber.Ctx) error {
	var payload heavyPayload
	if err := json.Unmarshal(c.Body(), &payload); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid heavy json")
	}

	ctx, cancel := ctxWithTimeout()
	defer cancel()

	const q = `INSERT INTO heavy_data (payload, metadata, nested_array, tags) VALUES ($1, $2, $3, $4) RETURNING id, created_at, updated_at`
	var rec heavyRecord
	rec.Payload = payload.Payload
	rec.Metadata = payload.Metadata
	rec.Nested = payload.NestedArray
	rec.Tags = payload.Tags

	if err := db.QueryRowContext(ctx, q, payload.Payload, payload.Metadata, payload.NestedArray, pq.Array(payload.Tags)).Scan(&rec.ID, &rec.CreatedAt, &rec.UpdatedAt); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}

	return c.JSON(rec)
}
