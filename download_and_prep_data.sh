#!/bin/bash

abort() {
    echo "$*"; exit 1;
}

usage() {
    abort "Usage: $(basename $0)"
}

require() {
    type $1 >/dev/null 2>/dev/null
}

while [ "${1#-}" != "$1" ]; do
    case "$1" in
        -h) usage;;
        *) usage;;
    esac
    shift
done

require ogr2ogr || abort "Please install gdal -- on Ubuntu: sudo apt-get install gdal-bin"
require topojson || abort "Please install topojson -- with Node, npm install -g topojson"

set -e

mkdir -p data && cd data

echo "Downloading datasets..."
wget -c http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_0_map_subunits.zip
wget -c http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_populated_places.zip

echo "Extracting archives"
unzip -o ne_10m_admin_0_map_subunits.zip
unzip -o ne_10m_populated_places.zip

echo "Cleaning up old JSON files, if any..."
rm -f *.json

echo "Extracting interesting data to GeoJSON files..."
ogr2ogr -f GeoJSON -where "ADM0_A3 IN ('GBR', 'IRL')" \
    subunits-uk.json ne_10m_admin_0_map_subunits.shp
ogr2ogr -f GeoJSON -where "ADM0_A3 IN ('BRA', 'URY', 'ARG', 'PRY', 'VEN', 'COL', 'BOL')" \
    subunits-brasil.json ne_10m_admin_0_map_subunits.shp


ogr2ogr -f GeoJSON -where "ISO_A2 = 'GB' AND SCALERANK < 8" places-uk.json ne_10m_populated_places.shp
ogr2ogr -f GeoJSON -where "ISO_A2 = 'BR' AND SCALERANK < 8" places-brasil.json ne_10m_populated_places.shp


echo "Consolidating data in TopoJSON files..."
topojson -o brasil.json --id-property SU_A3 --properties name=NAMEASCII,category=FEATURECLA -- subunits-brasil.json places-brasil.json
topojson -o uk.json --id-property SU_A3 --properties name=NAME,category=FEATURECLA -- subunits-uk.json places-uk.json

echo "Done"
