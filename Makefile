.PHONY: db

db: ## start db
	docker-compose -f docker-compose.yml up --build -d postgres

proxy:
	docker-compose -f docker-compose.yml up --build -d nginx
	
