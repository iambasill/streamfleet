package cmd

import (
	"log"
	"net"

	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	"github.com/iambasill/streamfleet/src/configs"
	"github.com/iambasill/streamfleet/src/database"
	dbq "github.com/iambasill/streamfleet/src/database/sqlc"
	controllers "github.com/iambasill/streamfleet/src/grpc"
	pb "github.com/iambasill/streamfleet/src/grpc/services"
)

func RunGrpcServer() {
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
