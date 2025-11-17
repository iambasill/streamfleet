package cmd

import (
	"log"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"github.com/iambasill/streamfleet/src/configs"
	"github.com/iambasill/streamfleet/src/database"
	dbq "github.com/iambasill/streamfleet/src/database/sqlc"
	controller "github.com/iambasill/streamfleet/src/http/controllers"
	routes "github.com/iambasill/streamfleet/src/http/routes"
)

func RunHttpServer() {
	// Load configurations
	DBenv, err := configs.DatabaseConfig(".")
	if err != nil {
		log.Fatal("Cannot access Database Variables:", err)
	}

	env, err := configs.ENVConfig(".")
	if err != nil {
		log.Fatal("Cannot access ENV Variables:", err)
	}

	// Database connection
	conn, err := database.ConnectDB(DBenv)
	if err != nil {
		log.Fatal("Cannot connect to database:", err)
	}
	defer func() {
		if err := conn.Close(); err != nil {
			log.Printf("Error closing database connection: %v", err)
		}
	}()

	// Initialize dependencies
	dbqueries := dbq.NewDBQuery(conn)
	controller := controller.NewServer(dbqueries)

	corsConfig := cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
	}

	server := gin.Default()
	server.Use(cors.New(corsConfig))
	server.Use(gin.Logger())
	server.Use(gin.Recovery())

	routes.RootRouter(server, controller)

	log.Printf("Starting HTTP server on port %s...", env.HTTP_SERVER_ADDRESS)
	if err := server.Run(":" + env.HTTP_SERVER_ADDRESS); err != nil {
		log.Fatalf("Failed to run HTTP server: %v", err)
	}

}
