# GitHub Actions CI/CD Workflows

This directory contains the GitHub Actions workflows for the Zama API Platform Challenge project. These workflows implement comprehensive CI/CD pipelines covering testing, building, security scanning, infrastructure management, and deployment.

## 🚀 Workflows Overview

### 1. CI - Go API Service (`ci.yml`)

**Triggers:**
- Push to `main` or `develop` branches (when API service files change)
- Pull requests to `main` (when API service files change)

**Jobs:**
- **test**: Runs Go tests, linting, formatting, security scans
- **integration**: Builds and runs integration tests
- **security**: Trivy vulnerability scanning

**Features:**
- Go 1.21 support with caching
- golangci-lint for code quality
- gosec for security scanning
- Race condition detection
- Coverage reporting with Codecov
- Trivy security scanning

### 2. Docker Build & Push (`docker.yml`)

**Triggers:**
- Push to `main` (when API service files change)
- Git tags starting with `v*`
- Pull requests to `main`
- Manual workflow dispatch

**Jobs:**
- **docker**: Docker build for linux/amd64 platform
- **security-scan**: Container security scanning with Grype
- **update-deployment**: Automatic ECS service updates

**Features:**
- Docker Hub integration (`flentier/demo-go-api-kong`)
- Linux AMD64 platform builds
- Semantic versioning support
- Container vulnerability scanning
- Automatic ECS deployment on main branch

### 3. Terraform Infrastructure (`terraform.yml`)

**Triggers:**
- Push to `main` (when Terraform files change)
- Pull requests to `main`
- Manual workflow dispatch with environment selection

**Jobs:**
- **terraform-check**: Format validation, module validation, security scanning
- **terraform-plan**: Generate and save Terraform plans
- **terraform-apply**: Apply infrastructure changes
- **terraform-destroy**: Destroy infrastructure (manual only)

**Features:**
- Multi-environment support (dev/staging/prod)
- **Manual approval required** for all applies (no automatic deployments)
- Terraform state management with S3 backend
- Security scanning with tfsec and Checkov
- Plan artifacts and PR comments
- Infrastructure graph generation
- GitHub Environment protection integration

### 4. Integration Tests (`integration-test.yml`)

**Triggers:**
- Push to `main` or `develop`
- Pull requests to `main`
- Manual workflow dispatch with test type selection

**Jobs:**
- **integration-tests**: API service integration tests
- **kong-integration-tests**: Kong Gateway integration tests
- **performance-tests**: Load testing with k6
- **test-summary**: Aggregated test results

**Features:**
- Kong Gateway testing with PostgreSQL
- Load testing with k6
- Security testing
- Performance benchmarking
- Test result artifacts

### 5. Deploy to AWS (`deploy.yml`)

**Triggers:**
- Manual workflow dispatch only (controlled deployments)

**Jobs:**
- **pre-deployment-checks**: Validation and AWS connectivity
- **build-and-push**: Build and push Docker images
- **deploy-infrastructure**: Deploy/update AWS infrastructure
- **deploy-application**: Update ECS services
- **post-deployment-tests**: Verify deployment health
- **deployment-summary**: Generate deployment report

**Features:**
- Environment selection (dev/staging/prod)
- Selective deployment (infrastructure/application)
- Post-deployment verification
- Deployment summaries with links
- AWS ECS integration

### 6. Kong Konnect Integration Tests (`kong-konnect-test.yml`)

**Triggers:**
- Push to `main` or `develop`
- Pull requests to `main`
- Manual workflow dispatch with test type selection

**Jobs:**
- **kong-health-test**: Test health endpoints without authentication
- **kong-auth-test**: Test API key authentication (valid/invalid)
- **kong-rate-limit-test**: Test rate limiting with 11 requests
- **kong-comprehensive-test**: Aggregate results and summary

**Features:**
- Real Kong Konnect endpoint testing
- Rate limiting validation (should hit limit after ~10 requests)
- Authentication testing with your API key format
- Comprehensive test reporting

### 7. Security Validation (`security-validation.yml`)

**Triggers:**
- Push to `main` or `develop`
- Pull requests to `main`
- Manual workflow dispatch with environment selection

**Jobs:**
- **security-endpoint-validation**: Test direct ALB access is blocked
- **network-security-scan**: Port scanning and network security validation

**Features:**
- **Critical Security Test**: Validates direct API access on port 8080 is blocked
- **Network Security Scanning**: Port scanning with nmap
- **Automatic ALB Discovery**: Finds ALB endpoints from AWS
- **Security Reporting**: Comprehensive security validation reports
- **Post-deployment Integration**: Runs as part of deployment validation

## 🔧 Setup Requirements

### Required GitHub Secrets

```bash
# Docker Hub (Public Repository: flentier/demo-go-api-kong)
DOCKERHUB_USERNAME=flentier
DOCKERHUB_TOKEN=<your-docker-hub-token>

# AWS Credentials (see docs/AWS_CREDENTIALS_SETUP.md for details)
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE          # Starts with "AKIA"
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG...  # 40-character string
AWS_REGION=us-west-2

# Terraform State
TF_STATE_BUCKET=<your-terraform-state-bucket>

# Kong Konnect Integration
KONG_API_KEY=test-user-bob:BOB-API-KEY-123
KONG_ENDPOINT=http://kong-4994957fd2euqcpzn.kongcloud.dev
```

### Optional Secrets

```bash
# For enhanced coverage reporting
CODECOV_TOKEN=<your-codecov-token>
```

## 🎯 Workflow Dependencies

```mermaid
graph TD
    A[Code Push] --> B[CI Workflow]
    B --> C[Docker Build]
    C --> D[Integration Tests]
    
    E[Manual Deploy] --> F[Pre-deployment Checks]
    F --> G[Build & Push]
    F --> H[Deploy Infrastructure]
    G --> I[Deploy Application]
    H --> I
    I --> J[Post-deployment Tests]
    
    K[PR] --> L[Terraform Plan]
    L --> M[Comment on PR]
```

## 📋 Usage Examples

### Automatic Workflows

```bash
# Trigger CI on push
git push origin main

# Trigger Docker build on tag
git tag v1.0.0
git push origin v1.0.0

# Trigger Terraform plan on PR
# (Automatically runs when PR contains Terraform changes)
```

### Manual Workflows

```bash
# Deploy to development environment
# Go to Actions tab → Deploy to AWS → Run workflow
# Select: environment=dev, deploy_infrastructure=true, deploy_application=true

# Run specific integration tests
# Go to Actions tab → Integration Tests → Run workflow
# Select: test_type=api, environment=local

# Build specific Docker tag
# Go to Actions tab → Docker Build & Push → Run workflow
# Select: tag=v1.2.3, push=true
```

## 🛡️ Security Features

### Code Security
- **gosec**: Go security scanner
- **golangci-lint**: Code quality and security linting
- **Trivy**: Container and filesystem vulnerability scanning
- **Grype**: Additional container security scanning

### Infrastructure Security
- **tfsec**: Terraform security scanning
- **Checkov**: Infrastructure as Code security analysis
- **SARIF uploads**: Security results uploaded to GitHub Security tab
- **Manual approval required**: No automatic infrastructure deployments
- **GitHub Environment protection**: Multi-reviewer approval process
- **Pre-deployment validation**: Confirmation steps before apply

### Container Security
- **Multi-stage builds**: Minimal runtime images
- **Non-root user**: Containers run as non-privileged user
- **Vulnerability scanning**: Automated security scanning
- **Platform-specific builds**: Linux AMD64 only for consistency

### Deployment Security
- **Manual triggers only**: Terraform apply requires explicit manual trigger
- **Environment isolation**: Separate environments with different protection levels
- **Audit trails**: Full deployment history and approval records
- **Wait timers**: Cooling-off periods for production deployments

## 📊 Monitoring & Observability

### Workflow Monitoring
- **Job summaries**: Detailed results in GitHub Actions UI
- **Artifact uploads**: Test results, plans, graphs
- **PR comments**: Terraform plans automatically commented
- **Deployment URLs**: Direct links to deployed applications

### Application Monitoring
- **Health checks**: Automated health endpoint testing
- **Performance tests**: Load testing with k6
- **Metrics collection**: Prometheus metrics endpoint testing
- **AWS integration**: ECS service monitoring

## 🔄 Deployment Strategies

### Development Environment
- **Automatic**: Deploys on every push to main
- **Fast feedback**: Quick deployment with basic testing
- **Feature testing**: Full integration test suite

### Staging Environment
- **Manual trigger**: Controlled deployments
- **Full testing**: Complete test suite including load tests
- **Production preview**: Mirror of production environment

### Production Environment
- **Manual approval**: Requires manual workflow dispatch
- **Blue/green ready**: ECS service updates with zero downtime
- **Rollback capable**: Easy rollback via ECS service history

## 🚨 Troubleshooting

### Common Issues

1. **Docker Hub authentication failed**
   ```bash
   # Check secrets are correctly set
   # DOCKERHUB_USERNAME and DOCKERHUB_TOKEN
   ```

2. **AWS permissions denied**
   ```bash
   # Verify AWS credentials have sufficient permissions
   # Check IAM policies for ECS, ALB, VPC access
   ```

3. **Terraform state lock**
   ```bash
   # Manual state unlock may be needed
   terraform force-unlock <lock-id>
   ```

4. **ECS deployment timeout**
   ```bash
   # Check ECS service events in AWS Console
   # Verify security groups and networking
   ```

### Debug Commands

```bash
# Check workflow runs
gh run list --workflow=ci.yml

# View workflow logs
gh run view <run-id> --log

# Re-run failed workflow
gh run rerun <run-id>
```

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Build & Push Action](https://github.com/docker/build-push-action)
- [Terraform GitHub Actions](https://github.com/hashicorp/setup-terraform)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)

## 🎯 Best Practices Implemented

1. **Fail Fast**: Early validation and quick feedback
2. **Security First**: Multiple security scanning layers
3. **Reproducible**: Pinned tool versions and caching
4. **Observable**: Comprehensive logging and artifacts
5. **Scalable**: Environment-based configuration
6. **Maintainable**: Clear documentation and modular workflows

---

**Note**: These workflows are designed for the Zama API Platform Challenge and demonstrate production-ready CI/CD practices with comprehensive testing, security scanning, and deployment automation.
