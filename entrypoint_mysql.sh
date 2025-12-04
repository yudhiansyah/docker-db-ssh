#!/bin/bash
set -e
# Oracle Linux (microdnf) might not have 'service' command.
# Start sshd directly.
/usr/sbin/sshd
exec /usr/local/bin/docker-entrypoint.sh "$@"
