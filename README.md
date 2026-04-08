# elk-docker-compose-coolify

## VPS Setup (Run Before First Deploy)

Coolify generates a new project name prefix on each redeploy, which causes named Docker volumes to be recreated empty. To persist Elasticsearch data, we use a bind mount to a fixed host path.

Run on the VPS:

```bash
mkdir -p /data/elasticsearch && chown -R 1000:1000 /data/elasticsearch
```
