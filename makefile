# Load environment variables from .env file
include .env
export

# Database connection string - using the individual components from .env
DB_URL = postgres://$(DB_USERNAME):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_DATABASE)?sslmode=disable
DB_URL_NO_DB = postgres://$(DB_USERNAME):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/postgres?sslmode=disable

# Migration commands

migrate-clean:
	migrate -path src/database/migrations -database "$(DB_URL)" force 2

migrateup:
	migrate -path src/database/migrations -database "$(DB_URL)" up 

migratedown:
	migrate -path src/database/migrations -database "$(DB_URL)" down

migratedown-all:
	migrate -path src/database/migrations -database "$(DB_URL)" down -all

migrate-to-version:
	migrate -path src/database/migrations -database "$(DB_URL)" goto $(v)

migrate-force:
	migrate -path src/database/migrations -database "$(DB_URL)" force $(v)

migrate-version:
	migrate -path src/database/migrations -database "$(DB_URL)" version

migrate-create:
	migrate create -ext sql -dir src/database/migrations -seq $(name)

# Nuclear option - use sudo to bypass authentication (development only)
db-reset:
	@echo "Resetting database using sudo..."
	sudo -u postgres dropdb --if-exists $(DB_DATABASE)
	sudo -u postgres createdb -O $(DB_USERNAME) $(DB_DATABASE)
	@echo "Database reset complete. Run 'make migrateup' to apply migrations."

# Database connection test
db-connect:
	psql "$(DB_URL)"

# Quick test command
db-test:
	@echo "Testing database connection..."
	psql "$(DB_URL)" -c "SELECT version();"



# Create database only (if it doesn't exist)
db-create:
	psql "$(DB_URL_NO_DB)" -c "CREATE DATABASE $(DB_DATABASE);"

# Drop database only
db-drop:
	psql "$(DB_URL_NO_DB)" -c "DROP DATABASE IF EXISTS $(DB_DATABASE);"

proto:
	rm -rf src/grpc/services/*.go 
	rm -rf src/docs/swagger/*.swagger.json
	protoc --proto_path=pkg/proto \
	--go_out=src/grpc/services --go-grpc_out=src/grpc/services \
	--go_opt=paths=source_relative --go-grpc_opt=paths=source_relative \
	--grpc-gateway_out=src/grpc/services --grpc-gateway_opt=paths=source_relative \
	pkg/proto/*.proto

server:
	go run cmd/main.go

web:
	grpcui -plaintext $(GRPC_SERVER_ADDRESS)

.PHONY: migrate-clean server web migrateup migratedown migratedown-all migrate-to-version migrate-force migrate-version migrate-create db-reset db-reset-alt db-reset-sudo db-connect db-test show-env db-create db-drop proto