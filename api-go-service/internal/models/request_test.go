package models

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestSumRequest_Validate(t *testing.T) {
	tests := []struct {
		name      string
		request   SumRequest
		wantError bool
		errorMsg  string
	}{
		{
			name:      "Valid request with 2 numbers",
			request:   SumRequest{Numbers: []float64{1.0, 2.0}},
			wantError: false,
		},
		{
			name:      "Valid request with multiple numbers",
			request:   SumRequest{Numbers: []float64{1.0, 2.0, 3.0, 4.0, 5.0}},
			wantError: false,
		},
		{
			name:      "Invalid request with 1 number",
			request:   SumRequest{Numbers: []float64{1.0}},
			wantError: true,
			errorMsg:  "at least 2 numbers are required, got 1",
		},
		{
			name:      "Invalid request with empty array",
			request:   SumRequest{Numbers: []float64{}},
			wantError: true,
			errorMsg:  "at least 2 numbers are required, got 0",
		},
		{
			name:      "Invalid request with too many numbers",
			request:   SumRequest{Numbers: make([]float64, 101)},
			wantError: true,
			errorMsg:  "maximum 100 numbers allowed, got 101",
		},
		{
			name:      "Valid request with exactly 100 numbers",
			request:   SumRequest{Numbers: make([]float64, 100)},
			wantError: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.request.Validate()
			if tt.wantError {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.errorMsg)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestNewSumResponse(t *testing.T) {
	numbers := []float64{1.5, 2.5, 3.0}
	requestID := "test-request-123"

	response := NewSumResponse(numbers, requestID)

	assert.Equal(t, 7.0, response.Sum)
	assert.Equal(t, 3, response.Count)
	assert.Equal(t, numbers, response.Numbers)
	assert.Equal(t, requestID, response.RequestID)
	assert.False(t, response.Timestamp.IsZero())
	assert.True(t, time.Since(response.Timestamp) < time.Second)
}

func TestNewHealthResponse(t *testing.T) {
	version := "1.0.0-test"
	uptime := "5m30s"
	requestID := "test-request-456"

	t.Run("Healthy response", func(t *testing.T) {
		checks := map[string]string{
			"memory":     "ok",
			"goroutines": "ok",
			"uptime":     "ok",
		}

		response := NewHealthResponse(version, uptime, checks, requestID)

		assert.Equal(t, "healthy", response.Status)
		assert.Equal(t, version, response.Version)
		assert.Equal(t, uptime, response.Uptime)
		assert.Equal(t, checks, response.Checks)
		assert.Equal(t, requestID, response.RequestID)
		assert.True(t, response.IsHealthy())
	})

	t.Run("Unhealthy response", func(t *testing.T) {
		checks := map[string]string{
			"memory":     "ok",
			"goroutines": "high_count",
			"uptime":     "ok",
		}

		response := NewHealthResponse(version, uptime, checks, requestID)

		assert.Equal(t, "unhealthy", response.Status)
		assert.False(t, response.IsHealthy())
	})
}

func TestNewErrorResponse(t *testing.T) {
	err := assert.AnError
	code := "TEST_ERROR"
	path := "/test/path"
	requestID := "test-request-789"

	response := NewErrorResponse(err, code, path, requestID)

	assert.Equal(t, err.Error(), response.Error)
	assert.Equal(t, code, response.Code)
	assert.Equal(t, path, response.Path)
	assert.Equal(t, requestID, response.RequestID)
	assert.False(t, response.Timestamp.IsZero())
}

func TestNewValidationErrorResponse(t *testing.T) {
	validationErrors := map[string]string{
		"field1": "is required",
		"field2": "must be positive",
	}
	path := "/validation/test"
	requestID := "test-request-validation"

	response := NewValidationErrorResponse(validationErrors, path, requestID)

	assert.Equal(t, "validation failed", response.Error)
	assert.Equal(t, "VALIDATION_ERROR", response.Code)
	assert.Equal(t, validationErrors, response.Details)
	assert.Equal(t, path, response.Path)
	assert.Equal(t, requestID, response.RequestID)
}

func TestToJSON(t *testing.T) {
	data := map[string]interface{}{
		"test":   "value",
		"number": 42,
	}

	jsonData, err := ToJSON(data)
	assert.NoError(t, err)
	assert.Contains(t, string(jsonData), "test")
	assert.Contains(t, string(jsonData), "value")
	assert.Contains(t, string(jsonData), "42")
}

func TestSumRequest_String(t *testing.T) {
	request := SumRequest{Numbers: []float64{1.0, 2.0, 3.0}}
	str := request.String()
	assert.Contains(t, str, "SumRequest")
	assert.Contains(t, str, "[1 2 3]")
}

func TestSumResponse_String(t *testing.T) {
	response := SumResponse{Sum: 6.0, Count: 3}
	str := response.String()
	assert.Contains(t, str, "SumResponse")
	assert.Contains(t, str, "6.000000")
	assert.Contains(t, str, "3")
}
