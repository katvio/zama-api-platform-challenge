package server

import (
	"github.com/gin-gonic/gin"
	"github.com/katvio/api-go-service/internal/config"
	"github.com/katvio/api-go-service/internal/handlers"
	"github.com/katvio/api-go-service/internal/middleware"
	"github.com/katvio/api-go-service/pkg/logger"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// SetupRoutes configures all routes for the application
func SetupRoutes(cfg *config.Config, log *logger.Logger) *gin.Engine {
	// Set Gin mode based on environment
	if cfg.IsProduction() {
		gin.SetMode(gin.ReleaseMode)
	} else {
		gin.SetMode(gin.DebugMode)
	}

	// Create router
	router := gin.New()

	// Set trusted proxies for security
	router.SetTrustedProxies(cfg.Security.TrustedProxies)

	// Global middleware
	router.Use(middleware.RecoveryMiddleware(log))
	router.Use(middleware.LoggingMiddleware(log))

	if cfg.Metrics.Enabled {
		router.Use(middleware.MetricsMiddleware())
	}

	// Initialize handlers
	healthHandler := handlers.NewHealthHandler(log, getVersion())
	sumHandler := handlers.NewSumHandler(log)

	// Health check routes (no API key required)
	router.GET(cfg.Health.Path, healthHandler.HandleHealth)
	router.GET("/healthz/live", healthHandler.HandleLiveness)
	router.GET("/healthz/ready", healthHandler.HandleReadiness)

	// Metrics endpoint (if enabled)
	if cfg.Metrics.Enabled {
		router.GET(cfg.Metrics.Path, gin.WrapH(promhttp.Handler()))
	}

	// API routes (versioned)
	v1 := router.Group("/api/v1")
	{
		// Sum endpoint
		v1.POST("/sum", sumHandler.HandleSum)
		v1.GET("/sum", sumHandler.HandleSumGet) // Info endpoint
	}

	// Root endpoint - API information
	router.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"service":     "zama-api-service",
			"version":     getVersion(),
			"environment": cfg.Server.Environment,
			"endpoints": gin.H{
				"health":  cfg.Health.Path,
				"metrics": cfg.Metrics.Path,
				"api": gin.H{
					"v1": gin.H{
						"sum": "/api/v1/sum",
					},
				},
			},
		})
	})

	return router
}

// getVersion returns the application version
// In a real application, this would be injected at build time
func getVersion() string {
	// This could be set via build flags: -ldflags "-X main.version=1.0.0"
	return "1.0.0"
}
