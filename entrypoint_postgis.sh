#!/bin/bash
set -e
service ssh start
exec /usr/local/bin/docker-entrypoint.sh "$@"
