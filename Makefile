.PHONY: help build up down logs logs-backend logs-nginx logs-jenkins clean demo status rebuild restart health test

# Color codes for output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Default target
help:
	@echo "$(CYAN)"
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║  Lightweight Distributed Backend Platform - Make Commands  ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
	@echo "$(NC)"
	@echo "$(GREEN)Development Commands:$(NC)"
	@echo "  make build              Build all Docker images"
	@echo "  make up                 Start services in the background"
	@echo "  make down               Stop services cleanly"
	@echo "  make restart            Restart the platform"
	@echo "  make rebuild            Rebuild images and restart"
	@echo ""
	@echo "$(GREEN)Monitoring & Debugging:$(NC)"
	@echo "  make logs               Stream logs from all services"
	@echo "  make logs-backend       Stream backend logs"
	@echo "  make logs-nginx         Stream NGINX logs"
	@echo "  make status             Show current service status"
	@echo "  make health             Run health endpoint checks"
	@echo ""
	@echo "$(GREEN)Testing & Demonstration:$(NC)"
	@echo "  make test               Validate the main endpoint"
	@echo "  make demo               Demonstrate load balancing"
	@echo ""
	@echo "$(GREEN)Maintenance:$(NC)"
	@echo "  make clean              Stop services and remove volumes"
	@echo "  make shell-backend1     Open shell on backend1"
	@echo "  make shell-backend2     Open shell on backend2"
	@echo "  make shell-nginx        Open shell on nginx-lb"
	@echo ""
	@echo "$(GREEN)Information:$(NC)"
	@echo "  make help               Show this message"
	@echo ""

# Build Docker images
build:
	@echo "$(CYAN)Building Docker images...$(NC)"
	docker compose build --parallel backend1 backend2
	@echo "$(GREEN)✓ Build complete$(NC)"

# Start services in background
up:
	@echo "$(CYAN)Starting services...$(NC)"
	docker compose up -d
	@echo "$(YELLOW)Waiting for services to initialize...$(NC)"
	sleep 5
	@echo "$(GREEN)✓ Services started$(NC)"
	@echo ""
	@$(MAKE) status

# Stop services
down:
	@echo "$(CYAN)Stopping services...$(NC)"
	docker compose down --remove-orphans
	@echo "$(GREEN)✓ Services stopped$(NC)"

# Restart services
restart: down up

# Clean rebuild
rebuild:
	@$(MAKE) down
	@echo "$(CYAN)Rebuilding images...$(NC)"
	docker compose build --no-cache --parallel backend1 backend2
	@$(MAKE) up
	@echo "$(GREEN)✓ Clean rebuild complete$(NC)"

# View logs from all services
logs:
	docker compose logs -f

# View backend logs
logs-backend:
	docker compose logs -f backend1 backend2

# View NGINX logs
logs-nginx:
	docker compose logs -f nginx

# Show service status
status:
	@echo "$(CYAN)Service Status:$(NC)"
	@docker compose ps
	@echo ""
	@echo "$(CYAN)Network Configuration:$(NC)"
	@docker network inspect app-network 2>/dev/null | grep -A 20 "Containers" || echo "Network not found"

# Test health endpoints
health:
	@echo "$(CYAN)Testing Health Endpoints:$(NC)"
	@echo ""
	@echo "$(YELLOW)→ Backend 1 (direct):$(NC)"
	@curl -s http://localhost:8081/health || echo "$(RED)Connection failed$(NC)"
	@echo ""
	@echo "$(YELLOW)→ Backend 2 (direct):$(NC)"
	@curl -s http://localhost:8082/health || echo "$(RED)Connection failed$(NC)"
	@echo ""
	@echo "$(YELLOW)→ NGINX Load Balancer:$(NC)"
	@curl -s http://localhost:8080/health || echo "$(RED)Connection failed$(NC)"
	@echo ""

# Run basic tests
test: health
	@echo "$(CYAN)Testing Main Endpoint:$(NC)"
	@echo ""
	@curl -s http://localhost:8080/ | head -10 || echo "$(RED)Connection failed$(NC)"
	@echo ""

# Demonstrate load balancing
demo:
	@echo "$(CYAN)═══════════════════════════════════════════════════════$(NC)"
	@echo "$(CYAN)  Load Balancing Demonstration$(NC)"
	@echo "$(CYAN)═══════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "Making 10 requests through NGINX (expect round-robin):"
	@echo ""
	@for i in {1..10}; do \
		echo "$(YELLOW)Request $$i:$(NC)"; \
		curl -s http://localhost:8080/ 2>/dev/null | grep -A 5 "Lightweight" | head -6 || echo "$(RED)Error$(NC)"; \
		echo ""; \
	done
	@echo "$(GREEN)✓ Demonstration complete$(NC)"

# Clean up
clean:
	@echo "$(CYAN)Cleaning up...$(NC)"
	@docker compose down --volumes --remove-orphans 2>/dev/null || true
	@docker volume prune -f 2>/dev/null || true
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

# Shell access
shell-backend1:
	docker exec -it backend1 /bin/bash

shell-backend2:
	docker exec -it backend2 /bin/bash

shell-nginx:
	docker exec -it nginx-lb /bin/sh

# Development workflow
.PHONY: dev
dev: build up logs

# Jenkins integration (optional)
.PHONY: jenkins-build
jenkins-build:
	@echo "$(CYAN)Preparing for Jenkins build...$(NC)"
	@echo "Run this job in Jenkins:"
	@echo "  1. Create a new Pipeline job"
	@echo "  2. Set Pipeline script from SCM"
	@echo "  3. Point to this repository's Jenkinsfile"
	@echo ""

# Docker cleanup
.PHONY: docker-clean
docker-clean:
	@echo "$(CYAN)Removing unused Docker resources...$(NC)"
	docker system prune -f
	@echo "$(GREEN)✓ Docker cleanup complete$(NC)"

# Comprehensive health check
.PHONY: full-health
full-health:
	@echo "$(CYAN)╔════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)║  Comprehensive Health Check            ║$(NC)"
	@echo "$(CYAN)╚════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)1. Service Status:$(NC)"
	@docker compose ps
	@echo ""
	@echo "$(YELLOW)2. Direct Backend Tests:$(NC)"
	@echo "   Backend 1: $$(curl -s http://localhost:8081/health)"
	@echo "   Backend 2: $$(curl -s http://localhost:8082/health)"
	@echo ""
	@echo "$(YELLOW)3. Load Balancer:$(NC)"
	@echo "   NGINX Health: $$(curl -s http://localhost:8080/health)"
	@echo ""
	@echo "$(YELLOW)4. Network:$(NC)"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "backend|nginx"
	@echo ""
	@echo "$(GREEN)✓ Health check complete$(NC)"
	@echo ""

# Default: show help when called with no arguments
.DEFAULT_GOAL := help
