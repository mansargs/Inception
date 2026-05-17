LIGHT_PURPLE	= \033[1;35m
RESET			= \033[0m

DATA_PATH		= /home/$(USER)/data
WORDPRESS_PATH	= $(DATA_PATH)/wordpress
MARIADB_PATH	= $(DATA_PATH)/mariadb
SECRETS_PATH	= ./srcs/secrets
ENV_FILE		= ./srcs/.env

all: check_env create_dirs check_secrets up

check_env:
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "${LIGHT_PURPLE}Error: .env file not found at $(ENV_FILE)${RESET}"; \
		echo "${LIGHT_PURPLE}Copy .env_example to .env and fill in your values:${RESET}"; \
		echo "  cp srcs/.env_example srcs/.env"; \
		exit 1; \
	fi

create_dirs:
	@mkdir -p $(WORDPRESS_PATH)
	@mkdir -p $(MARIADB_PATH)
	@echo "${LIGHT_PURPLE}Data directories created at $(DATA_PATH)${RESET}"

check_secrets:
	@mkdir -p $(SECRETS_PATH)/maria_db
	@mkdir -p $(SECRETS_PATH)/wordpress
	@error=0; \
	if [ ! -f $(SECRETS_PATH)/maria_db/db_password.txt ] || [ ! -s $(SECRETS_PATH)/maria_db/db_password.txt ]; then \
		echo "${LIGHT_PURPLE}Missing: $(SECRETS_PATH)/maria_db/db_password.txt${RESET}"; error=1; \
	fi; \
	if [ ! -f $(SECRETS_PATH)/maria_db/db_root_password.txt ] || [ ! -s $(SECRETS_PATH)/maria_db/db_root_password.txt ]; then \
		echo "${LIGHT_PURPLE}Missing: $(SECRETS_PATH)/maria_db/db_root_password.txt${RESET}"; error=1; \
	fi; \
	if [ ! -f $(SECRETS_PATH)/wordpress/wp_user_password.txt ] || [ ! -s $(SECRETS_PATH)/wordpress/wp_user_password.txt ]; then \
		echo "${LIGHT_PURPLE}Missing: $(SECRETS_PATH)/wordpress/wp_user_password.txt${RESET}"; error=1; \
	fi; \
	if [ ! -f $(SECRETS_PATH)/wordpress/wp_root_password.txt ] || [ ! -s $(SECRETS_PATH)/wordpress/wp_root_password.txt ]; then \
		echo "${LIGHT_PURPLE}Missing: $(SECRETS_PATH)/wordpress/wp_root_password.txt${RESET}"; error=1; \
	fi; \
	if [ $$error -eq 1 ]; then \
		echo ""; \
		echo "${LIGHT_PURPLE}Create the missing secrets files with your passwords:${RESET}"; \
		echo "  echo -n 'your_db_pass' > $(SECRETS_PATH)/maria_db/db_password.txt"; \
		echo "  echo -n 'your_root_pass' > $(SECRETS_PATH)/maria_db/db_root_password.txt"; \
		echo "  echo -n 'your_wp_user_pass' > $(SECRETS_PATH)/wordpress/wp_user_password.txt"; \
		echo "  echo -n 'your_wp_admin_pass' > $(SECRETS_PATH)/wordpress/wp_root_password.txt"; \
		exit 1; \
	fi
	@echo "${LIGHT_PURPLE}Secrets files verified.${RESET}"

up:
	@echo "${LIGHT_PURPLE}Starting up containers...${RESET}"
	@docker-compose -f ./srcs/docker-compose.yml up -d --build
	@echo "${LIGHT_PURPLE}Containers are up! Access your site at https://$(USER).42.fr${RESET}"

down:
	@echo "${LIGHT_PURPLE}Shutting down containers...${RESET}"
	@docker-compose -f ./srcs/docker-compose.yml down
	@echo "${LIGHT_PURPLE}Done.${RESET}"

hard_down:
	@echo "${LIGHT_PURPLE}Shutting down containers and removing named volumes...${RESET}"
	@docker-compose -f ./srcs/docker-compose.yml down -v
	@echo "${LIGHT_PURPLE}Done.${RESET}"

start:
	@echo "${LIGHT_PURPLE}Starting containers...${RESET}"
	@docker-compose -f ./srcs/docker-compose.yml start
	@echo "${LIGHT_PURPLE}Done.${RESET}"

stop:
	@echo "${LIGHT_PURPLE}Stopping containers...${RESET}"
	@docker-compose -f ./srcs/docker-compose.yml stop
	@echo "${LIGHT_PURPLE}Done.${RESET}"

clean: down
	@echo "${LIGHT_PURPLE}Removing host data directories...${RESET}"
	@sudo rm -rf $(WORDPRESS_PATH)
	@sudo rm -rf $(MARIADB_PATH)

	@echo "${LIGHT_PURPLE}Removing volumes ...${RESET}"
	@docker volume rm srcs_wordpress-volume srcs_mariadb-volume 2>/dev/null || true

	@echo "${LIGHT_PURPLE}Host data cleaned.${RESET}"

fclean: clean
	@echo "${LIGHT_PURPLE}Removing project Docker images...${RESET}"
	@docker rmi my-nginx my-mariadb my-wordpress 2>/dev/null || true
	@echo "${LIGHT_PURPLE}Project images removed.${RESET}"

	@echo "${LIGHT_PURPLE}Removing secrets...${RESET}"
	@rm -rf $(SECRETS_PATH)

	@echo "${LIGHT_PURPLE}Clearing Docker build cache...${RESET}"
	@docker builder prune -f
	@echo "${LIGHT_PURPLE}Build cache cleared.${RESET}"

	@echo "${LIGHT_PURPLE}Full clean complete!${RESET}"

re: fclean all

.PHONY: all re up down hard_down start stop create_dirs check_secrets check_env clean fclean
