#!/bin/bash

# Start Elasticsearch in the background
/usr/local/bin/docker-entrypoint.sh elasticsearch -d

# Wait for Elasticsearch to start
until curl -s -X GET "http://localhost:9200/" | grep -q "You Know, for Search"; do
    sleep 5
done

# Set up built-in users
echo "Setting up built-in users..."
elasticsearch-setup-passwords auto -b << EOF
y
EOF

# Create passwords for system users
curl -X POST -u "elastic:${ELASTIC_PASSWORD}" "http://localhost:9200/_security/user/kibana_system/_password" -H 'Content-Type: application/json' -d "{\"password\":\"${ELASTIC_PASSWORD}\"}"
curl -X POST -u "elastic:${ELASTIC_PASSWORD}" "http://localhost:9200/_security/user/logstash_system/_password" -H 'Content-Type: application/json' -d "{\"password\":\"${ELASTIC_PASSWORD}\"}"
curl -X POST -u "elastic:${ELASTIC_PASSWORD}" "http://localhost:9200/_security/user/beats_system/_password" -H 'Content-Type: application/json' -d "{\"password\":\"${ELASTIC_PASSWORD}\"}"

# Keep container running
tail -f /dev/null 