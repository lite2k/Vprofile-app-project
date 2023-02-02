#!/usr/bin/bash
set -e
INTERNETIP=$(curl "https://checkip.amazonaws.com")
INTERNETIP="$INTERNETIP/32"
jq -n --arg internetip "$INTERNETIP" '{"internet_ip":$internetip}'
