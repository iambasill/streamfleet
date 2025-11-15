package grpc

import (
	database "github.com/iambasill/streamfleet/src/database/sqlc"
	pb "github.com/iambasill/streamfleet/src/grpc/services"
)

type Server struct {
	pb.UnimplementedOrderServiceServer
	dbq *database.DBQuery
}

func NewServer(dbq *database.DBQuery) *Server {
	return &Server{
		dbq: dbq,
	}
}
