#!/bin/zsh

# script to get OSM ways from the global database in a lat/lon rectangle.
# Required usage is
#   $0 lat lon radius



for i (`seq 3`)
    {
        [ -z "${@[$i]}" ] && { echo "need 3 arguments on the commandline: lat,lon,radius"; exit 1  }
    }


lat0=$(($1 - $3))
lat1=$(($1 + $3))
lon0=$(($2 - $3))
lon1=$(($2 + $3))

OVERPASS="/home/dima/projects/osm_overpass/osm-3s_v0.7.53/"

$OVERPASS/bin/osm3s_query --db-dir=$OVERPASS/db <<EOF
[out:json];

way["highway"] ["highway" != "footway" ] ["highway" != "path" ]($lat0,$lon0,$lat1,$lon1);

(._;>;);

out count;

EOF

