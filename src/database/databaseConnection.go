package database

import (
	"database/sql"
	"fmt"
	"os"
	"time"

	_ "github.com/lib/pq" // PostgreSQL driver
)

func ConnectDB() (*sql.DB, error) {
	// Get individual database config from environment
	driver := getEnv("DB_DRIVER", "postgres")
	username := os.Getenv("DB_USERNAME")
	password := os.Getenv("DB_PASSWORD")
	host := getEnv("DB_HOST", "localhost")
	port := getEnv("DB_PORT", "5432")
	database := os.Getenv("DB_DATABASE")

	// Validate required fields
	if username == "" {
		return nil, fmt.Errorf("DB_USERNAME is required")
	}
	if password == "" {
		return nil, fmt.Errorf("DB_PASSWORD is required")
	}
	if database == "" {
		return nil, fmt.Errorf("DB_DATABASE is required")
	}

	// Build connection string
	dsn := fmt.Sprintf("%s://%s:%s@%s:%s/%s?sslmode=disable",
		driver, username, password, host, port, database)

	// Open database connection
	db, err := sql.Open(driver, dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Test connection
	if err := db.Ping(); err != nil {
		db.Close()
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	// Set connection pool settings
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(25)
	db.SetConnMaxLifetime(5 * time.Minute)

	return db, nil
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}