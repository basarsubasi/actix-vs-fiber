package main

import (
	"encoding/json"
	"time"
)

type lightData struct {
	Key   string `json:"key"`
	Value string `json:"value"`
}

type lightRecord struct {
	ID        int64     `json:"id"`
	Key       string    `json:"key"`
	Value     string    `json:"value"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type heavyPayload struct {
	Payload     json.RawMessage `json:"payload"`
	Metadata    json.RawMessage `json:"metadata"`
	NestedArray json.RawMessage `json:"nested_array"`
	Tags        []string        `json:"tags"`
}

type heavyRecord struct {
	ID        int64           `json:"id"`
	Payload   json.RawMessage `json:"payload"`
	Metadata  json.RawMessage `json:"metadata"`
	Nested    json.RawMessage `json:"nested_array"`
	Tags      []string        `json:"tags"`
	CreatedAt time.Time       `json:"created_at"`
	UpdatedAt time.Time       `json:"updated_at"`
}
