package http

import (
	"database/sql"
	"errors"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	database "github.com/iambasill/streamfleet/src/database/sqlc"
	middleware "github.com/iambasill/streamfleet/src/http/middlewares"
	"github.com/iambasill/streamfleet/src/utils"
	"github.com/lib/pq"
)

func (server *Server) Register(ctx *gin.Context) {
	type RegisterRequest struct{
		FirstName string `json:"firstName" binding:"required,max=100"`
		LastName  string `json:"lastName" binding:"required,max=100"`
		Email     string `json:"email" binding:"required,email,max=100"`
		Password  string `json:"password" binding:"required,min=8,max=100"`
		PhoneNumber     string `json:"phoneNumber" binding:"required,max=100"`
		Role      string `json:"role" binding:"required,oneof=admin dispatcher customer driver"`
	}
	var req RegisterRequest




	if err := ctx.ShouldBindJSON(&req); err != nil {
		errDetails := utils.FormatValidationError(err)
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request", "details": errDetails})
		return
	}


	hashedPassword, err := utils.HashPassword(req.Password)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
		return
	}

	arg := database.CreateUserParams{
		FirstName: req.FirstName,
		LastName:  req.LastName,
		Email:     req.Email,
		Password:  hashedPassword,
		Phone:     req.PhoneNumber,
		Role:      req.Role,
	}

	user, err := server.dbq.CreateUser(ctx, arg)
	if err != nil {
		var pqErr *pq.Error
        if errors.As(err, &pqErr) && pqErr.Code == "23505" {
            ctx.JSON(http.StatusConflict, gin.H{
                "error": "Email already exists",
            })
            return
        }
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user", "details": err.Error()})
		return
	}

	ctx.JSON(http.StatusCreated, gin.H{
		"message":   "User registered successfully",
		"firstName": user.FirstName,
		"lastName":  user.LastName,
		"email":     user.Email,
		"phone":     user.Phone,
		"password": user.Password,
	})
}

func (server *Server) Login (ctx *gin.Context) {
	type LoginRequest struct {
		Email string	 	`json:"email" binding:"required,email,max=100"`
		Password string 	`json:"password" binding:"required,min=3,max=100"`
	}

	var req LoginRequest
	err := ctx.ShouldBindJSON(&req)
	if err != nil {
		message := utils.FormatValidationError(err)

		ctx.JSON(http.StatusBadRequest, gin.H{
			"message":message,
		})
		return
	}

	user, err := server.dbq.GetUserByEmail(ctx, req.Email)
	if err != nil {
		if err == sql.ErrNoRows{
			ctx.JSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"message":"Invalid Credentials!",
			})
		return
		}
		
		ctx.JSON(http.StatusInternalServerError, gin.H{
		"error": err.Error(),})
		return
	}

	validPassword := utils.VerifyPassword(req.Password,user.Password)
	if !validPassword {
		ctx.JSON(http.StatusUnauthorized, gin.H{
		"success": false,
		"message":"Invalid Credentials!",
		})
		return
	}		
	
	token, err := utils.CreateToken(user.UserID,user.Email)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
		"error": err.Error(),})
		return
	}


	refreshToken, _ := utils.CreateToken(user.UserID,user.Email)

	// 
   	args := database.CreateUserSessionParams{
      UserID: user.UserID,
      SessionToken: refreshToken,
      ExpiresAt: time.Now().Add(24 * time.Hour),
   }

   // Store the session in the database
  	 _, sessionErr := server.dbq.CreateUserSession(ctx , args)
   if sessionErr != nil {
      ctx.JSON(http.StatusInternalServerError, gin.H{
		 "error": sessionErr.Error(),
	  })	
      return 
   }
   
	ctx.JSON(http.StatusOK, gin.H{
		"success": true,
		"message":"Login successful",
		"access": token,
		"refresh": refreshToken,
		})		
}

func (server *Server )GetProfile (ctx *gin.Context){
    reqPayload, err := middleware.GetAuthPayload(ctx)
    if err != nil {
        ctx.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
            "error": "Unauthoized",
			
        })
        return
    }

	user, err := server.dbq.GetUserByUserID(ctx, reqPayload.UserID)
	if err != nil {
		    ctx.AbortWithStatusJSON(http.StatusNotFound, gin.H{
            "error": "User not found",
        })
        return
	}

	type UserProfile struct {
		FirstName string `json:"firstName"`
		LastName  string `json:"lastName"`
		Email     string `json:"email"`
		Phone     string `json:"phone"`
		Role      string `json:"role"`
	}
	
	data := &UserProfile{
		FirstName: user.FirstName,
		LastName:  user.LastName,
		Email:     user.Email,
		Phone:     user.Phone,
		Role:      user.Role,
	}

	ctx.JSON(http.StatusOK, gin.H{
		"success": true,
		"profile": data,
	})

} 
