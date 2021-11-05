#!/bin/bash

echo "$(timeout --foreground 1 cat)" > /tmp/stdin.scn

if grep -q '<Node' /tmp/stdin.scn; then
	runSofa --input-file /tmp/stdin.scn --gui batch "$@"
else
    exec "$@"
fi
