# Muzly Backend Makefile

.PHONY: help install dev run test lint migrate docker-build docker-up docker-down clean

# Default target
help:
	@echo "Muzly Backend - Available commands:"
	@echo ""
	@echo "  install         - Install dependencies"
	@echo "  dev             - Run development server with auto-reload"
	@echo "  run             - Run production server"
	@echo "  test            - Run tests"
	@echo "  test-cov        - Run tests with coverage report"
	@echo "  lint            - Run linters (flake8, black, mypy)"
	@echo "  format          - Format code with black"
	@echo "  migrate         - Create and apply database migration"
	@echo "  migrate-make    - Create new migration (usage: make migrate-make msg='description')"
	@echo "  migrate-up      - Apply pending migrations"
	@echo "  migrate-down    - Downgrade one migration"
	@echo "  docker-build    - Build Docker image"
	@echo "  docker-up       - Start Docker Compose"
	@echo "  docker-down     - Stop Docker Compose"
	@echo "  docker-logs     - View Docker Compose logs"
	@echo "  docker-restart  - Restart Docker Compose"
	@echo "  clean           - Clean temporary files and cache"
	@echo ""

# Installation
install:
	pip install -r requirements.txt

dev:
	uvicorn app.main:app --reload --host 0.0.0.0 --port 8080

run:
	uvicorn app.main:app --host 0.0.0.0 --port 8080 --workers 4

# Testing
test:
	pytest

test-cov:
	pytest --cov=app --cov-report=html --cov-report=term-missing

test-watch:
	ptw --now .

# Linting
lint:
	flake8 app tests --count --select=E9,F63,F7,F82 --show-source --statistics
	flake8 app tests --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics
	black --check app tests
	mypy app --ignore-missing-imports --no-strict-optional

format:
	black app tests

isort:
	isort app tests

# Database migrations
migrate: migrate-up

migrate-make:
	alembic revision --autogenerate -m "$(msg)"

migrate-up:
	alembic upgrade head

migrate-down:
	alembic downgrade -1

migrate-show:
	alembic history

migrate-current:
	alembic current

# Docker
docker-build:
	docker-compose build

docker-up:
	docker-compose up -d

docker-up-pg:
	docker-compose --profile postgres up -d

docker-up-all:
	docker-compose --profile postgres --profile nginx up -d

docker-down:
	docker-compose down

docker-logs:
	docker-compose logs -f

docker-restart:
	docker-compose restart

docker-clean:
	docker-compose down -v
	docker system prune -f

# Cleanup
clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name "*.pyc" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type d -name ".mypy_cache" -exec rm -rf {} +
	find . -type d -name "htmlcov" -exec rm -rf {} +
	find . -type f -name ".coverage" -delete
	find . -type f -name "coverage.xml" -delete
	rm -rf dist/ build/ *.egg-info

# Development setup
setup: install
	@echo "Setting up development environment..."
	pip install flake8 black mypy pytest-cov
	@echo "Done! Run 'make dev' to start the development server."

# Production setup (with PostgreSQL)
setup-prod:
	cp .env.example .env
	@echo "Edit .env with your production settings!"
	docker-compose --profile postgres up -d
	sleep 5
	make migrate
