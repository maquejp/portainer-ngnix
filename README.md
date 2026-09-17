# Nginx Portainer Stack

Reverse proxy for local development services.

## Services

| Path | Service | Port |
|------|---------|------|
| `/` | Welcome page (static) | - |
| `/smart/` | Angular SPA | 8089 |
| `/maildev/` | MailDev (email testing) | 1080 |
| `/dummy/` | Dummy service | 8080 |

All apps (Smart, MailDev, etc.) are deployed as their own containers and must be attached to the shared `shared` Docker network.

## Usage

```bash
docker network create shared   # one-time
docker compose up --build -d
```

## Adding a New Service

1. Deploy the service separately, attached to the `shared` network
2. Add a `location` block in `nginx.conf`:
   ```nginx
   location /new-service/ {
       proxy_pass http://new-service:PORT/;
       proxy_http_version 1.1;
       proxy_set_header Upgrade $http_upgrade;
       proxy_set_header Connection "upgrade";
       proxy_set_header Host $host;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header X-Forwarded-Proto $scheme;
   }
   ```
3. Rebuild nginx: `docker compose up --build nginx`

## Serving an Angular SPA through nginx

The SPA runs in its own container. Points to watch:

- **`baseHref`** must match the nginx location path (`/smart/`)
- **API calls** should use relative paths (e.g. `/api/foo`) so the browser hits the same origin
- WebSocket or routing need `proxy_set_header` upgrade headers (already in the blocks above)
- Confirm the SPA container forwards paths correctly when a trailing `/` is stripped by `proxy_pass` (use `proxy_pass http://smart:80;` without trailing slash if the SPA must see the full `/smart/` path)