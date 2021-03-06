#!/bin/bash
# This script makes sure that Jenkins can properly run your tests against your
# codebase.
set -e

DB_HOST="localhost"
DB_USER="hudson"

VENV=./virtualenv

echo "Starting build on executor $EXECUTOR_NUMBER..."

# Make sure there's no old pyc files around.
find . -name '*.pyc' -exec rm {} \;

# RHEL postgres 9 RPM installs pg_config here, psycopg2 needs it
export PATH=$PATH:/usr/pgsql-9.2/bin/

if [ ! -d "$VENV/bin" ]; then
  echo "No virtualenv found. Bootstrapping..."
  "$(dirname "$0")/bootstrap.sh" "$@" || exit 1
fi

if [ ! -d "vendor" ]; then
    echo "No /vendor... crap."
    exit 1
fi

source $VENV/bin/activate

echo "Linting..."
git ls-files crashstats | xargs check.py | bin/linting.py

echo "Starting tests..."
FORCE_DB=true coverage run manage.py test --noinput --with-xunit
coverage xml $(find crashstats lib -name '*.py')
echo "Tests finished."
