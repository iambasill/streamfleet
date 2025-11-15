package main

import (
	"log"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"

	"github.com/iambasill/streamfleet/src/configs"
	"github.com/iambasill/streamfleet/src/database"
	dbq "github.com/iambasill/streamfleet/src/database/sqlc"
	controllers "github.com/iambasill/streamfleet/src/http"
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
	controller := controllers.NewServer(dbqueries)

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

	log.Printf("Starting HTTP server on port %s...", env.HTTP_SERVER_PORT)
	if err := server.Run(":" + env.HTTP_SERVER_PORT); err != nil {
		log.Fatalf("Failed to run HTTP server: %v", err)
	}

}

// func RunHttpServerWithShutdown() {
// 	// ... [previous setup code]

// 	httpServer := &http.Server{
// 		Addr:    ":" + env.HTTPPort,
// 		Handler: router,
// 	}

// 	// Run server in a goroutine
// 	go func() {
// 		log.Printf("Starting HTTP server on port %s...", env.HTTPPort)
// 		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
// 			log.Fatalf("Failed to run HTTP server: %v", err)
// 		}
// 	}()

// 	// Wait for interrupt signal to gracefully shutdown
// 	quit := make(chan os.Signal, 1)
// 	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
// 	<-quit
// 	log.Println("Shutting down server...")

// 	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
// 	defer cancel()

// 	if err := httpServer.Shutdown(ctx); err != nil {
// 		log.Fatal("Server forced to shutdown:", err)
// 	}

// 	log.Println("Server exited")
// }
