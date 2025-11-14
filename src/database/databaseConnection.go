package database

import (
	"database/sql"
	"fmt"
	"streamfleet-app/src/configs"
	"time"
)

func ConnectDB(config configs.DBConfig) (*sql.DB, error) {
	db, err := sql.Open(config.DbDriver, config.DbSource)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	err = db.Ping()
	if err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	// Set connection pool settings
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(25)
	db.SetConnMaxLifetime(5 * time.Minute)
	return db, nil
}
