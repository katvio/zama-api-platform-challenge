package server

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/katvio/api-go-service/internal/config"
	"github.com/katvio/api-go-service/internal/middleware"
	"github.com/katvio/api-go-service/pkg/logger"
)

// Server represents the HTTP server
type Server struct {
	httpServer *http.Server
	config     *config.Config
	logger     *logger.Logger
}

// New creates a new server instance
func New(cfg *config.Config, log *logger.Logger) *Server {
	// Initialize metrics if enabled
	if cfg.Metrics.Enabled {
		middleware.InitMetrics(getVersion(), cfg.Server.Environment)
	}

	// Setup routes
	router := SetupRoutes(cfg, log)

	// Create HTTP server
	httpServer := &http.Server{
		Addr:         fmt.Sprintf("%s:%s", cfg.Server.Host, cfg.Server.Port),
		Handler:      router,
		ReadTimeout:  cfg.Server.ReadTimeout,
		WriteTimeout: cfg.Server.WriteTimeout,
	}

	return &Server{
		httpServer: httpServer,
		config:     cfg,
		logger:     log,
	}
}

// Start starts the HTTP server
func (s *Server) Start() error {
	// Log service startup
	s.logger.LogServiceStart("zama-api-service", getVersion(), s.config.Server.Port)

	// Start server in a goroutine
	go func() {
		if err := s.httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			s.logger.LogError(err, "server", "start_server", map[string]interface{}{
				"port": s.config.Server.Port,
				"host": s.config.Server.Host,
			})
		}
	}()

	s.logger.WithFields(map[string]interface{}{
		"port":        s.config.Server.Port,
		"host":        s.config.Server.Host,
		"environment": s.config.Server.Environment,
		"version":     getVersion(),
	}).Info("Server started successfully")

	return nil
}

// Stop gracefully stops the HTTP server
func (s *Server) Stop() error {
	s.logger.LogServiceStop("zama-api-service")

	// Create context with timeout for shutdown
	ctx, cancel := context.WithTimeout(context.Background(), s.config.Server.ShutdownTimeout)
	defer cancel()

	// Shutdown server
	if err := s.httpServer.Shutdown(ctx); err != nil {
		s.logger.LogError(err, "server", "shutdown", nil)
		return err
	}

	s.logger.Info("Server stopped gracefully")
	return nil
}

// Run starts the server and handles graceful shutdown
func (s *Server) Run() error {
	// Start the server
	if err := s.Start(); err != nil {
		return err
	}

	// Wait for interrupt signal to gracefully shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	// Block until signal is received
	sig := <-quit
	s.logger.WithFields(map[string]interface{}{
		"signal": sig.String(),
	}).Info("Shutdown signal received")

	// Graceful shutdown
	return s.Stop()
}

// Health returns the server health status
func (s *Server) Health() error {
	// Simple health check - try to connect to the server
	client := &http.Client{
		Timeout: 5 * time.Second,
	}

	url := fmt.Sprintf("http://%s:%s%s", s.config.Server.Host, s.config.Server.Port, s.config.Health.Path)
	resp, err := client.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("health check failed with status: %d", resp.StatusCode)
	}

	return nil
}

// GetConfig returns the server configuration
func (s *Server) GetConfig() *config.Config {
	return s.config
}

// GetLogger returns the server logger
func (s *Server) GetLogger() *logger.Logger {
	return s.logger
}
