package routes

import (
	"github.com/gin-gonic/gin"

	controllers "github.com/iambasill/streamfleet/src/http"
)

func authRoute(router *gin.RouterGroup, server *controllers.Server) {
	authRoutes := router.Group("/auth")
	{
		authRoutes.POST("/login")
		authRoutes.POST("/register")
		authRoutes.POST("/logout")
		authRoutes.POST("/refresh")
	}
}
