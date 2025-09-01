package handlers

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/katvio/api-go-service/internal/middleware"
	"github.com/katvio/api-go-service/internal/models"
	"github.com/katvio/api-go-service/pkg/logger"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func setupTestRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	router := gin.New()

	// Add middleware for testing
	router.Use(func(c *gin.Context) {
		c.Set(middleware.RequestIDKey, "test-request-id")
		c.Header("X-Request-ID", "test-request-id")
		c.Next()
	})

	return router
}

func setupTestLogger() *logger.Logger {
	return logger.New("error", "json") // Use error level to reduce test noise
}

// TestHealthHandler tests the health check endpoints
func TestHealthHandler(t *testing.T) {
	log := setupTestLogger()
	handler := NewHealthHandler(log, "1.0.0-test")
	router := setupTestRouter()

	router.GET("/healthz", handler.HandleHealth)
	router.GET("/healthz/live", handler.HandleLiveness)
	router.GET("/healthz/ready", handler.HandleReadiness)

	tests := []struct {
		name           string
		endpoint       string
		expectedStatus int
		checkFields    []string
	}{
		{
			name:           "Health check returns OK",
			endpoint:       "/healthz",
			expectedStatus: http.StatusOK,
			checkFields:    []string{"status", "timestamp", "version", "uptime", "checks"},
		},
		{
			name:           "Liveness check returns OK",
			endpoint:       "/healthz/live",
			expectedStatus: http.StatusOK,
			checkFields:    []string{"status", "timestamp"},
		},
		{
			name:           "Readiness check returns OK",
			endpoint:       "/healthz/ready",
			expectedStatus: http.StatusOK,
			checkFields:    []string{"status", "timestamp", "checks"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req, _ := http.NewRequest("GET", tt.endpoint, nil)
			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)

			if w.Code != tt.expectedStatus {
				t.Logf("Response body: %s", w.Body.String())
			}
			assert.Equal(t, tt.expectedStatus, w.Code)

			var response map[string]interface{}
			err := json.Unmarshal(w.Body.Bytes(), &response)
			require.NoError(t, err)

			// Check that all expected fields are present
			for _, field := range tt.checkFields {
				assert.Contains(t, response, field, "Response should contain field: %s", field)
			}

			// Check request ID header
			assert.Equal(t, "test-request-id", w.Header().Get("X-Request-ID"))
		})
	}
}

func TestHealthHandler_StartTime(t *testing.T) {
	log := setupTestLogger()
	handler := NewHealthHandler(log, "1.0.0-test")

	startTime := handler.GetStartTime()
	assert.True(t, time.Since(startTime) < time.Second, "Start time should be recent")
}

// TestSumHandler tests the sum calculation endpoints
func TestSumHandler(t *testing.T) {
	log := setupTestLogger()
	handler := NewSumHandler(log)
	router := setupTestRouter()

	router.POST("/api/v1/sum", handler.HandleSum)
	router.GET("/api/v1/sum", handler.HandleSumGet)

	t.Run("POST /api/v1/sum - Valid request", func(t *testing.T) {
		request := models.SumRequest{
			Numbers: []float64{1.5, 2.5, 3.0},
		}

		jsonData, _ := json.Marshal(request)
		req, _ := http.NewRequest("POST", "/api/v1/sum", bytes.NewBuffer(jsonData))
		req.Header.Set("Content-Type", "application/json")

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response models.SumResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)

		assert.Equal(t, 7.0, response.Sum)
		assert.Equal(t, 3, response.Count)
		assert.Equal(t, request.Numbers, response.Numbers)
		assert.Equal(t, "test-request-id", response.RequestID)
		assert.False(t, response.Timestamp.IsZero())
	})

	t.Run("POST /api/v1/sum - Invalid JSON", func(t *testing.T) {
		req, _ := http.NewRequest("POST", "/api/v1/sum", bytes.NewBuffer([]byte("invalid json")))
		req.Header.Set("Content-Type", "application/json")

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)

		var response models.ErrorResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)

		assert.Equal(t, "INVALID_REQUEST_BODY", response.Code)
		assert.Equal(t, "test-request-id", response.RequestID)
	})

	t.Run("POST /api/v1/sum - Too few numbers", func(t *testing.T) {
		request := models.SumRequest{
			Numbers: []float64{1.5}, // Only one number
		}

		jsonData, _ := json.Marshal(request)
		req, _ := http.NewRequest("POST", "/api/v1/sum", bytes.NewBuffer(jsonData))
		req.Header.Set("Content-Type", "application/json")

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)

		var response models.ErrorResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)

		assert.Equal(t, "VALIDATION_ERROR", response.Code)
		assert.Contains(t, response.Error, "at least 2 numbers are required")
	})

	t.Run("POST /api/v1/sum - Too many numbers", func(t *testing.T) {
		// Create a request with more than 100 numbers
		numbers := make([]float64, 101)
		for i := range numbers {
			numbers[i] = float64(i)
		}

		request := models.SumRequest{Numbers: numbers}
		jsonData, _ := json.Marshal(request)
		req, _ := http.NewRequest("POST", "/api/v1/sum", bytes.NewBuffer(jsonData))
		req.Header.Set("Content-Type", "application/json")

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)

		var response models.ErrorResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)

		assert.Equal(t, "VALIDATION_ERROR", response.Code)
		assert.Contains(t, response.Error, "maximum 100 numbers allowed")
	})

	t.Run("GET /api/v1/sum - Returns endpoint info", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/api/v1/sum", nil)

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)

		assert.Equal(t, "/api/v1/sum", response["endpoint"])
		assert.Equal(t, "POST", response["method"])
		assert.Contains(t, response, "description")
		assert.Contains(t, response, "example_request")
		assert.Contains(t, response, "example_response")
	})
}

// TestSumHandler_EdgeCases tests edge cases for sum calculation
func TestSumHandler_EdgeCases(t *testing.T) {
	log := setupTestLogger()
	handler := NewSumHandler(log)
	router := setupTestRouter()
	router.POST("/api/v1/sum", handler.HandleSum)

	tests := []struct {
		name           string
		numbers        []float64
		expectedSum    float64
		expectedStatus int
	}{
		{
			name:           "Two numbers",
			numbers:        []float64{1.0, 2.0},
			expectedSum:    3.0,
			expectedStatus: http.StatusOK,
		},
		{
			name:           "Negative numbers",
			numbers:        []float64{-1.0, -2.0, -3.0},
			expectedSum:    -6.0,
			expectedStatus: http.StatusOK,
		},
		{
			name:           "Mixed positive and negative",
			numbers:        []float64{10.0, -5.0, 3.0},
			expectedSum:    8.0,
			expectedStatus: http.StatusOK,
		},
		{
			name:           "Zeros",
			numbers:        []float64{0.0, 0.0, 0.0},
			expectedSum:    0.0,
			expectedStatus: http.StatusOK,
		},
		{
			name:           "Large numbers",
			numbers:        []float64{1000000.0, 2000000.0},
			expectedSum:    3000000.0,
			expectedStatus: http.StatusOK,
		},
		{
			name:           "Decimal precision",
			numbers:        []float64{0.1, 0.2, 0.3},
			expectedSum:    0.6,
			expectedStatus: http.StatusOK,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			request := models.SumRequest{Numbers: tt.numbers}
			jsonData, _ := json.Marshal(request)
			req, _ := http.NewRequest("POST", "/api/v1/sum", bytes.NewBuffer(jsonData))
			req.Header.Set("Content-Type", "application/json")

			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)

			assert.Equal(t, tt.expectedStatus, w.Code)

			if tt.expectedStatus == http.StatusOK {
				var response models.SumResponse
				err := json.Unmarshal(w.Body.Bytes(), &response)
				require.NoError(t, err)

				assert.InDelta(t, tt.expectedSum, response.Sum, 0.0001, "Sum should match expected value")
				assert.Equal(t, len(tt.numbers), response.Count)
			}
		})
	}
}

// BenchmarkSumHandler benchmarks the sum calculation endpoint
func BenchmarkSumHandler(b *testing.B) {
	log := setupTestLogger()
	handler := NewSumHandler(log)
	router := setupTestRouter()
	router.POST("/api/v1/sum", handler.HandleSum)

	request := models.SumRequest{
		Numbers: []float64{1.0, 2.0, 3.0, 4.0, 5.0},
	}
	jsonData, _ := json.Marshal(request)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		req, _ := http.NewRequest("POST", "/api/v1/sum", bytes.NewBuffer(jsonData))
		req.Header.Set("Content-Type", "application/json")

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		if w.Code != http.StatusOK {
			b.Fatalf("Expected status 200, got %d", w.Code)
		}
	}
}
