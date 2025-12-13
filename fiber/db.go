package main

import (
	"database/sql"
)

var db *sql.DB

// initDB sets up the shared database handle with sane defaults.
func initDB(connStr string) (*sql.DB, error) {
	d, err := sql.Open("postgres", connStr)
	if err != nil {
		return nil, err
	}

	d.SetMaxOpenConns(0)
	d.SetMaxIdleConns(0)
	d.SetConnMaxLifetime(-1)

	if err := d.Ping(); err != nil {
		d.Close()
		return nil, err
	}

	db = d
	return d, nil
}
