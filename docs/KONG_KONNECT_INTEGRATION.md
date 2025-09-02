# Kong Konnect Integration Guide

This document explains how to integrate the deployed ECS Fargate API service with Kong Konnect's serverless gateways.

## Overview

Kong Konnect provides serverless API gateways where Kong hosts both the control plane and data plane gateways. This eliminates the need to run Kong containers in our infrastructure while still providing enterprise-grade API management capabilities.

## Architecture

```
Internet → Kong Konnect Serverless Gateway → AWS ALB → ECS Fargate (API Service)
```

## Prerequisites

1. Kong Konnect account (sign up at https://cloud.konghq.com/)
2. Deployed ECS Fargate infrastructure via Terraform
3. API service accessible via Application Load Balancer

## Kong Konnect Configuration Steps

### 1. Get Your API Service URL

After deploying the Terraform infrastructure, get the API service URL:

```bash
cd terraform/environments/dev
terraform output api_direct_url
```

Example output: `http://zama-api-platform-dev-alb-1234567890.eu-west-1.elb.amazonaws.com:8080`

### 2. Create a Service in Kong Konnect

1. Log into Kong Konnect dashboard
2. Navigate to "Gateway Manager" → "Services"
3. Click "New Service"
4. Configure:
   - **Name**: `zama-api-service`
   - **URL**: Use the ALB URL from step 1
   - **Protocol**: `http`
   - **Host**: ALB DNS name (without http://)
   - **Port**: `8080`
   - **Path**: `/`

### 3. Create Routes

Create the following routes in Kong Konnect:

#### Health Check Route (Public)
- **Name**: `api-health-route`
- **Service**: `zama-api-service`
- **Protocols**: `http`, `https`
- **Methods**: `GET`
- **Paths**: `/healthz`, `/healthz/live`, `/healthz/ready`
- **Strip Path**: `false`
- **Preserve Host**: `false`

#### Main API Route (Protected)
- **Name**: `api-main-route`
- **Service**: `zama-api-service`
- **Protocols**: `http`, `https`
- **Methods**: `GET`, `POST`, `PUT`, `DELETE`
- **Paths**: `/api`
- **Strip Path**: `false`
- **Preserve Host**: `false`

### 4. Configure Authentication

1. Navigate to "Gateway Manager" → "Consumers"
2. Create a new consumer:
   - **Username**: `demo-client`
   - **Custom ID**: `demo-client-001`

3. Add API Key to the consumer:
   - Go to the consumer details
   - Click "Credentials" → "Key Authentication"
   - Add key: `demo-api-key-12345`

4. Enable Key Authentication on the protected route:
   - Go to "Gateway Manager" → "Routes" → `api-main-route`
   - Click "Plugins" → "Add Plugin"
   - Select "Key Authentication"
   - Configure:
     - **Key Names**: `X-API-Key`, `apikey`
     - **Key in Header**: `true`
     - **Key in Query**: `true`
     - **Hide Credentials**: `false`

### 5. Configure Rate Limiting

1. Go to the protected route (`api-main-route`)
2. Add "Rate Limiting" plugin:
   - **Minute**: `100`
   - **Hour**: `1000`
   - **Policy**: `local`
   - **Fault Tolerant**: `true`
   - **Hide Client Headers**: `false`

### 6. Configure Logging and Monitoring

1. Add "HTTP Log" plugin to routes for request/response logging
2. Enable "Prometheus" plugin for metrics collection
3. Configure "Datadog" or "New Relic" plugins if using external monitoring

## Testing the Integration

### Direct API Access (Bypass Kong)
```bash
# Health check
curl -X GET http://your-alb-dns:8080/healthz

# Sum endpoint (direct)
curl -X POST http://your-alb-dns:8080/api/v1/sum \
  -H 'Content-Type: application/json' \
  -d '{"numbers": [1, 2, 3, 4, 5]}'
```

### Via Kong Konnect Gateway
```bash
# Get your Kong Konnect gateway URL from the dashboard
KONG_GATEWAY_URL="https://your-gateway.us.cp0.konghq.com"

# Health check (no auth required)
curl -X GET $KONG_GATEWAY_URL/healthz

# Sum endpoint (requires API key)
curl -X POST $KONG_GATEWAY_URL/api/v1/sum \
  -H 'X-API-Key: demo-api-key-12345' \
  -H 'Content-Type: application/json' \
  -d '{"numbers": [1, 2, 3, 4, 5]}'
```

## Security Considerations

### 1. Network Security
- The ECS Fargate service is deployed in private subnets
- Only the ALB is internet-facing
- Security groups restrict access to necessary ports only
- Kong Konnect provides additional security layers

### 2. API Key Management
- API keys are stored in AWS Secrets Manager
- Kong Konnect manages API key validation
- Consider rotating API keys regularly
- Use different keys for different environments

### 3. SSL/TLS
- Kong Konnect provides SSL termination
- Configure custom domains with SSL certificates
- Force HTTPS for production traffic

## Monitoring and Observability

### 1. Kong Konnect Analytics
- Built-in analytics dashboard
- Request/response metrics
- Error rate monitoring
- Performance insights

### 2. AWS CloudWatch Integration
- ECS service metrics
- ALB metrics
- Custom application metrics
- Log aggregation

### 3. Alerting
- Kong Konnect alerts for high error rates
- AWS CloudWatch alarms for infrastructure issues
- Integration with PagerDuty, Slack, etc.

## Production Considerations

### 1. High Availability
- Kong Konnect provides built-in HA
- Deploy API service across multiple AZs
- Configure auto-scaling policies

### 2. Performance
- Kong Konnect global edge locations
- Caching strategies
- Connection pooling
- Rate limiting tuning

### 3. Compliance
- Kong Konnect SOC 2 compliance
- Data residency requirements
- Audit logging
- GDPR considerations

## Troubleshooting

### Common Issues

1. **Service Not Reachable**
   - Check ALB health checks
   - Verify security group rules
   - Ensure ECS tasks are running

2. **Authentication Failures**
   - Verify API key configuration
   - Check consumer setup
   - Validate plugin configuration

3. **Rate Limiting Issues**
   - Review rate limiting policies
   - Check consumer quotas
   - Monitor usage patterns

### Debugging Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster zama-api-platform-dev-cluster --services zama-api-platform-dev-api-service

# Check ALB target health
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:...

# Check Kong Konnect service status via Admin API
curl -X GET https://your-admin-api.konghq.com/services/zama-api-service
```

## Next Steps

1. Set up custom domain for Kong Konnect gateway
2. Configure SSL certificates
3. Implement advanced rate limiting strategies
4. Set up comprehensive monitoring and alerting
5. Configure backup and disaster recovery procedures

## Resources

- [Kong Konnect Documentation](https://docs.konghq.com/konnect/)
- [Kong Gateway Plugin Hub](https://docs.konghq.com/hub/)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
