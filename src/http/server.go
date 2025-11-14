package controllers

import (
	database "streamfleet-app/src/database/sqlc"
	pb "streamfleet-app/src/pb"
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
