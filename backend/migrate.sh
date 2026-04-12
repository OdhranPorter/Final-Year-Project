#!/bin/bash
set -e
echo "Running migrations..."
python manage.py migrate --noinput
echo "Migrations complete!"
