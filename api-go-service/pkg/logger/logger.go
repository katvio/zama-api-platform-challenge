package logger

import (
	"context"
	"os"
	"strings"
	"time"

	"github.com/sirupsen/logrus"
)

// Logger wraps logrus.Logger with additional functionality
type Logger struct {
	*logrus.Logger
}

// New creates a new logger instance with the specified configuration
func New(level, format string) *Logger {
	log := logrus.New()

	// Set log level
	logLevel, err := logrus.ParseLevel(strings.ToLower(level))
	if err != nil {
		logLevel = logrus.InfoLevel
	}
	log.SetLevel(logLevel)

	// Set formatter based on format
	switch strings.ToLower(format) {
	case "json":
		log.SetFormatter(&logrus.JSONFormatter{
			TimestampFormat: time.RFC3339,
			FieldMap: logrus.FieldMap{
				logrus.FieldKeyTime:  "timestamp",
				logrus.FieldKeyLevel: "level",
				logrus.FieldKeyMsg:   "message",
				logrus.FieldKeyFunc:  "caller",
			},
		})
	default:
		log.SetFormatter(&logrus.TextFormatter{
			FullTimestamp:   true,
			TimestampFormat: time.RFC3339,
		})
	}

	// Set output to stdout
	log.SetOutput(os.Stdout)

	// Enable caller information for debugging
	log.SetReportCaller(true)

	return &Logger{Logger: log}
}

// WithContext adds context fields to the logger
func (l *Logger) WithContext(ctx context.Context) *logrus.Entry {
	entry := l.WithField("trace_id", getTraceID(ctx))
	return entry
}

// WithRequestID adds request ID to the logger
func (l *Logger) WithRequestID(requestID string) *logrus.Entry {
	return l.WithField("request_id", requestID)
}

// WithComponent adds component name to the logger
func (l *Logger) WithComponent(component string) *logrus.Entry {
	return l.WithField("component", component)
}

// WithError adds error information to the logger
func (l *Logger) WithError(err error) *logrus.Entry {
	return l.Logger.WithError(err)
}

// WithFields adds multiple fields to the logger
func (l *Logger) WithFields(fields map[string]interface{}) *logrus.Entry {
	return l.Logger.WithFields(logrus.Fields(fields))
}

// LogHTTPRequest logs HTTP request information
func (l *Logger) LogHTTPRequest(method, path, userAgent, clientIP string, statusCode int, latency time.Duration, requestID string) {
	l.WithFields(map[string]interface{}{
		"method":      method,
		"path":        path,
		"status_code": statusCode,
		"latency_ms":  latency.Milliseconds(),
		"user_agent":  userAgent,
		"client_ip":   clientIP,
		"request_id":  requestID,
		"type":        "http_request",
	}).Info("HTTP request processed")
}

// LogError logs error with additional context
func (l *Logger) LogError(err error, component, operation string, fields map[string]interface{}) {
	entry := l.WithError(err).WithFields(map[string]interface{}{
		"component": component,
		"operation": operation,
		"type":      "error",
	})

	if fields != nil {
		entry = entry.WithFields(logrus.Fields(fields))
	}

	entry.Error("Operation failed")
}

// LogServiceStart logs service startup information
func (l *Logger) LogServiceStart(serviceName, version, port string) {
	l.WithFields(map[string]interface{}{
		"service": serviceName,
		"version": version,
		"port":    port,
		"type":    "service_start",
	}).Info("Service starting")
}

// LogServiceStop logs service shutdown information
func (l *Logger) LogServiceStop(serviceName string) {
	l.WithFields(map[string]interface{}{
		"service": serviceName,
		"type":    "service_stop",
	}).Info("Service shutting down")
}

// getTraceID extracts trace ID from context
// In a real implementation, you'd extract this from your tracing system
func getTraceID(ctx context.Context) string {
	if ctx == nil {
		return ""
	}

	// This is a placeholder - in production you'd use your tracing system
	// e.g., OpenTelemetry, Jaeger, etc.
	if traceID := ctx.Value("trace_id"); traceID != nil {
		if id, ok := traceID.(string); ok {
			return id
		}
	}

	return ""
}

// HealthCheckFields returns standard fields for health check logging
func HealthCheckFields() map[string]interface{} {
	return map[string]interface{}{
		"component": "health_check",
		"type":      "health_check",
	}
}

// MetricsFields returns standard fields for metrics logging
func MetricsFields() map[string]interface{} {
	return map[string]interface{}{
		"component": "metrics",
		"type":      "metrics",
	}
}
