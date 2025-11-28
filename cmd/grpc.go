package cmd

import (
	"log"
	"net"
	"os"

	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	"github.com/iambasill/streamfleet/src/database"
	dbq "github.com/iambasill/streamfleet/src/database/sqlc"
	controllers "github.com/iambasill/streamfleet/src/grpc"
	pb "github.com/iambasill/streamfleet/src/grpc/services"
)


func RunGrpcServer() {
	conn, err := database.ConnectDB()
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
	GRPCServerAddress := os.Getenv("GRPC_SERVER_ADDRESS")
	if GRPCServerAddress == "" {
		GRPCServerAddress = "9000"
	}

	listener, err := net.Listen("tcp", GRPCServerAddress)
	if err != nil {
		log.Fatal("Cannot start gRPC server:", err)
	}

	log.Printf(" Starting gRPC server on %s", GRPCServerAddress)
	if err := grpcServer.Serve(listener); err != nil {
		log.Fatal("Failed to start gRPC server:", err)
	}
}
