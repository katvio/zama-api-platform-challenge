package main

import (
	"flag"
	"log"
	"os"

	"github.com/katvio/api-go-service/internal/config"
	"github.com/katvio/api-go-service/internal/server"
	"github.com/katvio/api-go-service/pkg/logger"
)

var (
	version = "1.0.0" // This will be set at build time via -ldflags
	commit  = "dev"   // This will be set at build time via -ldflags
)

func main() {
	// Parse command line flags
	var (
		showVersion = flag.Bool("version", false, "Show version information")
		configPath  = flag.String("config", "", "Path to configuration file")
	)
	flag.Parse()

	// Show version if requested
	if *showVersion {
		log.Printf("zama-api-service version: %s, commit: %s\n", version, commit)
		os.Exit(0)
	}

	// Load configuration
	cfg := config.Load()

	// Override with config file if provided
	if *configPath != "" {
		// In a real application, you might want to load from a config file
		// For now, we'll stick with environment variables
		log.Printf("Config file loading not implemented, using environment variables")
	}

	// Initialize logger
	appLogger := logger.New(cfg.Logger.Level, cfg.Logger.Format)

	// Log startup information
	appLogger.WithFields(map[string]interface{}{
		"version":     version,
		"commit":      commit,
		"environment": cfg.Server.Environment,
		"log_level":   cfg.Logger.Level,
		"log_format":  cfg.Logger.Format,
	}).Info("Starting zama-api-service")

	// Create and start server
	srv := server.New(cfg, appLogger)

	// Run server (this blocks until shutdown signal is received)
	if err := srv.Run(); err != nil {
		appLogger.LogError(err, "main", "run_server", map[string]interface{}{
			"version": version,
			"commit":  commit,
		})
		os.Exit(1)
	}

	appLogger.Info("zama-api-service shutdown completed")
}
