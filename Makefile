all: build/openmaptiles.tm2source/data.yml build/mapping.yaml build/tileset.sql

help:
	@echo "=============================================================================="
	@echo " OpenMapTiles  https://github.com/openmaptiles/openmaptiles "
	@echo "Hints for testing areas                "
	@echo "  make list                            # list actual geofabrik OSM extracts for download -> <<your-area>> "
	@echo "  "
	@echo "Hints for designers:"
	@echo "  make start-tileserver                # start klokantech/tileserver-gl [ see localhost:8080 ] "
	@echo "  "
	@echo "Hints for developers:"
	@echo "  make                                 # build source code  "
	@echo "  make download-geofabrik area=albania # download OSM data from geofabrik, and create config file"
	@echo "  make psql                            # start PostgreSQL console "
	@echo "  make psql-list-tables                # list all PostgreSQL tables "
	@echo "  make psql-vacuum-analyze             # PostgreSQL: VACUUM ANALYZE"
	@echo "  make psql-analyze                    # PostgreSQL: ANALYZE"
	@echo "  make generate-devdoc                 # generate devdoc  [./build/devdoc]"
	@echo "  make clean-docker                    # remove docker containers, PG data volume "
	@echo "  make forced-clean-sql                # drop all PostgreSQL tables for clean environment "
	@echo "  cat  .env                            # list PG database and MIN_ZOOM and MAX_ZOOM informations"
	@echo "  make help                            # help about avaialable commands"
	@echo "=============================================================================="

build:
	mkdir -p build

build/openmaptiles.tm2source/data.yml: build
	mkdir -p build/openmaptiles.tm2source
	docker-compose run --rm openmaptiles-tools generate-tm2source openmaptiles.yaml --host="postgres" --port=5432 --database="openmaptiles" --user="openmaptiles" --password="openmaptiles" > build/openmaptiles.tm2source/data.yml

build/mapping.yaml: build
	docker-compose run --rm openmaptiles-tools generate-imposm3 openmaptiles.yaml > build/mapping.yaml

build/tileset.sql: build
	docker-compose run --rm openmaptiles-tools generate-sql openmaptiles.yaml > build/tileset.sql

clean:
	rm -f build/openmaptiles.tm2source/data.yml && rm -f build/mapping.yaml && rm -f build/tileset.sql

clean-docker:
	docker-compose down -v --remove-orphans
	docker-compose rm -fv
	docker volume ls -q | grep openmaptiles  | xargs -r docker volume rm || true

db-start:
	docker-compose up   -d postgres

psql: db-start
	docker-compose run --rm import-osm /usr/src/app/psql.sh

import-osm: db-start all
	docker-compose run --rm import-osm

import-sql: db-start all
	docker-compose run --rm import-sql

import-osmsql: db-start all
	docker-compose run --rm import-osm
	docker-compose run --rm import-sql

generate-tiles: db-start all
	rm -rf data/tiles.mbtiles
	if [ -f ./data/docker-compose-config.yml ]; then \
		echo "Generating tiles with custom config."; \
		docker-compose -f docker-compose.yml -f ./data/docker-compose-config.yml run --rm generate-vectortiles; \
		docker-compose -f docker-compose.yml -f ./data/docker-compose-config.yml run --rm openmaptiles-tools  generate-metadata --force ./data/tiles.mbtiles; \
	else \
		docker-compose run --rm generate-vectortiles; \
		docker-compose run --rm openmaptiles-tools  generate-metadata --force ./data/tiles.mbtiles; \
	fi
	docker-compose run --rm openmaptiles-tools  chmod 666         ./data/tiles.mbtiles

psql-vacuum-analyze: db-start
	@echo "Start - postgresql: VACUUM ANALYZE VERBOSE;"
	docker-compose run --rm import-osm /usr/src/app/psql.sh  -P pager=off  -c 'VACUUM ANALYZE VERBOSE;'

psql-analyze: db-start
	@echo "Start - postgresql: ANALYZE VERBOSE ;"
	docker-compose run --rm import-osm /usr/src/app/psql.sh  -P pager=off  -c 'ANALYZE VERBOSE;'

download-geofabrik:
	@echo ===============  download-geofabrik =======================
	@echo Download area :   $(area)
	@echo [[ example: make download-geofabrik  area=albania ]]
	@echo [[ list areas:  make download-geofabrik-list       ]]
	docker-compose run --rm import-osm  ./download-geofabrik.sh $(area)
	ls -la ./data/$(area).*
	@echo "Generated config file: ./data/docker-compose-config.yml"
	@echo " "
	cat ./data/docker-compose-config.yml
	@echo " "

list:
	docker-compose run --rm import-osm  ./download-geofabrik-list.sh

download-wikidata:
	mkdir -p wikidata && docker-compose run --rm --entrypoint /usr/src/app/download-gz.sh import-wikidata

start-tileserver:
	@echo " "
	@echo "***********************************************************"
	@echo "* "
	@echo "* Download/refresh klokantech/tileserver-gl docker image"
	@echo "* see documentation: https://github.com/klokantech/tileserver-gl"
	@echo "* "
	@echo "***********************************************************"
	@echo " "
	docker pull klokantech/tileserver-gl
	@echo " "
	@echo "***********************************************************"
	@echo "* "
	@echo "* Start klokantech/tileserver-gl "
	@echo "*       ----------------------------> check localhost:8080 "
	@echo "* "
	@echo "***********************************************************"
	@echo " "
	docker run -it --rm --name tileserver-gl -v $$(pwd)/data:/data -p 8080:80 klokantech/tileserver-gl


generate-devdoc:
	mkdir -p ./build/devdoc
	docker run --rm -v $$(pwd):/tileset openmaptiles/openmaptiles-tools generate-etlgraph layers/skiing/skiing.yaml               ./build/devdoc

list-docker-images:
	docker images | grep openmaptiles

refresh-docker-images:
	docker-compose pull --ignore-pull-failures

remove-docker-images:
	@echo "Deleting all openmaptiles related docker image(s)..."
	@docker-compose down
	@docker images | grep "openmaptiles" | awk -F" " '{print $$3}' | xargs --no-run-if-empty docker rmi -f
	@docker images | grep "osm2vectortiles/mapbox-studio" | awk -F" " '{print $$3}' | xargs --no-run-if-empty docker rmi -f
	@docker images | grep "klokantech/tileserver-gl"      | awk -F" " '{print $$3}' | xargs --no-run-if-empty docker rmi -f

docker-unnecessary-clean:
	@echo "Deleting unnecessary container(s)..."
	@docker ps -a  | grep Exited | awk -F" " '{print $$1}' | xargs  --no-run-if-empty docker rm
	@echo "Deleting unnecessary image(s)..."
	@docker images | grep \<none\> | awk -F" " '{print $$3}' | xargs  --no-run-if-empty  docker rmi


