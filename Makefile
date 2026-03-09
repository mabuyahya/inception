COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = /home/$(USER)/data

all: up

up:
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress
	@docker compose -f $(COMPOSE_FILE) up --build -d

down:
	@docker compose -f $(COMPOSE_FILE) down

clean:
	@docker compose -f $(COMPOSE_FILE) down -v

fclean: clean
	@docker system prune -af
	@sudo rm -rf $(DATA_DIR)

re: fclean all

status:
	@docker compose -f $(COMPOSE_FILE) ps

start:
	@docker compose -f $(COMPOSE_FILE) start

stop:
	@docker compose -f $(COMPOSE_FILE) stop

restart:
	@docker compose -f $(COMPOSE_FILE) restart

.PHONY: all up down clean fclean re status start stop restart