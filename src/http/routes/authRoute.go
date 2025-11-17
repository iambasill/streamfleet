package http

import (
	"github.com/gin-gonic/gin"

	controller "github.com/iambasill/streamfleet/src/http/controllers"
)

func authRoute(router *gin.RouterGroup, server *controller.Server) {
	authRoutes := router.Group("/auth")
	{
		authRoutes.POST("/login")
		authRoutes.POST("/register", server.Register)
		authRoutes.POST("/logout")
		authRoutes.POST("/refresh")
		authRoutes.GET("/me")
	}
}
