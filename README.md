# Branch Loans Application

A Flask-based loan management application with PostgreSQL database, featuring a complete CI/CD pipeline, monitoring, and multi-environment support.

## Table of Contents
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Local Development Setup](#local-development-setup)
- [Environment Configuration](#environment-configuration)
- [Running the Application](#running-the-application)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring & Observability](#monitoring--observability)
- [Design Decisions](#design-decisions)
- [Troubleshooting](#troubleshooting)

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         Nginx (HTTPS)                       │
│                    branchloans.com:443                      │
│  ┌────────────┬──────────────────┬─────────────────────┐    │
│  │ / (API)    │ /prometheus/     │ /grafana/           │    │
└──┴────────────┴──────────────────┴─────────────────────┴────┘
        │               │                    │
        ▼               ▼                    ▼
   ┌─────────┐   ┌─────────────┐     ┌──────────┐
   │  Flask  │   │ Prometheus  │     │ Grafana  │
   │   API   │   │   :9090     │     │  :3000   │
   │  :8000  │   └─────────────┘     └──────────┘
   └────┬────┘          │                   │
        │               └───────────────────┘
        │                   (Scrapes /metrics)
        ▼
   ┌──────────┐
   │PostgreSQL│
   │  :5432   │
   └──────────┘

GitHub Actions Pipeline:
┌──────────┐    ┌───────────┐    ┌──────────┐    ┌────────┐
│  Build   │───▶│  Docker   │───▶│ Security │───▶│  Push  │
│  & Test  │    │   Build   │    │   Scan   │    │ to Hub │
└──────────┘    └───────────┘    └──────────┘    └────────┘
```

## Prerequisites

- **Docker** (v20.10+) and **Docker Compose** (v2.0+)
- **Python 3.11** (for local development without Docker)
- **Git**
- **OpenSSL** (for SSL certificate generation)
- **Make** (optional, for convenience commands)

## Local Development Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd <repository-name>
```

### 2. Generate SSL Certificates

For local HTTPS access:

```bash
# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout branchloans.key -out branchloans.crt \
  -subj "/CN=branchloans.com"

# Move certificates to ssl directory
mkdir -p ssl
mv branchloans.key branchloans.crt ssl/
```

### 3. Configure Local DNS

Add the following to your `/etc/hosts` file:

```bash
# Linux/Mac
sudo vim /etc/hosts

# Add this line:
127.0.0.1 branchloans.com
```

For macOS, trust the certificate:

```bash
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain ssl/branchloans.crt
```

### 4. Create Environment Files

Create environment-specific `.env` files in the root directory:

#### `.env.development`
```env
# Flask Configuration
FLASK_ENV=production
FLASK_APP=app.py

# Database Configuration
POSTGRES_USER=dev_user
POSTGRES_PASSWORD=dev_password
POSTGRES_DB=branchloans_dev
DATABASE_URL=postgresql+psycopg2://dev_user:dev_password@db:5432/branchloans_dev

# Resource Limits
APP_CPU_LIMIT=1
APP_MEMORY_LIMIT=512m
DB_CPU_LIMIT=1
DB_MEMORY_LIMIT=512m

# Health Check Configuration
HEALTHCHECK_INTERVAL=30s
HEALTHCHECK_TIMEOUT=5s
HEALTHCHECK_RETRIES=3

# Volume Path
DB_VOLUME_PATH=./postgres_data_dev
```

#### `.env.staging`
```env
FLASK_ENV=production
FLASK_APP=app.py

POSTGRES_USER=staging_user
POSTGRES_PASSWORD=staging_password
POSTGRES_DB=branchloans_staging
DATABASE_URL=postgresql+psycopg2://staging_user:staging_password@db:5432/branchloans_staging

APP_CPU_LIMIT=2
APP_MEMORY_LIMIT=1g
DB_CPU_LIMIT=2
DB_MEMORY_LIMIT=1g

HEALTHCHECK_INTERVAL=20s
HEALTHCHECK_TIMEOUT=4s
HEALTHCHECK_RETRIES=4

DB_VOLUME_PATH=./postgres_data_staging
```

#### `.env.production`
```env
FLASK_ENV=production
FLASK_APP=app.py

POSTGRES_USER=prod_user
POSTGRES_PASSWORD=<strong-secure-password>
POSTGRES_DB=branchloans_prod
DATABASE_URL=postgresql+psycopg2://prod_user:<strong-secure-password>@db:5432/branchloans_prod

APP_CPU_LIMIT=4
APP_MEMORY_LIMIT=2g
DB_CPU_LIMIT=4
DB_MEMORY_LIMIT=2g

HEALTHCHECK_INTERVAL=15s
HEALTHCHECK_TIMEOUT=3s
HEALTHCHECK_RETRIES=5

DB_VOLUME_PATH=/var/lib/postgresql/data
```

## Environment Configuration

### Environment Variables Explained

| Variable | Purpose | Example Values |
|----------|---------|----------------|
| `FLASK_ENV` | Flask environment mode | `production`, `development` |
| `FLASK_APP` | Entry point for Flask | `app.py` |
| `POSTGRES_USER` | Database username | `dev_user` |
| `POSTGRES_PASSWORD` | Database password | `secure_password` |
| `POSTGRES_DB` | Database name | `branchloans_dev` |
| `DATABASE_URL` | Full database connection string | `postgresql+psycopg2://...` |
| `APP_CPU_LIMIT` | CPU cores for API container | `1`, `2`, `4` |
| `APP_MEMORY_LIMIT` | Memory limit for API | `512m`, `1g`, `2g` |
| `DB_CPU_LIMIT` | CPU cores for DB container | `1`, `2`, `4` |
| `DB_MEMORY_LIMIT` | Memory limit for DB | `512m`, `1g`, `2g` |
| `HEALTHCHECK_INTERVAL` | Time between health checks | `30s`, `15s` |
| `HEALTHCHECK_TIMEOUT` | Health check timeout | `5s`, `3s` |
| `HEALTHCHECK_RETRIES` | Retries before unhealthy | `3`, `5` |
| `DB_VOLUME_PATH` | PostgreSQL data directory | `./postgres_data_dev` |

### Switching Between Environments

#### Using Docker Compose

```bash
# Development
docker-compose --env-file .env.development up -d

# Staging
docker-compose --env-file .env.staging up -d

# Production
docker-compose --env-file .env.production up -d
```

#### Using Environment Variables

```bash
# Set environment
export ENV=development  # or staging, production

# Run with specific env file
docker-compose --env-file .env.${ENV} up -d
```

## Running the Application

### With Docker (Recommended)

```bash
# Start all services (development)
docker-compose --env-file .env.development up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Stop and remove volumes (CAUTION: Deletes data)
docker-compose down -v
```

### Without Docker (Local Python)

```bash
# Install dependencies
pip install -r requirements.txt

# Set environment variables
export FLASK_APP=app.py
export FLASK_ENV=development
export DATABASE_URL=postgresql+psycopg2://user:pass@localhost:5432/dbname

# Run database migrations (if applicable)
flask db upgrade

# Run the application
python app.py
# OR
gunicorn -w 2 -b 0.0.0.0:8000 wsgi:app
```

### Accessing the Application

Once running, access the services at:

- **API**: `https://branchloans.com/` (or `http://localhost:8000`)
- **Health Check**: `https://branchloans.com/health`
- **DB Health Check**: `https://branchloans.com/health-db`
- **Metrics**: `https://branchloans.com/metrics`
- **Prometheus**: `https://branchloans.com/prometheus/`
- **Grafana**: `https://branchloans.com/grafana/` (default: admin/admin)

## CI/CD Pipeline

### Pipeline Architecture

The project uses **two separate workflows**:

#### 1. CI Pipeline (Pull Requests)
**File**: `.github/workflows/ci.yml`

Triggers on: Pull requests to `main`, `development`, `master`, `production`, `staging`

**Jobs**:
1. **Build & Test** - Installs dependencies and runs tests
2. **Lint** - Code quality checks (placeholder for Black/Flake8)
3. **Docker Build** - Validates Dockerfile builds successfully

```
Pull Request → Build → Lint → Docker Build → Ready to Merge
```

#### 2. CD Pipeline (Deployments)
**File**: `.github/workflows/cd.yml`

Triggers on: Push to `main`, `development`, `master`, `production`, `staging`

**Jobs**:
1. **Test-and-build** - Runs test suite
2. **Dockerimg-Build** - Builds Docker image with environment-specific args
3. **Security-Scan** - Scans image with Trivy for vulnerabilities
4. **Push-to-Docker-Hub** - Pushes image to Docker Hub with tags

```
Push to Branch → Test → Build Image → Security Scan → Push to Registry
                                          ↓
                                   (Fails on CRITICAL/HIGH)
```

### How It Works

#### Multi-Stage Docker Build

The Dockerfile uses a **multi-stage build** for optimization:

**Stage 1 (Builder)**:
- Installs build dependencies
- Compiles Python packages
- Creates isolated `/install` directory

**Stage 2 (Runtime)**:
- Uses slim Python image
- Copies only compiled packages from builder
- Minimal attack surface and smaller image size

**Build Arguments**:
- `FLASK_ENV`: Application environment
- `HEALTHCHECK_INTERVAL`: Time between health checks
- `HEALTHCHECK_TIMEOUT`: Maximum time for health check
- `HEALTHCHECK_RETRIES`: Number of retries before marking unhealthy

#### Environment-Specific Configuration

The CD pipeline automatically configures builds based on the branch:

| Branch | Environment | Healthcheck Interval | CPU/Memory |
|--------|-------------|---------------------|------------|
| `development`/`main` | Development | 30s / 5s / 3 retries | 1 CPU / 512MB |
| `staging` | Staging | 20s / 4s / 4 retries | 2 CPU / 1GB |
| `production`/`master` | Production | 15s / 3s / 5 retries | 4 CPU / 2GB |

#### Security Scanning

**Trivy** scans for:
- Known CVEs in dependencies
- Misconfigurations
- Exposed secrets

**Configuration**:
- Fails on: `CRITICAL` and `HIGH` severity
- Ignores: Unfixed vulnerabilities (to reduce noise)
- Format: Table output for readability

#### Docker Hub Tagging

Images are tagged with:
- **Commit SHA**: `username/repo-branch:abc123`
- **Latest**: `username/repo-branch:latest`

Example: `dockeruser/branchloans-development:a1b2c3d` and `dockeruser/branchloans-development:latest`

### Required GitHub Secrets

Configure these in your repository settings (Settings → Secrets and variables → Actions):

**Secrets**:
```
DOCKER_USERNAME              # Docker Hub username
DOCKER_PASSWORD              # Docker Hub access token

# Development
POSTGRES_USER_DEVELOPMENT
POSTGRES_PASSWORD_DEVELOPMENT
POSTGRES_DB_DEVELOPMENT
DB_VOLUME_PATH_DEVELOPMENT

# Staging
POSTGRES_USER_STAGING
POSTGRES_PASSWORD_STAGING
POSTGRES_DB_STAGING
DB_VOLUME_PATH_STAGING

# Production
POSTGRES_USER_PRODUCTION
POSTGRES_PASSWORD_PRODUCTION
POSTGRES_DB_PRODUCTION
DB_VOLUME_PATH_PRODUCTION
```

**Variables** (Settings → Secrets and variables → Actions → Variables):
```
# Development
HEALTHCHECK_INTERVAL_DEVELOPMENT=30s
HEALTHCHECK_TIMEOUT_DEVELOPMENT=5s
HEALTHCHECK_RETRIES_DEVELOPMENT=3
APP_CPU_LIMIT_DEVELOPMENT=1
APP_MEMORY_LIMIT_DEVELOPMENT=512m
DB_CPU_LIMIT_DEVELOPMENT=1
DB_MEMORY_LIMIT_DEVELOPMENT=512m

# Staging
HEALTHCHECK_INTERVAL_STAGING=20s
HEALTHCHECK_TIMEOUT_STAGING=4s
HEALTHCHECK_RETRIES_STAGING=4
APP_CPU_LIMIT_STAGING=2
APP_MEMORY_LIMIT_STAGING=1g
DB_CPU_LIMIT_STAGING=2
DB_MEMORY_LIMIT_STAGING=1g

# Production
HEALTHCHECK_INTERVAL_PRODUCTION=15s
HEALTHCHECK_TIMEOUT_PRODUCTION=3s
HEALTHCHECK_RETRIES_PRODUCTION=5
APP_CPU_LIMIT_PRODUCTION=4
APP_MEMORY_LIMIT_PRODUCTION=2g
DB_CPU_LIMIT_PRODUCTION=4
DB_MEMORY_LIMIT_PRODUCTION=2g
```

## Monitoring & Observability

### Health Checks

#### Application Health (`/health`)
Basic liveness check - returns 200 if the application is running.

```bash
curl https://branchloans.com/health
```

#### Database Health (`/health-db`)
Validates database connectivity by executing `SELECT 1`.

**Features**:
- Measures query execution time
- Structured JSON logging with request ID
- Returns 500 on database connection failure

```bash
curl https://branchloans.com/health-db
```

**Response**:
```json
{
  "status": "Connection Successfully Established with the Database in 0.0234 seconds"
}
```

### Structured Logging

The application uses **structured JSON logging** for better observability:

**Features**:
- Unique request ID per request (`X-Request-ID` header or auto-generated UUID)
- ISO 8601 timestamps with UTC timezone
- Key-value pairs for easy parsing
- Request context preservation

**Log Format**:
```json
{
  "timestamp": "2025-11-15T10:30:45.123456Z",
  "request_id": "550e8400-e29b-41d4-a716-446655440000",
  "message": "DB health check success",
  "duration": "0.0234s"
}
```

**Usage in Code**:
```python
from logger import log, setup_request_context

# In before_request
setup_request_context()

# Anywhere in your code
log("User authenticated", user_id=user.id, method="oauth")
log("Database query slow", query_time=2.5, query="SELECT * FROM users", level="warning")
```

### Prometheus Metrics

Metrics are exposed at `/metrics` and scraped by Prometheus.

**Access Prometheus UI**: `https://branchloans.com/prometheus/`

### Grafana Dashboards

**Access Grafana**: `https://branchloans.com/grafana/`

**Default Credentials**: `admin` / `admin` (change on first login)

**Available Dashboards**:
- Application performance metrics
- Database query performance
- Resource utilization (CPU, memory)
- Request rates and latencies

## Design Decisions

### Why Multi-Stage Docker Build?

**Trade-offs Considered**:
- ✅ **Smaller image size**: ~60% reduction by excluding build tools
- ✅ **Security**: Reduced attack surface with fewer binaries
- ✅ **Build speed**: Layer caching speeds up rebuilds
- ❌ **Complexity**: Slightly more complex Dockerfile
- ❌ **Debugging**: Harder to debug issues in production image

**Decision**: Multi-stage build chosen for production readiness and security benefits.

### Why Separate CI/CD Workflows?

**Trade-offs Considered**:
- ✅ **Fast feedback**: CI runs on PRs without deployment overhead
- ✅ **Clear separation**: Different triggers and purposes
- ✅ **Resource efficiency**: Don't push images for every PR
- ❌ **Duplication**: Some job definitions duplicated
- ❌ **Maintenance**: Two files to maintain

**Decision**: Separation provides better developer experience and clearer intent.

### Why Trivy for Security Scanning?

**Alternatives Considered**:
- **Snyk**: Better UI, but requires external account
- **Grype**: Similar features, but less GitHub Actions support
- **Clair**: More complex setup

**Decision**: Trivy is free, open-source, and well-integrated with GitHub Actions.

### Why Structured Logging?

**Trade-offs Considered**:
- ✅ **Machine-readable**: Easy to parse and aggregate
- ✅ **Request tracing**: Correlation across distributed systems
- ✅ **Debugging**: Rich context for troubleshooting
- ❌ **Readability**: Less human-friendly than plain text
- ❌ **Overhead**: Slightly more verbose

**Decision**: JSON logging is standard for production applications and enables powerful observability.

### Why Nginx Reverse Proxy?

**Trade-offs Considered**:
- ✅ **SSL termination**: Centralized HTTPS handling
- ✅ **Service routing**: Single entry point for multiple services
- ✅ **Performance**: Better at serving static content than Flask
- ❌ **Complexity**: Additional service to manage
- ❌ **Single point of failure**: If Nginx fails, everything is down

**Decision**: Industry standard for production deployments, worth the complexity.

## What Would I Improve With More Time?

### 1. Automated Testing
- **Current**: Placeholder test steps
- **Improvement**: 
  - Unit tests with pytest
  - Integration tests for database operations
  - API contract tests
  - Test coverage reporting (>80% target)

### 2. Database Migrations
- **Current**: Manual schema management
- **Improvement**:
  - Alembic/Flask-Migrate for version-controlled migrations
  - Automated migration runs in CI/CD
  - Rollback strategies

### 3. Secrets Management
- **Current**: GitHub Secrets
- **Improvement**:
  - HashiCorp Vault or AWS Secrets Manager
  - Secret rotation policies
  - Environment-specific secret injection

### 4. Advanced Monitoring
- **Current**: Basic metrics and logs
- **Improvement**:
  - Distributed tracing (Jaeger/Zipkin)
  - Error tracking (Sentry)
  - Custom business metrics dashboards
  - Alerting rules in Prometheus

### 5. High Availability
- **Current**: Single instance per service
- **Improvement**:
  - Load balancing across multiple API instances
  - Database replication (primary-replica)
  - Redis for caching and session management
  - Auto-scaling based on metrics

### 6. Blue-Green Deployments
- **Current**: Direct deployment
- **Improvement**:
  - Zero-downtime deployments
  - Automated rollback on health check failures
  - Canary deployments for gradual rollouts

### 7. Code Quality
- **Current**: Placeholder linting
- **Improvement**:
  - Black for formatting
  - Flake8 for linting
  - MyPy for type checking
  - Pre-commit hooks

### 8. Documentation
- **Current**: This README
- **Improvement**:
  - API documentation (Swagger/OpenAPI)
  - Architecture decision records (ADRs)
  - Runbooks for common operational tasks
  - Video walkthroughs

## Troubleshooting

### Common Issues

#### 1. "Connection refused" when accessing https://branchloans.com

**Symptoms**:
```
curl: (7) Failed to connect to branchloans.com port 443: Connection refused
```

**Solutions**:
```bash
# Check if containers are running
docker-compose ps

# Check nginx logs
docker-compose logs nginx

# Verify /etc/hosts entry
cat /etc/hosts | grep branchloans.com

# Restart services
docker-compose restart nginx
```

#### 2. Database connection errors

**Symptoms**:
```json
{"status": "Database connection error"}
```

**Solutions**:
```bash
# Check database container
docker-compose ps db

# Check database logs
docker-compose logs db

# Verify environment variables
docker-compose exec api env | grep DATABASE_URL

# Test database connectivity
docker-compose exec db psql -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT 1;"

# Restart database
docker-compose restart db
```

#### 3. "SSL certificate problem" errors

**Symptoms**:
```
curl: (60) SSL certificate problem: self signed certificate
```

**Solutions**:
```bash
# Option 1: Use -k flag to skip verification (development only)
curl -k https://branchloans.com/health

# Option 2: Trust the certificate (macOS)
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain ssl/branchloans.crt

# Option 3: Use localhost with HTTP
curl http://localhost:8000/health
```

#### 4. Docker build fails with "no space left on device"

**Symptoms**:
```
Error: failed to copy files: no space left on device
```

**Solutions**:
```bash
# Clean up Docker resources
docker system prune -a --volumes

# Check disk space
df -h

# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune
```

#### 5. Port already in use

**Symptoms**:
```
Error: bind: address already in use
```

**Solutions**:
```bash
# Find process using port 8000
lsof -i :8000
# OR
netstat -tulpn | grep 8000

# Kill the process
kill -9 <PID>

# Or use different port in docker-compose.yml
ports:
  - "8001:8000"
```

#### 6. GitHub Actions pipeline fails

**Symptoms**:
- Workflow shows red X
- Security scan fails
- Push to Docker Hub fails

**Solutions**:
```bash
# Check workflow logs in GitHub Actions tab

# For security scan failures:
# - Review Trivy output for vulnerable dependencies
# - Update requirements.txt with patched versions
# - Consider ignoring specific CVEs if no fix is available

# For Docker Hub push failures:
# - Verify DOCKER_USERNAME and DOCKER_PASSWORD secrets
# - Check Docker Hub login:
docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD

# For test failures:
# - Run tests locally: pytest
# - Check DATABASE_URL in GitHub Secrets
```

#### 7. Grafana shows "No data"

**Symptoms**:
- Dashboards display "No data" or "N/A"

**Solutions**:
```bash
# Check Prometheus is scraping metrics
# Visit: https://branchloans.com/prometheus/targets

# Verify metrics endpoint is accessible
curl https://branchloans.com/metrics

# Check Prometheus configuration
docker-compose exec prometheus cat /etc/prometheus/prometheus.yml

# Restart Prometheus
docker-compose restart prometheus grafana
```

### Verification Commands

#### Check All Services Are Running
```bash
docker-compose ps

# Expected output: All services should be "Up"
# NAME                COMMAND                  SERVICE     STATUS
# app                 "gunicorn..."           api         Up
# db                  "docker-entrypoint..."  db          Up
# nginx               "nginx..."              nginx       Up
# prometheus          "prometheus..."         prometheus  Up
# grafana             "grafana..."            grafana     Up
```

#### Test API Endpoints
```bash
# Health check
curl -k https://branchloans.com/health
# Expected: {"status": "healthy"}

# Database health check
curl -k https://branchloans.com/health-db
# Expected: {"status": "Connection Successfully Established..."}

# Metrics
curl -k https://branchloans.com/metrics
# Expected: Prometheus metrics output
```

#### Check Logs
```bash
# All services
docker-compose logs

# Specific service
docker-compose logs api
docker-compose logs db
docker-compose logs nginx

# Follow logs in real-time
docker-compose logs -f api

# Last 100 lines
docker-compose logs --tail=100 api
```

#### Database Connection Test
```bash
# Connect to database
docker-compose exec db psql -U $POSTGRES_USER -d $POSTGRES_DB

# Inside psql:
\dt        # List tables
\l         # List databases
\q         # Quit
```

#### Resource Usage
```bash
# Check container resource usage
docker stats

# Check disk usage
docker system df

# Check specific container
docker inspect api | grep -A 10 "Memory"
```

### Getting Help

If you encounter issues not covered here:

1. **Check logs**: `docker-compose logs [service_name]`
2. **Verify environment**: Ensure correct `.env` file is being used
3. **Review GitHub Actions**: Check workflow logs for CI/CD issues
4. **Check documentation**: Review relevant sections of this README
5. **Search issues**: Check the repository's issue tracker

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make changes and commit: `git commit -am 'Add new feature'`
4. Push to branch: `git push origin feature/my-feature`
5. Create a Pull Request
