.PHONY: up down restart logs ps health shell-db reset

up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart

logs:
	docker compose logs -f

ps:
	docker compose ps

health:
	curl -s http://localhost:$$(grep ^HONCHO_PORT .env.api | cut -d= -f2)/health | jq .

shell-db:
	docker exec -it honcho-db psql \
	  -U $$(grep ^POSTGRES_USER .env.db | cut -d= -f2) \
	  -d $$(grep ^POSTGRES_DB .env.db | cut -d= -f2)

# Tear down everything and wipe all volumes — destructive!
reset:
	docker compose down -v
	rm -rf ./db_data
