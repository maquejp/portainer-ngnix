# Nginx Portainer Stack

Reverse proxy for local development services, used alongside a Portainer instance for container management.

This repo runs one container:

| Service | Image                                          | Access             | Purpose       |
| ------- | ---------------------------------------------- | ------------------ | ------------- |
| nginx   | `nginx-portainer:latest` (built from this repo) | <http://localhost> | Reverse proxy |

Portainer is **not** part of this compose stack — it is already running on the machine (<https://localhost:9443>). Point Portainer at `/var/run/docker.sock` if you want it managing these containers.

## Proxied Services

Apps such as Smart, MailDev, etc. are deployed as their own containers and must be attached to the `local-network` Docker network. nginx routes them by path:

| Path        | Service                 | Port |
| ----------- | ----------------------- | ---- |
| `/`         | Welcome page (static)   | -    |
| `/smart/`   | Angular SPA             | 8089 |
| `/maildev/` | MailDev (email testing) | 80    |
| `/dummy/`   | Dummy service           | 8080 |

## MailDev Configuration

MailDev runs as its own container (e.g. deployed through Portainer) on the same Docker network as nginx. The mapping you see in Portainer only applies to host access — nginx uses the container-internal port instead.

- A Portainer mapping like `8085:80` means host port **8085** maps to container port **80**.
- `http://localhost:8085` reaches MailDev directly (host → container).
- nginx connects over the Docker network by hostname, so `proxy_pass` must point at the **internal** port:

  ```nginx
  location /maildev/ {
      proxy_pass http://maildev:80/;
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
  }
  ```

- The default MailDev web port is `1080`; if the container maps to a different one (e.g. `80`), update `proxy_pass` to match the actual internal port or upstream connections fail.
- Do **not** add a `location ~* \.(js|css|png|jpg|jpeg|gif|ico)$` caching block: regex locations take precedence over prefix locations, so nginx would serve MailDev's assets from its own html directory and return 404 instead of proxying them.

## Usage

```bash
docker network create local-network   # one-time
make build                     # build + tag the nginx image once
make up                        # start services (nginx)
```

The compose file declares both `build: .` and `image: nginx-portainer:latest` for nginx. Running `make build` tags the image, so `docker compose up` simply references it afterwards — it only builds on the fly if the image is missing. Use `make rebuild` after editing `nginx.conf`.

## Make Targets

| Target         | Description                                |
| -------------- | ------------------------------------------ |
| `make build`   | Build + tag the nginx image once           |
| `make up`      | Start all services                         |
| `make rebuild` | Force-rebuild nginx and restart everything |
| `make down`    | Stop and remove containers                 |
| `make restart` | Restart containers                         |
| `make logs`    | Tail logs                                  |
| `make ps`      | Show running services                      |
| `make pull`    | Pull prebuilt images                       |
| `make push`    | Push the nginx image to a registry         |
| `make save`    | Export image to `images/nginx-portainer-latest-<timestamp>.tar` |
| `make load`    | Load image from the latest tar in the images folder      |

## Moving the Image to Another Server (Portainer)

`make save` first builds the image (it depends on `make build`), then exports it to `images/nginx-portainer-latest-<timestamp>.tar`. Each run keeps its own timestamped archive, so you can save multiple versions:

```bash
make save
```

Copy that file to the target machine, then in Portainer go to **Images → Load** → select **Load image from file** and upload it. Afterwards you can create a container from the `nginx-portainer:latest` image. To restore it locally instead:

```bash
make load
```

## Adding a New Service

1. Deploy the service separately, attached to the `local-network` network
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

3. Add a link in `index.html`
4. Rebuild nginx: `make rebuild`

## Serving an Angular SPA through nginx

The SPA runs in its own container. Points to watch:

- **`baseHref`** must match the nginx location path (`/smart/`)
- **API calls** should use relative paths (e.g. `/api/foo`) so the browser hits the same origin
- WebSocket or routing need `proxy_set_header` upgrade headers (already in the blocks above)
- Confirm the SPA container forwards paths correctly when a trailing `/` is stripped by `proxy_pass` (use `proxy_pass http://smart:80;` without trailing slash if the SPA must see the full `/smart/` path)
