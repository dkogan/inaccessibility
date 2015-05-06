#!/bin/zsh

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

