#!/bin/bash
set -e

# Create directories if they don't exist
mkdir -p /var/lib/knot
mkdir -p /var/www/html/five.secu23.fun

# Start Knot DNS service
service knot start
echo "Knot DNS service started"

# Start Apache service
service apache2 start
echo "Apache service started"

# Keep container running
tail -f /dev/null