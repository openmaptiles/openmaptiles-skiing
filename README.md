## OpenMapTiles

OpenMapTiles is an extensible and open vector tile schema for a OpenStreetMap basemap. It is used to generate vector tiles for [openmaptiles.org](https://openmaptiles.org/) and [openmaptiles.com](https://openmaptiles.com/).

We encourage you to collaborate, reuse and adapt existing layers and add your own layers or use our approach for your own vector tile project. The repository is built on top of the [openmaptiles/tools](https://github.com/openmaptiles/openmaptiles-tools) to simplify vector tile creation.

- :link: Docs https://openmaptiles.org/docs
- :link: Schema: https://openmaptiles.org/schema
- :link: Production package: https://openmaptiles.com/

This repository is the simple example, how to create a custom layer in [OpenMapTiles project](https://github.com/openmaptiles/openmaptiles).


## Develop

To work on OpenMapTiles you need Docker and Python.

- Install [Docker](https://docs.docker.com/engine/installation/). Minimum version is 1.12.3+.
- Install [Docker Compose](https://docs.docker.com/compose/install/). Minimum version is 1.7.1+.

### Build

Build the tileset.

```bash
git clone git@github.com:openmaptiles/skiing.git
cd openmaptiles
# Build the imposm mapping, the tm2source project and collect all SQL scripts
make
```

### Prepare the Database

Now start up the database container.

```bash
docker-compose up -d postgres
```

[Download OpenStreetMap data extracts](http://download.geofabrik.de/) and store the PBF file in the `./data` directory.

```bash
cd data
wget http://download.geofabrik.de/europe/albania-latest.osm.pbf
```

[Import OpenStreetMap data](https://github.com/openmaptiles/import-osm) with the mapping rules from
`build/mapping.yaml` (which has been created by `make`).

```bash
docker-compose run import-osm
```

### Work on Layers

Each time you modify layer SQL code run `make` and `docker-compose run import-sql`.

```
make clean
make
docker-compose run import-sql
```

Now you are ready to **generate the vector tiles**. Using environment variables
you can limit the bounding box and zoom levels of what you want to generate (`docker-compose.yml`).

```
docker-compose run generate-vectortiles
```

## License

All code in this repository is under the [BSD license](./LICENSE.md) and the cartography decisions encoded in the schema and SQL are licensed under [CC-BY](./LICENSE.md).

Products or services using maps derived from OpenMapTiles schema need to visibly credit "OpenMapTiles.org" or reference "OpenMapTiles" with a link to https://openmaptiles.org/. Exceptions to attribution requirement can be granted on request.

For a browsable electronic map based on OpenMapTiles and OpenStreetMap data, the
credit should appear in the corner of the map. For example:

[© OpenMapTiles](https://openmaptiles.org/) [© OpenStreetMap contributors](https://www.openstreetmap.org/copyright)

For printed and static maps a similar attribution should be made in a textual
description near the image, in the same fashion as if you cite a photograph.
