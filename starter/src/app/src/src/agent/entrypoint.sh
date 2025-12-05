#!/bin/bash

set -ex

htpasswd -b -c /etc/nginx/.htpasswd "${DB_USER:-benutzer}" "${DB_PASSWORD:-mot-de-passage}"
nginx

cd /appli

mkdir -p ~/.streamlit
cat <<EOF > ~/.streamlit/config.toml
[server]
enableCORS = false
enableXsrfProtection = false
corsAllowedOrigins = ['http://localhost:8501', 'http://${EXTERNAL_IP}']
EOF

uv run streamlit run app.py --server.port=8501 --server.enableCORS=false  --server.enableXsrfProtection=false
