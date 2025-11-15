package main

import (
	"log"

	"github.com/golang-migrate/migrate/v4"

	"github.com/iambasill/streamfleet/src/configs"

)

func main() {

	dbEnv, err := configs.DatabaseConfig(".")
	if err != nil {
		log.Fatal("Cannot connect to database:", err)
	}
	runMigration(dbEnv.DbSource, "file://src/database/migrations/")
	RunHttpServer()

}

func runMigration(dbSource string, migrationsDir string) {
	m, err := migrate.New(
		migrationsDir,
		dbSource,
	)
	if err != nil {
		log.Fatalf("Failed to start migration: %v", err)
	}
	if err := m.Up(); err != nil && err != migrate.ErrNoChange {
		log.Fatalf("Migration failed: %v", err)
	}
	log.Println(" Database migration completed successfully")
}
