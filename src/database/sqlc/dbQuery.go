package database

import "database/sql"

type DBQuery struct {
	*Queries
}

func NewDBQuery(db *sql.DB) *DBQuery {
	return &DBQuery{
		Queries: New(db),
	}
}
