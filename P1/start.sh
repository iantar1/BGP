#!/bin/sh
# P1/docker/router/start.sh
# This script runs when the container starts in GNS3

# Start the FRR service (launches all enabled daemons)
/usr/lib/frr/frrinit.sh start

# Keep container alive (GNS3 needs the container running)
tail -f /dev/null