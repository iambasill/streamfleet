package http

import (
	database "github.com/iambasill/streamfleet/src/database/sqlc"
)

type Server struct {
	dbq *database.DBQuery
}

func NewServer(dbq *database.DBQuery) *Server {
	return &Server{
		dbq: dbq,
	}
}
