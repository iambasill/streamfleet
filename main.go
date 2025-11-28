package main

import (
	"log"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	cmd "github.com/iambasill/streamfleet/cmd"
	"github.com/joho/godotenv"
)





func main() {

	
    err := godotenv.Load()
    if err != nil {
        log.Fatal("Error loading .env file")
    }

	// dbEnv, err := configs.DatabaseConfig(".")
	// if err != nil {
	// 	log.Fatal("Cannot connect to database:", err)
	// }
	// runMigration(dbEnv.DbSource, "file://src/database/migrations/")
	cmd.RunHttpServer()

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

