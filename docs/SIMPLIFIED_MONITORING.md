# Monitoring & Observability Summary

## 🎯 **What's Monitoring Your Go API**

**Pure AWS Infrastructure Approach** - No complex Lambda functions or Synthetics required.

### **Health Endpoint Monitoring**
- ALB automatically checks `/healthz` endpoint every 30 seconds
- CloudWatch alarms monitor ALB target health metrics
- **Email alerts sent within 10 minutes** when your Go app goes down

### **12 Comprehensive Alerts** 

#### 🔴 **CRITICAL** (Service Down)
- **No Healthy Targets**: `/healthz` failing on all instances → Service completely down
- **Unhealthy Tasks**: No ECS tasks running → Infrastructure failure

#### 🟠 **HIGH** (Service Issues) 
- **High Error Rate**: Many 5XX responses → Application errors
- **ALB Unhealthy Targets**: Some health checks failing → Partial degradation
- **API Error Count**: Many ERROR logs → Application-level issues
- **Connection Errors**: ALB can't connect → Network/port issues

#### 🟡 **MEDIUM** (Performance Issues)
- **High Response Time**: API responding slowly (>2s) → Performance degradation
- **Slow Health Response**: Health endpoint slow (>5s) → Service struggling
- **Low Request Count**: No traffic processing → Possible outage
- **High CPU/Memory**: Resource constraints → Need scaling

## 📧 **Email Notifications**
- **Configured email**: `cyril.bourdet.pro@gmail.com`
- **Alert delivery**: 10-15 minutes after issue detected
- **SNS subscription**: Must confirm email subscription to receive alerts

## 📊 **Monitoring Coverage**
- ✅ **Service availability** via ALB health checks
- ✅ **Application performance** via response times and error rates
- ✅ **Infrastructure health** via ECS task and resource metrics
- ✅ **Application errors** via structured log parsing
- ✅ **Network connectivity** via ALB connection metrics

## 🚀 **Deployment**
```bash
cd terraform/environments/dev/observability
terraform apply
```

**Key benefit**: Uses existing AWS infrastructure (ALB health checks) for reliable, simple monitoring without complex dependencies.
