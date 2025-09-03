#!/bin/bash

# Zama API Platform - Kong Konnect Serverless Setup
# For serverless control planes, you only need your API service locally

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[SERVERLESS]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ️${NC}  $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Docker
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
    
    # Check Docker Compose
    if command -v docker-compose > /dev/null 2>&1 || docker compose version > /dev/null 2>&1; then
        print_success "Docker Compose is available"
    else
        print_error "Docker Compose is not available"
        exit 1
    fi
}

# Function to start services
start_services() {
    print_status "🚀 Starting Zama API Service for Kong Konnect Serverless"
    
    check_prerequisites
    
    # Use docker compose if available
    if docker compose version > /dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
    else
        COMPOSE_CMD="docker-compose"
    fi
    
    print_status "Using: $COMPOSE_CMD"
    
    # Start only the API service (no Kong data plane needed for serverless)
    $COMPOSE_CMD -f tools/docker-compose.yml up --build -d
    
    print_success "API service started!"
    
    # Wait for API service to be ready
    print_status "Waiting for API service to be ready..."
    
    for i in {1..30}; do
        if curl -f -s http://localhost:8080/healthz > /dev/null 2>&1; then
            print_success "API service is ready!"
            break
        fi
        print_status "Waiting for API service... (attempt $i/30)"
        sleep 2
    done
    
    show_info
}

# Function to stop services
stop_services() {
    print_status "🛑 Stopping services..."
    
    if docker compose version > /dev/null 2>&1; then
        docker compose -f tools/docker-compose.yml down -v
    else
        docker-compose -f tools/docker-compose.yml down -v
    fi
    
    print_success "Services stopped"
}

# Function to show logs
show_logs() {
    if docker compose version > /dev/null 2>&1; then
        docker compose -f tools/docker-compose.yml logs -f
    else
        docker-compose -f tools/docker-compose.yml logs -f
    fi
}

# Function to test setup
test_setup() {
    print_status "🧪 Testing Kong Konnect Serverless Setup"
    
    # Test API service directly
    print_status "Testing API service..."
    if curl -s http://localhost:8080/healthz | grep -q "healthy"; then
        print_success "✅ API service is healthy"
    else
        print_error "❌ API service is not responding"
        return 1
    fi
    
    # Test API endpoint
    print_status "Testing sum endpoint..."
    if curl -s -X POST http://localhost:8080/api/v1/sum \
        -H "Content-Type: application/json" \
        -d '{"numbers":[1,2,3]}' | grep -q '"sum":6'; then
        print_success "✅ Sum endpoint is working"
    else
        print_error "❌ Sum endpoint is not working"
        return 1
    fi
    
    print_success "🎉 Local API service is ready for Kong Konnect Serverless!"
}

# Function to show service information
show_info() {
    echo ""
    print_success "🎉 Zama API Service Ready for Kong Konnect Serverless!"
    echo ""
    print_status "🌐 Local Service:"
    echo "   • API Service:      http://localhost:8080"
    echo ""
    print_status "☁️  Kong Konnect Serverless:"
    echo "   • Konnect Dashboard: https://cloud.konghq.com/"
    echo "   • Your Proxy URL:    https://kong-4994957fd2euqcpzn.kongcloud.dev"
    echo "   • Analytics:         Built into Konnect dashboard"
    echo "   • Dev Portal:        Available in Konnect"
    echo ""
    print_status "📋 Next Steps in Konnect Dashboard:"
    echo "   1. Create a Service pointing to your API"
    echo "   2. Create Routes for your endpoints"
    echo "   3. Add Authentication (API Key plugin)"
    echo "   4. Add Rate Limiting plugin"
    echo "   5. Test via your Proxy URL"
    echo ""
    print_status "🧪 Local Test Commands:"
    echo "   # Health check:"
    echo "   curl http://localhost:8080/healthz"
    echo ""
    print_status "🧪 Konnect Test Commands (after configuration):"
    echo "   # Health check via Konnect:"
    echo "   curl https://kong-4994957fd2euqcpzn.kongcloud.dev/healthz"
    echo ""
    echo "   # Protected endpoint via Konnect:"
    echo "   curl -H 'apikey: YOUR_API_KEY' \\"
    echo "        -X POST https://kong-4994957fd2euqcpzn.kongcloud.dev/api/v1/sum \\"
    echo "        -H 'Content-Type: application/json' \\"
    echo "        -d '{\"numbers\":[5,10]}'"
    echo ""
    print_status "📊 Management:"
    echo "   • Configure APIs:   https://cloud.konghq.com/"
    echo "   • View Analytics:   Built into Konnect"
    echo "   • Stop service:     $0 stop"
    echo "   • View logs:        $0 logs"
    echo ""
}

# Function to show Kong Konnect configuration guide
show_konnect_guide() {
    echo ""
    print_status "=== Kong Konnect Serverless Configuration Guide ==="
    echo ""
    print_info "Since you're using a Serverless control plane, configuration is done entirely"
    print_info "through the Kong Konnect dashboard. Here's what you need to set up:"
    echo ""
    print_status "🔧 Step 1: Create a Service"
    echo "   • Go to: https://cloud.konghq.com/"
    echo "   • Navigate to: Gateway Manager > Services"
    echo "   • Click: 'New Service'"
    echo "   • Name: zama-api-service"
    echo "   • URL: http://host.docker.internal:8080"
    echo "   • (or your public IP if accessible)"
    echo ""
    print_status "🛣️  Step 2: Create Routes"
    echo "   • Go to: Gateway Manager > Routes"
    echo "   • Create route for health: /healthz (no auth needed)"
    echo "   • Create route for API: /api/v1/sum (with auth)"
    echo ""
    print_status "🔐 Step 3: Add Authentication"
    echo "   • Go to: Gateway Manager > Plugins"
    echo "   • Add 'Key Authentication' plugin to /api/v1/sum route"
    echo "   • Create consumers and API keys"
    echo ""
    print_status "🛡️  Step 4: Add Rate Limiting"
    echo "   • Add 'Rate Limiting' plugin"
    echo "   • Set limits: 100/minute, 1000/hour"
    echo ""
    print_status "🧪 Step 5: Test"
    echo "   • Use your Proxy URL: https://kong-4994957fd2euqcpzn.kongcloud.dev"
    echo "   • Test with your API keys"
    echo ""
}

# Function to show help
show_help() {
    echo ""
    print_status "=== Kong Konnect Serverless Setup ==="
    echo ""
    print_info "For serverless control planes, you only need to run your API service locally."
    print_info "Kong Konnect handles all the gateway functionality in the cloud."
    echo ""
    print_status "🔧 Available Commands:"
    echo "   $0 start     - Start the API service"
    echo "   $0 stop      - Stop the API service"
    echo "   $0 test      - Test the API service"
    echo "   $0 logs      - Show API service logs"
    echo "   $0 guide     - Show Konnect configuration guide"
    echo "   $0 help      - Show this help"
    echo ""
}

# Main script logic
main() {
    local command=${1:-start}
    
    case $command in
        "start")
            start_services
            ;;
        "stop")
            stop_services
            ;;
        "test")
            test_setup
            ;;
        "logs")
            show_logs
            ;;
        "guide")
            show_konnect_guide
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
