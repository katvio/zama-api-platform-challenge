package models

import (
	"encoding/json"
	"fmt"
	"time"
)

// SumRequest represents the request payload for the sum endpoint
type SumRequest struct {
	Numbers []float64 `json:"numbers" binding:"required" validate:"required"`
}

// Validate performs custom validation on the SumRequest
func (s *SumRequest) Validate() error {
	if len(s.Numbers) < 2 {
		return fmt.Errorf("at least 2 numbers are required, got %d", len(s.Numbers))
	}

	if len(s.Numbers) > 100 {
		return fmt.Errorf("maximum 100 numbers allowed, got %d", len(s.Numbers))
	}

	return nil
}

// SumResponse represents the response payload for the sum endpoint
type SumResponse struct {
	Sum       float64   `json:"sum"`
	Count     int       `json:"count"`
	Numbers   []float64 `json:"numbers"`
	Timestamp time.Time `json:"timestamp"`
	RequestID string    `json:"request_id,omitempty"`
}

// HealthResponse represents the response payload for the health endpoint
type HealthResponse struct {
	Status    string            `json:"status"`
	Timestamp time.Time         `json:"timestamp"`
	Version   string            `json:"version,omitempty"`
	Uptime    string            `json:"uptime,omitempty"`
	Checks    map[string]string `json:"checks,omitempty"`
	RequestID string            `json:"request_id,omitempty"`
}

// ErrorResponse represents a standardized error response
type ErrorResponse struct {
	Error     string            `json:"error"`
	Code      string            `json:"code,omitempty"`
	Details   map[string]string `json:"details,omitempty"`
	Timestamp time.Time         `json:"timestamp"`
	RequestID string            `json:"request_id,omitempty"`
	Path      string            `json:"path,omitempty"`
}

// MetricsResponse represents the response for metrics endpoint
type MetricsResponse struct {
	Metrics   map[string]interface{} `json:"metrics"`
	Timestamp time.Time              `json:"timestamp"`
	RequestID string                 `json:"request_id,omitempty"`
}

// NewSumResponse creates a new SumResponse with calculated values
func NewSumResponse(numbers []float64, requestID string) *SumResponse {
	sum := 0.0
	for _, num := range numbers {
		sum += num
	}

	return &SumResponse{
		Sum:       sum,
		Count:     len(numbers),
		Numbers:   numbers,
		Timestamp: time.Now().UTC(),
		RequestID: requestID,
	}
}

// NewHealthResponse creates a new HealthResponse
func NewHealthResponse(version, uptime string, checks map[string]string, requestID string) *HealthResponse {
	status := "healthy"

	// If any check fails, mark as unhealthy
	for _, checkStatus := range checks {
		if checkStatus != "ok" {
			status = "unhealthy"
			break
		}
	}

	return &HealthResponse{
		Status:    status,
		Timestamp: time.Now().UTC(),
		Version:   version,
		Uptime:    uptime,
		Checks:    checks,
		RequestID: requestID,
	}
}

// NewErrorResponse creates a new ErrorResponse
func NewErrorResponse(err error, code, path, requestID string) *ErrorResponse {
	return &ErrorResponse{
		Error:     err.Error(),
		Code:      code,
		Timestamp: time.Now().UTC(),
		RequestID: requestID,
		Path:      path,
	}
}

// NewValidationErrorResponse creates a new ErrorResponse for validation errors
func NewValidationErrorResponse(validationErrors map[string]string, path, requestID string) *ErrorResponse {
	return &ErrorResponse{
		Error:     "validation failed",
		Code:      "VALIDATION_ERROR",
		Details:   validationErrors,
		Timestamp: time.Now().UTC(),
		RequestID: requestID,
		Path:      path,
	}
}

// ToJSON converts any response to JSON bytes
func ToJSON(v interface{}) ([]byte, error) {
	return json.Marshal(v)
}

// String returns a string representation of SumRequest
func (s *SumRequest) String() string {
	return fmt.Sprintf("SumRequest{Numbers: %v}", s.Numbers)
}

// String returns a string representation of SumResponse
func (s *SumResponse) String() string {
	return fmt.Sprintf("SumResponse{Sum: %f, Count: %d}", s.Sum, s.Count)
}

// IsHealthy returns true if the health check is healthy
func (h *HealthResponse) IsHealthy() bool {
	return h.Status == "healthy"
}
