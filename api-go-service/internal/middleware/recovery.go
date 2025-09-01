package middleware

import (
	"fmt"
	"net/http"
	"runtime"

	"github.com/gin-gonic/gin"
	"github.com/katvio/api-go-service/internal/models"
	"github.com/katvio/api-go-service/pkg/logger"
)

// RecoveryMiddleware creates a gin middleware for panic recovery
func RecoveryMiddleware(log *logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				// Get request ID from context
				requestID, _ := c.Get(RequestIDKey)
				reqID, _ := requestID.(string)

				// Get stack trace
				stack := make([]byte, 4096)
				length := runtime.Stack(stack, false)
				stackTrace := string(stack[:length])

				// Log the panic with stack trace
				log.LogError(
					fmt.Errorf("panic recovered: %v", err),
					"recovery_middleware",
					"panic_recovery",
					map[string]interface{}{
						"stack_trace": stackTrace,
						"request_id":  reqID,
						"method":      c.Request.Method,
						"path":        c.Request.URL.Path,
						"client_ip":   c.ClientIP(),
						"user_agent":  c.Request.UserAgent(),
					},
				)

				// Return error response
				errorResponse := models.NewErrorResponse(
					fmt.Errorf("internal server error"),
					"INTERNAL_SERVER_ERROR",
					c.Request.URL.Path,
					reqID,
				)

				c.JSON(http.StatusInternalServerError, errorResponse)
				c.Abort()
			}
		}()

		c.Next()
	}
}
