#!/bin/zsh

# script to get OSM ways from the global database in a lat/lon rectangle.
# Required usage is
#   $0 lat0 lon0 lat1 lon1
#
# The JSON output is written into query_lat0_lon0_lat1_lon1.json



for i (`seq 4`)
    {
        [ -z "${@[$i]}" ] && { echo "need 4 arguments on the commandline: lat,lon,  lat,lon"; exit 1  }
    }


local api=http://overpass-api.de/api/interpreter
curl -X POST --data @- $api <<EOF > query_$1_$2_$3_$4.json
[out:json];

way["highway"]($1,$2,$3,$4);

(._;>;);

out;

EOF

