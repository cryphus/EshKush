.PHONY: test test-unit test-integration test-e2e test-local \
        build up down logs help

test: test-unit test-integration

test-unit:
	docker-compose run --rm unit-tests

test-integration:
	docker-compose up --abort-on-container-exit --exit-code-from repo-tests \
	    postgres-test repo-tests

test-e2e:
	docker-compose up --abort-on-container-exit --exit-code-from e2e-tests \
	    postgres redis backend e2e-tests

test-all:
	@bash run-tests.sh

test-local:
	cd backend && dart test test/unit --reporter expanded

test-local-integration:
	cd backend && \
	  TEST_DB_HOST=localhost TEST_DB_PORT=5435 \
	  TEST_DB_NAME=eshkush_test TEST_DB_USER=$${DB_USER} TEST_DB_PASSWORD=$${DB_PASSWORD} \
	  JWT_SECRET=$${JWT_SECRET} JWT_REFRESH_SECRET=$${JWT_REFRESH_SECRET} \
	  BCRYPT_LOG_ROUNDS=4 \
	  dart test test/integration/repositories test/integration/services \
	    --reporter expanded --concurrency=1

build:
	docker-compose build

up:
	docker-compose up postgres redis backend

down:
	docker-compose down

logs:
	docker-compose logs -f $(s)

help:
	@echo ""
	@echo "  make test              — unit + integration тесты"
	@echo "  make test-unit         — только unit (быстро)"
	@echo "  make test-integration  — integration репозиториев + сервисов"
	@echo "  make test-e2e          — e2e HTTP тесты (весь стек)"
	@echo "  make test-all          — все тесты включая e2e (поэтапно)"
	@echo "  make test-local        — unit без Docker (нужен dart)"
	@echo "  make build             — собрать Docker-образы"
	@echo "  make up                — поднять бекенд"
	@echo "  make down              — остановить всё"
	@echo "  make logs s=backend    — логи сервиса"
	@echo ""
