#!/bin/bash

# Zama API Platform - Endpoint Testing Script
# This script tests all endpoints to verify the setup is working correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
API_BASE_URL="http://localhost:8080"
KONG_PROXY_URL="http://localhost:8000"
KONG_ADMIN_URL="http://localhost:8001"

# Test API keys
TEST_KEYS=("your-test-key" "zama-test-key-2024" "test-api-key-123")

# Function to print colored output
print_status() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ️${NC}  $1"
}

# Function to test HTTP endpoint
test_endpoint() {
    local name="$1"
    local url="$2"
    local method="${3:-GET}"
    local data="$4"
    local headers="$5"
    local expected_status="${6:-200}"
    local expected_content="$7"
    
    print_status "Testing: $name"
    
    # Build curl command
    local curl_cmd="curl -s -w '%{http_code}' -o /tmp/response.json"
    
    if [ -n "$headers" ]; then
        curl_cmd="$curl_cmd $headers"
    fi
    
    if [ "$method" != "GET" ]; then
        curl_cmd="$curl_cmd -X $method"
    fi
    
    if [ -n "$data" ]; then
        curl_cmd="$curl_cmd -H 'Content-Type: application/json' -d '$data'"
    fi
    
    curl_cmd="$curl_cmd '$url'"
    
    # Execute request
    local status_code
    status_code=$(eval "$curl_cmd")
    local response_body
    response_body=$(cat /tmp/response.json)
    
    # Check status code
    if [ "$status_code" -eq "$expected_status" ]; then
        if [ -n "$expected_content" ]; then
            if echo "$response_body" | grep -q "$expected_content"; then
                print_success "$name - Status: $status_code, Content: ✓"
                return 0
            else
                print_error "$name - Status: $status_code, Content: ✗ (expected: $expected_content)"
                echo "Response: $response_body"
                return 1
            fi
        else
            print_success "$name - Status: $status_code"
            return 0
        fi
    else
        print_error "$name - Expected: $expected_status, Got: $status_code"
        echo "Response: $response_body"
        return 1
    fi
}

# Function to test rate limiting
test_rate_limiting() {
    local api_key="$1"
    print_status "Testing rate limiting with key: $api_key"
    
    local success_count=0
    local rate_limited_count=0
    
    # Make multiple requests quickly
    for i in {1..10}; do
        local status_code
        status_code=$(curl -s -w '%{http_code}' -o /dev/null \
            -H "apikey: $api_key" \
            -X POST "$KONG_PROXY_URL/api/v1/sum" \
            -H "Content-Type: application/json" \
            -d '{"numbers":[1,2]}')
        
        if [ "$status_code" -eq 200 ]; then
            ((success_count++))
        elif [ "$status_code" -eq 429 ]; then
            ((rate_limited_count++))
        fi
        
        sleep 0.1
    done
    
    print_status "Rate limiting test results: $success_count successful, $rate_limited_count rate-limited"
    
    if [ $success_count -gt 0 ]; then
        print_success "Rate limiting allows requests"
    else
        print_error "Rate limiting blocks all requests"
    fi
}

# Main testing function
main() {
    echo ""
    print_status "=== Zama API Platform - Endpoint Testing ==="
    echo ""
    
    local total_tests=0
    local passed_tests=0
    
    # Test 1: Direct API Service Health Check
    print_status "--- Direct API Service Tests ---"
    ((total_tests++))
    if test_endpoint "API Health Check" "$API_BASE_URL/healthz" "GET" "" "" 200 "healthy"; then
        ((passed_tests++))
    fi
    
    # Test 2: Direct API Service Sum Endpoint
    ((total_tests++))
    if test_endpoint "API Sum Endpoint" "$API_BASE_URL/api/v1/sum" "POST" '{"numbers":[1,2,3]}' "" 200 '"sum":6'; then
        ((passed_tests++))
    fi
    
    # Test 3: Direct API Service Metrics
    ((total_tests++))
    if test_endpoint "API Metrics" "$API_BASE_URL/metrics" "GET" "" "" 200 "go_info"; then
        ((passed_tests++))
    fi
    
    echo ""
    print_status "--- Kong Data Plane Tests ---"
    
    # Test 4: Kong Proxy Health Check (should work without auth)
    ((total_tests++))
    if test_endpoint "Kong Proxy Health" "$KONG_PROXY_URL/healthz" "GET" "" "" 200 "healthy"; then
        ((passed_tests++))
    fi
    
    # Test 5: Kong Proxy Root (should work without auth)
    ((total_tests++))
    if test_endpoint "Kong Proxy Root" "$KONG_PROXY_URL/" "GET" "" "" 200 "zama-api-service"; then
        ((passed_tests++))
    fi
    
    echo ""
    print_status "--- Authentication Tests ---"
    
    # Test each API key
    for api_key in "${TEST_KEYS[@]}"; do
        ((total_tests++))
        if test_endpoint "Protected Endpoint (Key: $api_key)" "$KONG_PROXY_URL/api/v1/sum" "POST" '{"numbers":[5,10]}' "-H 'apikey: $api_key'" 200 '"sum":15'; then
            ((passed_tests++))
        fi
    done
    
    # Test with invalid API key
    ((total_tests++))
    if test_endpoint "Protected Endpoint (Invalid Key)" "$KONG_PROXY_URL/api/v1/sum" "POST" '{"numbers":[1,2]}' "-H 'apikey: invalid-key'" 401 "Invalid authentication credentials"; then
        ((passed_tests++))
    fi
    
    echo ""
    print_status "--- Rate Limiting Tests ---"
    
    # Test rate limiting with first valid key
    if [ ${#TEST_KEYS[@]} -gt 0 ]; then
        test_rate_limiting "${TEST_KEYS[0]}"
    fi
    
    echo ""
    print_status "--- Advanced Tests ---"
    
    # Test different HTTP methods
    ((total_tests++))
    if test_endpoint "GET Sum Info" "$KONG_PROXY_URL/api/v1/sum" "GET" "" "-H 'apikey: ${TEST_KEYS[0]}'" 200 "Sum Calculation API"; then
        ((passed_tests++))
    fi
    
    # Test with different content types
    ((total_tests++))
    if test_endpoint "Sum with Alternative Key Header" "$KONG_PROXY_URL/api/v1/sum" "POST" '{"numbers":[7,8,9]}' "-H 'X-API-Key: ${TEST_KEYS[1]}'" 200 '"sum":24'; then
        ((passed_tests++))
    fi
    
    # Test input validation
    ((total_tests++))
    if test_endpoint "Invalid Input (Empty Array)" "$KONG_PROXY_URL/api/v1/sum" "POST" '{"numbers":[]}' "-H 'apikey: ${TEST_KEYS[0]}'" 400 "at least 2 numbers"; then
        ((passed_tests++))
    fi
    
    ((total_tests++))
    if test_endpoint "Invalid Input (Single Number)" "$KONG_PROXY_URL/api/v1/sum" "POST" '{"numbers":[42]}' "-H 'apikey: ${TEST_KEYS[0]}'" 400 "at least 2 numbers"; then
        ((passed_tests++))
    fi
    
    echo ""
    print_status "--- Kong Konnect Integration ---"
    
    print_info "Kong configuration is managed through Konnect Dashboard:"
    print_info "  • Services: Configure at https://cloud.konghq.com/"
    print_info "  • Routes: Set up API routing through Konnect UI"
    print_info "  • Plugins: Enable authentication and rate limiting via dashboard"
    print_info "  • Analytics: Real-time metrics available in Konnect"
    
    echo ""
    print_status "=== Test Summary ==="
    print_status "Total tests: $total_tests"
    print_success "Passed: $passed_tests"
    print_error "Failed: $((total_tests - passed_tests))"
    
    local pass_percentage=$((passed_tests * 100 / total_tests))
    
    if [ $pass_percentage -ge 90 ]; then
        print_success "🎉 Excellent! $pass_percentage% tests passed"
    elif [ $pass_percentage -ge 75 ]; then
        print_warning "⚠️  Good! $pass_percentage% tests passed"
    else
        print_error "❌ Issues detected! Only $pass_percentage% tests passed"
    fi
    
    echo ""
    if [ $passed_tests -eq $total_tests ]; then
        print_success "✅ All tests passed! Your Zama API Platform is working perfectly."
        exit 0
    else
        print_error "❌ Some tests failed. Please check the output above for details."
        exit 1
    fi
}

# Cleanup function
cleanup() {
    rm -f /tmp/response.json
}

# Set up cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"
