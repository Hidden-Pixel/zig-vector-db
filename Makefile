.PHONY: db

db: ## start db
	docker-compose -f docker-compose.yml up --build -d postgres
	
