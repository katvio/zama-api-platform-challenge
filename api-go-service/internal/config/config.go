package config

import (
	"os"
	"strconv"
	"time"
)

// Config holds all configuration for our application
type Config struct {
	Server   ServerConfig
	Logger   LoggerConfig
	Metrics  MetricsConfig
	Health   HealthConfig
	Security SecurityConfig
}

// ServerConfig holds server-specific configuration
type ServerConfig struct {
	Port            string
	Host            string
	ReadTimeout     time.Duration
	WriteTimeout    time.Duration
	ShutdownTimeout time.Duration
	Environment     string
}

// LoggerConfig holds logging configuration
type LoggerConfig struct {
	Level  string
	Format string // json or text
}

// MetricsConfig holds metrics configuration
type MetricsConfig struct {
	Enabled bool
	Path    string
}

// HealthConfig holds health check configuration
type HealthConfig struct {
	Path string
}

// SecurityConfig holds security-related configuration
type SecurityConfig struct {
	APIKeyHeader   string
	TrustedProxies []string
}

// Load loads configuration from environment variables with sensible defaults
func Load() *Config {
	return &Config{
		Server: ServerConfig{
			Port:            getEnv("PORT", "8080"),
			Host:            getEnv("HOST", "0.0.0.0"),
			ReadTimeout:     getDurationEnv("READ_TIMEOUT", 30*time.Second),
			WriteTimeout:    getDurationEnv("WRITE_TIMEOUT", 30*time.Second),
			ShutdownTimeout: getDurationEnv("SHUTDOWN_TIMEOUT", 15*time.Second),
			Environment:     getEnv("ENVIRONMENT", "development"),
		},
		Logger: LoggerConfig{
			Level:  getEnv("LOG_LEVEL", "info"),
			Format: getEnv("LOG_FORMAT", "json"),
		},
		Metrics: MetricsConfig{
			Enabled: getBoolEnv("METRICS_ENABLED", true),
			Path:    getEnv("METRICS_PATH", "/metrics"),
		},
		Health: HealthConfig{
			Path: getEnv("HEALTH_PATH", "/healthz"),
		},
		Security: SecurityConfig{
			APIKeyHeader:   getEnv("API_KEY_HEADER", "X-API-Key"),
			TrustedProxies: getSliceEnv("TRUSTED_PROXIES", []string{"10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"}),
		},
	}
}

// getEnv gets an environment variable with a fallback default
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// getBoolEnv gets a boolean environment variable with a fallback default
func getBoolEnv(key string, defaultValue bool) bool {
	if value := os.Getenv(key); value != "" {
		if parsed, err := strconv.ParseBool(value); err == nil {
			return parsed
		}
	}
	return defaultValue
}

// getDurationEnv gets a duration environment variable with a fallback default
func getDurationEnv(key string, defaultValue time.Duration) time.Duration {
	if value := os.Getenv(key); value != "" {
		if parsed, err := time.ParseDuration(value); err == nil {
			return parsed
		}
	}
	return defaultValue
}

// getSliceEnv gets a slice environment variable with a fallback default
func getSliceEnv(key string, defaultValue []string) []string {
	if value := os.Getenv(key); value != "" {
		// For simplicity, we'll assume comma-separated values
		// In production, you might want more sophisticated parsing
		return []string{value}
	}
	return defaultValue
}

// IsProduction returns true if we're running in production environment
func (c *Config) IsProduction() bool {
	return c.Server.Environment == "production"
}

// IsDevelopment returns true if we're running in development environment
func (c *Config) IsDevelopment() bool {
	return c.Server.Environment == "development"
}
