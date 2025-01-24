#!/bin/bash

# Start Elasticsearch in the background
/usr/local/bin/docker-entrypoint.sh elasticsearch -d

# Wait for Elasticsearch to start
until curl -s -X GET "http://localhost:9200/" | grep -q "You Know, for Search"; do
    echo "Waiting for Elasticsearch to start..."
    sleep 10
done

echo "Elasticsearch is up - executing setup"

# Wait a bit more to ensure the security system is initialized
sleep 10

# Set up built-in users
echo "Setting up built-in users..."
elasticsearch-setup-passwords auto -b << EOF
y
EOF

# Wait for password setup to complete
sleep 5

# Create passwords for system users
echo "Setting up system users..."
curl -X POST -u "elastic:${ELASTIC_PASSWORD}" "http://localhost:9200/_security/user/kibana_system/_password" -H 'Content-Type: application/json' -d "{\"password\":\"${ELASTIC_PASSWORD}\"}"
curl -X POST -u "elastic:${ELASTIC_PASSWORD}" "http://localhost:9200/_security/user/logstash_system/_password" -H 'Content-Type: application/json' -d "{\"password\":\"${ELASTIC_PASSWORD}\"}"
curl -X POST -u "elastic:${ELASTIC_PASSWORD}" "http://localhost:9200/_security/user/beats_system/_password" -H 'Content-Type: application/json' -d "{\"password\":\"${ELASTIC_PASSWORD}\"}"

echo "Setup completed"

# Keep container running
tail -f /dev/null 