package main

import (
	"log"
	"net"

	"github.com/iambasill/streamfleet/src/configs"
	pb "github.com/iambasill/streamfleet/src/pb"

	"github.com/iambasill/streamfleet/src/controllers"
	"github.com/iambasill/streamfleet/src/database"
	dbq "github.com/iambasill/streamfleet/src/database/sqlc"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"

	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

func main() {

	dbEnv, err := configs.DatabaseConfig(".")
	if err != nil {
		log.Fatal("Cannot connect to database:", err)
	}
	runMigration(dbEnv.DbSource, "file://src/database/migrations/")

	runGrpcServer()

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
	log.Println("✅ Database migration completed successfully")
}

func runGrpcServer() {
	DBenv, err := configs.DatabaseConfig(".")
	if err != nil {
		log.Fatal("Cannot access Database Variables:", err)
	}

	env, err := configs.ENVConfig(".")
	if err != nil {
		log.Fatal("Cannot access ENV Variables:", err)
	}

	conn, err := database.ConnectDB(DBenv)
	if err != nil {
		log.Fatal("Cannot connect to database:", err)
	}
	defer conn.Close()

	dbqueries := dbq.NewDBQuery(conn)
	server := controllers.NewServer(dbqueries)

	// grpcLogger := grpc.UnaryInterceptor(controllers.GrpcLogger)
	// grpcServer := grpc.NewServer(grpcLogger)
	grpcServer := grpc.NewServer()

	pb.RegisterOrderServiceServer(grpcServer, server)
	reflection.Register(grpcServer)

	listener, err := net.Listen("tcp", env.GRPC_SERVER_ADDRESS)
	if err != nil {
		log.Fatal("Cannot start gRPC server:", err)
	}

	log.Printf("🚀 Starting gRPC server on %s", env.GRPC_SERVER_ADDRESS)
	if err := grpcServer.Serve(listener); err != nil {
		log.Fatal("Failed to start gRPC server:", err)
	}
}
