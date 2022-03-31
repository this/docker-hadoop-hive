.PHONY: start_hadoop
start_hadoop:
	$(MAKE) start-docker-compose-service service=hadoop


.PHONY: start_hive
start_hive:
	$(MAKE) start-docker-compose-service service=hive


.PHONY: start_kerberized_hadoop
start_kerberized_hadoop:
	$(MAKE) start-docker-compose-service service=kerberized-hadoop


.PHONY: start_kerberized_hive
start_kerberized_hive:
	$(MAKE) start-docker-compose-service service=kerberized-hive


.PHONY: start-docker-compose-service
start-docker-compose-service:
	$(MAKE) stop-docker-compose-services
	docker-compose --env-file .env up --build --remove-orphans --renew-anon-volumes --detach $(service)


.PHONY: stop-docker-compose-service
stop-docker-compose-services:
	docker-compose --env-file .env down --remove-orphans --volumes
