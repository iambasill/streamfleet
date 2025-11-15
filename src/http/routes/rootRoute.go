package routes

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	controllers "github.com/iambasill/streamfleet/src/http"

)

func RootRouter(router *gin.Engine, controllers *controllers.Server) *gin.Engine {
	// Set Gin mode based on environment
	// if env.Environment == "production" {
	// 	gin.SetMode(gin.ReleaseMode)
	// }

	// API routes group
	apiRoutes := router.Group("/api")
	authRoute(apiRoutes, controllers)

	// Health check endpoint
	router.GET("/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message":   "pong",
			"timestamp": time.Now().Unix(),
			"status":    "healthy",
		})
	})

	// 404 handler
	router.NoRoute(func(c *gin.Context) {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "Endpoint not found",
			"message": "The requested endpoint does not exist",
		})
	})
	
	return router
}
