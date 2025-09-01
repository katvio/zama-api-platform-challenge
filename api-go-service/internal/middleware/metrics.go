package middleware

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

var (
	// HTTP request duration histogram
	httpDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "Duration of HTTP requests in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "endpoint", "status_code"},
	)

	// HTTP request counter
	httpRequests = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "endpoint", "status_code"},
	)

	// HTTP request size histogram
	httpRequestSize = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_size_bytes",
			Help:    "Size of HTTP requests in bytes",
			Buckets: prometheus.ExponentialBuckets(100, 10, 5),
		},
		[]string{"method", "endpoint"},
	)

	// HTTP response size histogram
	httpResponseSize = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_response_size_bytes",
			Help:    "Size of HTTP responses in bytes",
			Buckets: prometheus.ExponentialBuckets(100, 10, 5),
		},
		[]string{"method", "endpoint", "status_code"},
	)

	// Active connections gauge
	activeConnections = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "http_active_connections",
			Help: "Number of active HTTP connections",
		},
	)

	// Application info gauge
	appInfo = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "app_info",
			Help: "Application information",
		},
		[]string{"version", "environment"},
	)
)

// MetricsMiddleware creates a gin middleware for Prometheus metrics collection
func MetricsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()

		// Increment active connections
		activeConnections.Inc()
		defer activeConnections.Dec()

		// Get request size
		requestSize := computeRequestSize(c.Request)

		// Process request
		c.Next()

		// Calculate duration
		duration := time.Since(start).Seconds()

		// Get labels
		method := c.Request.Method
		endpoint := c.FullPath()
		if endpoint == "" {
			endpoint = c.Request.URL.Path
		}
		statusCode := strconv.Itoa(c.Writer.Status())

		// Record metrics
		httpDuration.WithLabelValues(method, endpoint, statusCode).Observe(duration)
		httpRequests.WithLabelValues(method, endpoint, statusCode).Inc()
		httpRequestSize.WithLabelValues(method, endpoint).Observe(float64(requestSize))

		// Get response size
		responseSize := c.Writer.Size()
		if responseSize > 0 {
			httpResponseSize.WithLabelValues(method, endpoint, statusCode).Observe(float64(responseSize))
		}
	}
}

// InitMetrics initializes application metrics
func InitMetrics(version, environment string) {
	appInfo.WithLabelValues(version, environment).Set(1)
}

// computeRequestSize computes the size of an HTTP request
func computeRequestSize(r *http.Request) int64 {
	size := int64(0)

	if r.URL != nil {
		size += int64(len(r.URL.String()))
	}

	size += int64(len(r.Method))
	size += int64(len(r.Proto))

	for name, values := range r.Header {
		size += int64(len(name))
		for _, value := range values {
			size += int64(len(value))
		}
	}

	if r.ContentLength > 0 {
		size += r.ContentLength
	}

	return size
}
