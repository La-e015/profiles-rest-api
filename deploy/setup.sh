#!/usr/bin/env bash

set -e

# TODO: Set to URL of git repo.
PROJECT_GIT_URL='https://github.com/La-e015/profiles-rest-api.git'

PROJECT_BASE_PATH='/usr/local/apps/profiles-rest-api'

# Set Ubuntu Language
locale-gen en_GB.UTF-8

# Install Python 3.11, SQLite and pip
echo "Installing dependencies..."
apt-get update
apt-get install -y python3.11-dev python3.11-venv sqlite3 python3-pip supervisor nginx git

mkdir -p $PROJECT_BASE_PATH
git clone $PROJECT_GIT_URL $PROJECT_BASE_PATH

# Create the virtual environment using Python 3.11 explicitly
python3.11 -m venv $PROJECT_BASE_PATH/env

# Install dependencies inside the Python 3.11 environment
$PROJECT_BASE_PATH/env/bin/pip install -r $PROJECT_BASE_PATH/requirements.txt uwsgi setuptools

# Run migrations
$PROJECT_BASE_PATH/env/bin/python $PROJECT_BASE_PATH/manage.py migrate

# Collect static files
$PROJECT_BASE_PATH/env/bin/python $PROJECT_BASE_PATH/manage.py collectstatic --noinput

# Setup Supervisor to run our uwsgi process.
cp $PROJECT_BASE_PATH/deploy/supervisor_profiles_api.conf /etc/supervisor/conf.d/profiles_api.conf
supervisorctl reread
supervisorctl update
supervisorctl restart profiles_api

# Setup nginx to make our application accessible.
cp $PROJECT_BASE_PATH/deploy/nginx_profiles_api.conf /etc/nginx/sites-available/profiles_api.conf
rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/profiles_api.conf /etc/nginx/sites-enabled/profiles_api.conf
systemctl restart nginx.service

echo "DONE! :)"
