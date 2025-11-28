package http

import (
	"os"

	"github.com/gin-gonic/gin"

	controller "github.com/iambasill/streamfleet/src/http/controllers"
	middleware "github.com/iambasill/streamfleet/src/http/middlewares"
)


func authRoute(router *gin.RouterGroup, server *controller.Server) {
	appKey := os.Getenv("APP_KEY")
	if appKey == "" {
		panic("APP KEY UNDEFINED")
	}
	authRoutes := router.Group("/auth")
	{
		authRoutes.POST("/login", server.Login)
		authRoutes.POST("/register", server.Register)
		authRoutes.POST("/logout")
		authRoutes.POST("/refresh")
		authRoutes.GET("/me")
	}

	protectedRoutes := authRoutes.Group("")
	protectedRoutes.Use(middleware.AuthMiddleware(appKey))
	{
		// protectedRoutes.GET("/auth/me", server.GetCurrentUser)
		// protectedRoutes.POST("/auth/logout", server.Logout)
		protectedRoutes.GET("/profile", server.GetProfile)
	}
}
