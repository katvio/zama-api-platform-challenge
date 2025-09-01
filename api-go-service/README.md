# Zama API Service

A production-ready Go HTTP API service built for the Zama DevOps challenge. This service provides a simple sum calculation endpoint with comprehensive observability, security, and reliability features.

## Features

### Core API
- **Health Check Endpoint**: `/healthz` with comprehensive system checks
- **Sum Calculation**: `/api/v1/sum` - Calculate sum of numbers with validation
- **API Documentation**: Built-in endpoint documentation

### Production Features
- **Structured Logging**: JSON logging with request tracing
- **Metrics**: Prometheus metrics for observability
- **Graceful Shutdown**: Proper signal handling
- **Request Validation**: Input validation and error handling
- **Security**: Request ID tracking, recovery middleware
- **Health Checks**: Separate liveness and readiness probes

## Quick Start

### Prerequisites
- Go 1.21+
- Make (optional, for convenience commands)

### Running Locally

```bash
# Build and run
make build
./server

# Or run directly
go run ./cmd/server

# Or use make for development
make dev
```

The service will start on port 8080 by default.

### Testing the API

```bash
# Health check
curl http://localhost:8080/healthz

# Sum calculation
curl -X POST http://localhost:8080/api/v1/sum \
  -H "Content-Type: application/json" \
  -d '{"numbers": [1.5, 2.5, 3.0]}'

# API documentation
curl http://localhost:8080/api/v1/sum

# Metrics
curl http://localhost:8080/metrics
```

## Configuration

The service is configured via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | Server port |
| `HOST` | `0.0.0.0` | Server host |
| `LOG_LEVEL` | `info` | Log level (debug, info, warn, error) |
| `LOG_FORMAT` | `json` | Log format (json, text) |
| `ENVIRONMENT` | `development` | Environment (development, production) |
| `METRICS_ENABLED` | `true` | Enable Prometheus metrics |
| `READ_TIMEOUT` | `30s` | HTTP read timeout |
| `WRITE_TIMEOUT` | `30s` | HTTP write timeout |
| `SHUTDOWN_TIMEOUT` | `15s` | Graceful shutdown timeout |

## API Endpoints

### Health Endpoints

#### `GET /healthz`
Comprehensive health check with system status.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00Z",
  "version": "1.0.0",
  "uptime": "1h23m45s",
  "checks": {
    "memory": "ok",
    "goroutines": "ok",
    "uptime": "ok"
  },
  "request_id": "req-123"
}
```

#### `GET /healthz/live`
Kubernetes liveness probe endpoint.

#### `GET /healthz/ready`
Kubernetes readiness probe endpoint.

### API Endpoints

#### `POST /api/v1/sum`
Calculate the sum of an array of numbers.

**Request:**
```json
{
  "numbers": [1.5, 2.5, 3.0]
}
```

**Response:**
```json
{
  "sum": 7.0,
  "count": 3,
  "numbers": [1.5, 2.5, 3.0],
  "timestamp": "2024-01-01T00:00:00Z",
  "request_id": "req-123"
}
```

**Validation:**
- Minimum 2 numbers required
- Maximum 100 numbers allowed
- Numbers must be valid floats

#### `GET /api/v1/sum`
Get API documentation and examples.

### Metrics Endpoint

#### `GET /metrics`
Prometheus metrics endpoint with:
- HTTP request duration and count
- Request/response sizes
- Active connections
- Go runtime metrics
- Application info

## Development

### Available Make Commands

```bash
make help          # Show available commands
make build         # Build the application
make test          # Run tests
make test-race     # Run tests with race detection
make coverage      # Generate test coverage report
make lint          # Run linter (requires golangci-lint)
make fmt           # Format code
make vet           # Run go vet
make dev           # Build and run locally
make docker-build  # Build Docker image
make docker-run    # Run Docker container
```

### Running Tests

```bash
# Run all tests
go test ./...

# Run tests with coverage
go test ./... -coverprofile=coverage.out
go tool cover -html=coverage.out -o coverage.html

# Run tests with race detection
go test ./... -race

# Benchmark tests
go test -bench=. ./...
```

### Project Structure

```
api-go-service/
├── cmd/
│   └── server/          # Application entry point
├── internal/
│   ├── config/          # Configuration management
│   ├── handlers/        # HTTP handlers
│   ├── middleware/      # HTTP middleware
│   ├── models/          # Request/response models
│   └── server/          # Server setup and routing
├── pkg/
│   └── logger/          # Logging utilities
├── Dockerfile           # Container definition
├── Makefile            # Development commands
└── go.mod              # Go module definition
```

## Docker

### Building

```bash
# Build image
docker build -t zama-api-service .

# Build with version info
docker build \
  --build-arg VERSION=1.0.0 \
  --build-arg COMMIT=abc123 \
  -t zama-api-service:1.0.0 .
```

### Running

```bash
# Run container
docker run -p 8080:8080 zama-api-service

# Run with custom environment
docker run -p 8080:8080 \
  -e LOG_LEVEL=debug \
  -e ENVIRONMENT=development \
  zama-api-service
```

## Observability

### Logging
- Structured JSON logging
- Request ID tracking
- Component-based logging
- Configurable log levels

### Metrics
- HTTP request metrics (duration, count, size)
- Application metrics (active connections, goroutines)
- Go runtime metrics
- Custom business metrics

### Health Checks
- Liveness probe for Kubernetes
- Readiness probe for load balancers
- Comprehensive system health status
- Memory and goroutine monitoring

## Security Features

- Request ID generation and tracking
- Panic recovery middleware
- Input validation and sanitization
- Structured error responses
- Security headers (via reverse proxy)

## Performance

- Efficient JSON handling
- Connection pooling ready
- Graceful shutdown
- Resource monitoring
- Benchmark tests included

## Testing

The service includes comprehensive tests:

- **Unit Tests**: 89.9% handler coverage
- **Integration Tests**: HTTP endpoint testing
- **Benchmark Tests**: Performance testing
- **Race Detection**: Concurrency safety
- **Edge Cases**: Validation and error handling

Current test coverage:
- Handlers: 89.9%
- Overall: 24.9% (handlers are the main business logic)

## Production Deployment

### Environment Variables
Set appropriate values for production:

```bash
export ENVIRONMENT=production
export LOG_LEVEL=info
export LOG_FORMAT=json
export PORT=8080
```

### Health Checks
Configure your load balancer/orchestrator:

- **Liveness**: `GET /healthz/live`
- **Readiness**: `GET /healthz/ready`
- **Health**: `GET /healthz`

### Monitoring
The service exposes Prometheus metrics at `/metrics` for:

- Request latency and throughput
- Error rates
- Resource utilization
- Application health

## Contributing

1. Run tests: `make test`
2. Run linter: `make lint`
3. Format code: `make fmt`
4. Check coverage: `make coverage`

## License

This project is part of the Zama DevOps challenge.
