#!/bin/bash
set -e

# Install Node dependencies if node_modules is empty
if [ ! -d "node_modules/@tailwindcss" ]; then
  echo "Installing Node dependencies..."
  yarn install
fi

# Execute the main command
exec "$@"
