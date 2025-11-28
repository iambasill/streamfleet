package cmd

import (
	"log"
	"os"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"github.com/iambasill/streamfleet/src/database"
	dbq "github.com/iambasill/streamfleet/src/database/sqlc"
	controller "github.com/iambasill/streamfleet/src/http/controllers"
	routes "github.com/iambasill/streamfleet/src/http/routes"
)

func RunHttpServer() {

	conn, err := database.ConnectDB()
	if err != nil {
		log.Fatal("Cannot connect to database:", err)
	}
	defer conn.Close()

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

	HTTPServerAddress := os.Getenv("HTTP_SERVER_PORT")
	if HTTPServerAddress == "" {
		HTTPServerAddress = ":50051"
	}


	log.Printf("Starting HTTP server on port %s...", HTTPServerAddress)
	if err := server.Run(":" + HTTPServerAddress); err != nil {
		log.Fatalf("Failed to run HTTP server: %v", err)
	}

}
