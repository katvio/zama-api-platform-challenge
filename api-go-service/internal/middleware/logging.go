package middleware

import (
	"github.com/gin-gonic/gin"
	"github.com/katvio/api-go-service/pkg/logger"
	"time"
)

// RequestIDKey is the key used to store request ID in context
const RequestIDKey = "request_id"

// LoggingMiddleware creates a gin middleware for request logging
func LoggingMiddleware(log *logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()

		// Generate request ID if not present
		requestID := c.GetHeader("X-Request-ID")
		if requestID == "" {
			requestID = generateRequestID()
		}

		// Store request ID in context for other handlers
		c.Set(RequestIDKey, requestID)

		// Set response header
		c.Header("X-Request-ID", requestID)

		// Process request
		c.Next()

		// Calculate latency
		latency := time.Since(start)

		// Log the request
		log.LogHTTPRequest(
			c.Request.Method,
			c.Request.URL.Path,
			c.Request.UserAgent(),
			c.ClientIP(),
			c.Writer.Status(),
			latency,
			requestID,
		)
	}
}

// generateRequestID generates a simple request ID
// In production, you might want to use a more sophisticated approach
func generateRequestID() string {
	return time.Now().Format("20060102150405") + "-" + randomString(8)
}

// randomString generates a random string of given length
func randomString(length int) string {
	const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	b := make([]byte, length)
	for i := range b {
		b[i] = charset[time.Now().UnixNano()%int64(len(charset))]
	}
	return string(b)
}
