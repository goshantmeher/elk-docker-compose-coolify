# elk-docker-compose-coolify

## VPS Setup (Run Before First Deploy)

Coolify generates a new project name prefix on each redeploy, which causes named Docker volumes to be recreated empty. To persist Elasticsearch data, we use a bind mount to a fixed host path.

Run on the VPS:

```bash
mkdir -p /data/elasticsearch && chown -R 1000:1000 /data/elasticsearch
```

## Environment Variables (Coolify)

Set these in Coolify → Service → Environment Variables before deploying:

| Variable | Description |
|---|---|
| `ELASTIC_PASSWORD` | Password for the `elastic` superuser and all built-in users |
| `RABBITMQ_USER` | RabbitMQ admin username (default: `admin`) |
| `RABBITMQ_PASS` | RabbitMQ admin password |

## Post-Deploy: Set Built-in User Passwords

After every fresh deploy (or password change), SSH into the VPS and set passwords for ES built-in users. Replace `YOUR_PASSWORD` with the `ELASTIC_PASSWORD` value.

```bash
# Set kibana_system password
curl -s -X POST "http://127.0.0.1:9200/_security/user/kibana_system/_password" -H "Content-Type: application/json" -u 'elastic:YOUR_PASSWORD' -d '{"password": "YOUR_PASSWORD"}'

# Set logstash_system password
curl -s -X POST "http://127.0.0.1:9200/_security/user/logstash_system/_password" -H "Content-Type: application/json" -u 'elastic:YOUR_PASSWORD' -d '{"password": "YOUR_PASSWORD"}'

# Set beats_system password (for filebeat)
curl -s -X POST "http://127.0.0.1:9200/_security/user/beats_system/_password" -H "Content-Type: application/json" -u 'elastic:YOUR_PASSWORD' -d '{"password": "YOUR_PASSWORD"}'
```

Each command should return `{}` on success.

## Activate License (if needed)

If Kibana shows "License is not available", run:

```bash
curl -s -X POST "http://127.0.0.1:9200/_license/start_basic?acknowledge=true" -H "Content-Type: application/json" -u 'elastic:YOUR_PASSWORD'
```

## Security Architecture

- **Elasticsearch**: Port 9200 bound to `127.0.0.1` only — not accessible from the internet. xpack security enabled with password auth.
- **Kibana**: Accessible via Traefik at `https://kibana.shopme.blog`. No port exposed directly.
- **Logstash / Filebeat**: Internal only, no ports exposed.
- **RabbitMQ**: Ports bound to `127.0.0.1`. Management UI accessible via Traefik at `https://rabbitmq.shopme.blog`.

### Connecting from local dev

Since ES is not publicly exposed, use an SSH tunnel:

```bash
ssh -L 9200:127.0.0.1:9200 root@YOUR_VPS_IP
```

Then set in your local `.env`:

```
ELASTICSEARCH_NODE=http://localhost:9200
ELASTICSEARCH_USERNAME=elastic
ELASTICSEARCH_PASSWORD=YOUR_PASSWORD
```

## Reindexing After Data Loss

ES is a search index — ScyllaDB is the source of truth. If ES data is lost, trigger a full reindex via the admin endpoint:

```
POST /api/admin/search/reindex
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| Kibana: "server is not ready yet" | `kibana_system` password not set. Run the post-deploy password commands above. |
| Kibana: "License is not available" | Run the license activation command above. |
| Kibana: plugin load error in browser | Hard refresh (`Cmd+Shift+R`) or open in incognito. Stale browser cache. |
| `index_not_found_exception` on backend | ES indices were wiped. Trigger a reindex from admin endpoint. |
| Can't connect to ES from local dev | Start SSH tunnel first (see above). |
