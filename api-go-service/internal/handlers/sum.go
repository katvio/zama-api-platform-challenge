package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/katvio/api-go-service/internal/middleware"
	"github.com/katvio/api-go-service/internal/models"
	"github.com/katvio/api-go-service/pkg/logger"
)

// SumHandler handles sum calculation requests
type SumHandler struct {
	logger *logger.Logger
}

// NewSumHandler creates a new sum handler
func NewSumHandler(logger *logger.Logger) *SumHandler {
	return &SumHandler{
		logger: logger,
	}
}

// HandleSum handles POST /api/v1/sum requests
func (s *SumHandler) HandleSum(c *gin.Context) {
	requestID, _ := c.Get(middleware.RequestIDKey)
	reqID, _ := requestID.(string)

	// Parse request body
	var request models.SumRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		s.logger.WithError(err).WithFields(map[string]interface{}{
			"component":  "sum_handler",
			"operation":  "bind_request",
			"request_id": reqID,
		}).Error("Failed to bind request")

		errorResponse := models.NewErrorResponse(
			err,
			"INVALID_REQUEST_BODY",
			c.Request.URL.Path,
			reqID,
		)
		c.JSON(http.StatusBadRequest, errorResponse)
		return
	}

	// Validate request
	if err := request.Validate(); err != nil {
		s.logger.WithError(err).WithFields(map[string]interface{}{
			"component":  "sum_handler",
			"operation":  "validate_request",
			"request_id": reqID,
			"numbers":    request.Numbers,
		}).Error("Request validation failed")

		errorResponse := models.NewErrorResponse(
			err,
			"VALIDATION_ERROR",
			c.Request.URL.Path,
			reqID,
		)
		c.JSON(http.StatusBadRequest, errorResponse)
		return
	}

	// Log the operation
	s.logger.WithFields(map[string]interface{}{
		"component":    "sum_handler",
		"operation":    "calculate_sum",
		"request_id":   reqID,
		"number_count": len(request.Numbers),
	}).Info("Processing sum calculation")

	// Calculate sum and create response
	response := models.NewSumResponse(request.Numbers, reqID)

	// Log successful operation
	s.logger.WithFields(map[string]interface{}{
		"component":  "sum_handler",
		"operation":  "sum_calculated",
		"request_id": reqID,
		"sum":        response.Sum,
		"count":      response.Count,
	}).Info("Sum calculation completed")

	c.JSON(http.StatusOK, response)
}

// HandleSumGet handles GET /api/v1/sum requests (for testing/demo purposes)
func (s *SumHandler) HandleSumGet(c *gin.Context) {
	requestID, _ := c.Get(middleware.RequestIDKey)
	reqID, _ := requestID.(string)

	// Return information about the sum endpoint
	info := map[string]interface{}{
		"endpoint":    "/api/v1/sum",
		"method":      "POST",
		"description": "Calculate the sum of an array of numbers",
		"request_format": map[string]interface{}{
			"numbers": "array of numbers (min: 2, max: 100)",
		},
		"example_request": map[string]interface{}{
			"numbers": []float64{1.5, 2.5, 3.0},
		},
		"example_response": map[string]interface{}{
			"sum":       7.0,
			"count":     3,
			"numbers":   []float64{1.5, 2.5, 3.0},
			"timestamp": "2024-01-01T00:00:00Z",
		},
		"request_id": reqID,
	}

	s.logger.WithFields(map[string]interface{}{
		"component":  "sum_handler",
		"operation":  "get_info",
		"request_id": reqID,
	}).Info("Sum endpoint info requested")

	c.JSON(http.StatusOK, info)
}
