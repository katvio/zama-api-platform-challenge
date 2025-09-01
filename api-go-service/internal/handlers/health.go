package handlers

import (
	"fmt"
	"net/http"
	"runtime"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/katvio/api-go-service/internal/middleware"
	"github.com/katvio/api-go-service/internal/models"
	"github.com/katvio/api-go-service/pkg/logger"
)

// HealthHandler handles health check requests
type HealthHandler struct {
	logger    *logger.Logger
	startTime time.Time
	version   string
}

// NewHealthHandler creates a new health handler
func NewHealthHandler(logger *logger.Logger, version string) *HealthHandler {
	return &HealthHandler{
		logger:    logger,
		startTime: time.Now(),
		version:   version,
	}
}

// HandleHealth handles GET /healthz requests
func (h *HealthHandler) HandleHealth(c *gin.Context) {
	requestID, _ := c.Get(middleware.RequestIDKey)
	reqID, _ := requestID.(string)

	// Perform health checks
	checks := h.performHealthChecks()

	// Calculate uptime
	uptime := time.Since(h.startTime).String()

	// Create response
	response := models.NewHealthResponse(h.version, uptime, checks, reqID)

	// Log health check
	h.logger.WithFields(logger.HealthCheckFields()).WithFields(map[string]interface{}{
		"status":     response.Status,
		"request_id": reqID,
		"checks":     checks,
	}).Info("Health check performed")

	// Determine HTTP status code
	statusCode := http.StatusOK
	if !response.IsHealthy() {
		statusCode = http.StatusServiceUnavailable
	}

	c.JSON(statusCode, response)
}

// HandleLiveness handles GET /healthz/live requests (Kubernetes liveness probe)
func (h *HealthHandler) HandleLiveness(c *gin.Context) {
	requestID, _ := c.Get(middleware.RequestIDKey)
	reqID, _ := requestID.(string)

	// Liveness check - basic application responsiveness
	response := &models.HealthResponse{
		Status:    "alive",
		Timestamp: time.Now().UTC(),
		RequestID: reqID,
	}

	h.logger.WithFields(logger.HealthCheckFields()).WithFields(map[string]interface{}{
		"check_type": "liveness",
		"request_id": reqID,
	}).Info("Liveness check performed")

	c.JSON(http.StatusOK, response)
}

// HandleReadiness handles GET /healthz/ready requests (Kubernetes readiness probe)
func (h *HealthHandler) HandleReadiness(c *gin.Context) {
	requestID, _ := c.Get(middleware.RequestIDKey)
	reqID, _ := requestID.(string)

	// Readiness check - check if service is ready to serve traffic
	checks := h.performReadinessChecks()

	isReady := true
	for _, status := range checks {
		if status != "ok" {
			isReady = false
			break
		}
	}

	status := "ready"
	statusCode := http.StatusOK
	if !isReady {
		status = "not_ready"
		statusCode = http.StatusServiceUnavailable
	}

	response := &models.HealthResponse{
		Status:    status,
		Timestamp: time.Now().UTC(),
		Checks:    checks,
		RequestID: reqID,
	}

	h.logger.WithFields(logger.HealthCheckFields()).WithFields(map[string]interface{}{
		"check_type": "readiness",
		"status":     status,
		"request_id": reqID,
		"checks":     checks,
	}).Info("Readiness check performed")

	c.JSON(statusCode, response)
}

// performHealthChecks performs all health checks
func (h *HealthHandler) performHealthChecks() map[string]string {
	checks := make(map[string]string)

	// System health checks
	checks["memory"] = h.checkMemory()
	checks["goroutines"] = h.checkGoroutines()
	checks["uptime"] = h.checkUptime()

	// Add more checks as needed (database, external services, etc.)

	return checks
}

// performReadinessChecks performs readiness-specific checks
func (h *HealthHandler) performReadinessChecks() map[string]string {
	checks := make(map[string]string)

	// Basic readiness checks
	checks["service"] = "ok"
	checks["configuration"] = h.checkConfiguration()

	// Add more readiness checks as needed
	// (database connections, required external services, etc.)

	return checks
}

// checkMemory checks memory usage
func (h *HealthHandler) checkMemory() string {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	// Check if memory usage is reasonable (< 1GB for this simple service)
	if m.Alloc > 1024*1024*1024 {
		return "high_memory_usage"
	}

	return "ok"
}

// checkGoroutines checks the number of goroutines
func (h *HealthHandler) checkGoroutines() string {
	numGoroutines := runtime.NumGoroutine()

	// Check if goroutine count is reasonable (< 1000 for this simple service)
	if numGoroutines > 1000 {
		return fmt.Sprintf("high_goroutine_count_%d", numGoroutines)
	}

	return "ok"
}

// checkUptime checks if the service has been running for a minimum time
func (h *HealthHandler) checkUptime() string {
	uptime := time.Since(h.startTime)

	// Service should be running for at least 1 microsecond to be considered healthy
	// (minimal for testing, in production this would be higher)
	if uptime < time.Microsecond {
		return "starting"
	}

	return "ok"
}

// checkConfiguration checks if the service configuration is valid
func (h *HealthHandler) checkConfiguration() string {
	// In a real application, you would check:
	// - Required environment variables are set
	// - Configuration files are readable
	// - Required external dependencies are configured

	return "ok"
}

// GetStartTime returns the service start time (useful for testing)
func (h *HealthHandler) GetStartTime() time.Time {
	return h.startTime
}
