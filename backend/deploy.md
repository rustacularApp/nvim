# The Master A-to-Z Deployment Playbook (Fresh VPS → Live Zero-Downtime)

Save this checklist. **Part 1** is done once per VPS; **Parts 2 & 3** are what you do for each new project.

## Part 1: One-Time Fresh Contabo VPS Setup

### 1.1 Point your DNS records first
In your domain registrar (Cloudflare, Namecheap, etc.), create `A` records pointing to your Contabo VPS IPv4 address:
* `coolify.yourdomain.com` → `<VPS_IP>` *(for your Coolify dashboard)*
* `api.yourdomain.com` → `<VPS_IP>` *(for your project's backend—you can add more subdomains per project later)*

*(If using Cloudflare, keep proxy status as **DNS Only / Grey Cloud** initially until SSL generates, or set SSL/TLS mode to Full (Strict).)*

### 1.2 SSH into your fresh VPS & set up Firewall
Log in as `root` (or run `sudo -i` to become root—Coolify requires root):
```bash
apt update && apt upgrade -y
apt install -y curl ufw
```

Open the required firewall ports **before** enabling UFW (do not skip port `22`, or you'll lock yourself out):
```bash
ufw allow 22/tcp      # SSH
ufw allow 80/tcp      # HTTP (needed for SSL certs)
ufw allow 443/tcp     # HTTPS (your live apps)
ufw allow 8000/tcp    # Coolify dashboard (initial setup)
ufw allow 6001/tcp    # Coolify realtime logs (initial setup)
ufw allow 6002/tcp    # Coolify web terminal (initial setup)
ufw enable
```

### 1.3 Install Coolify (installs Docker + Traefik automatically)
Run the single official command as `root` (do **not** install Docker manually beforehand—let Coolify do it):
```bash
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
```
Wait ~2–5 minutes. When it finishes, it will print `http://<VPS_IP>:8000`.

### 1.4 Claim your Admin Account & Lock Down Coolify
1. **Immediately** open `http://<VPS_IP>:8000` in your browser and register your admin email/password. *(Do this right away—whoever visits port 8000 first becomes the admin!)*
2. In the Coolify dashboard, go to **Settings → Configuration → Instance's Domain** and enter `https://coolify.yourdomain.com`, then save.
3. Wait 1 minute and visit `https://coolify.yourdomain.com`. Once it loads with HTTPS, you can close the bootstrap ports on your VPS:
   ```bash
   ufw delete allow 8000/tcp
   ufw delete allow 6001/tcp
   ufw delete allow 6002/tcp
   ```
4. **Enable API Access** (so GitHub Actions can trigger deploys):
   * In Coolify: **Settings → Advanced → toggle ON "API Access"**.
   * Go to **Keys & Tokens → API Tokens → Create New Token** (give it **Deploy** permission). Copy and save this token somewhere safe—we'll call it `COOLIFY_TOKEN`.
5. **Log into GitHub Container Registry (GHCR) on the VPS** (only needed if your GitHub repo/Docker images are private):
   * On GitHub: *Profile Settings → Developer Settings → Personal Access Tokens (Classic)* → generate a token with `read:packages`.
   * On Contabo SSH (as `root`):
     ```bash
     echo "<YOUR_GITHUB_PAT>" | docker login ghcr.io -u <YOUR_GITHUB_USERNAME> --password-stdin
     ```

Your Contabo server is now a permanent private cloud. **You never have to repeat Part 1 for future projects.**

---

## Part 2: Your Reusable Project Template (Copy-Paste into any new Repo)

When you start a new Rust project, make sure your Rust code has:
* A `GET /health` route that returns `200 OK` (ideally checking DB/Redis ping).
* Graceful shutdown on `SIGTERM` (Actix-web has this built in; in Axum, use `.with_graceful_shutdown(...)`).

Then copy-paste just these **2 files** into the new project repo:

### File 1: `Dockerfile`
```dockerfile
FROM rust:1.96-slim AS builder

WORKDIR /usr/src/app
RUN apt-get update && apt-get install -y pkg-config libssl-dev perl make gcc && rm -rf /var/lib/apt/lists/*

COPY backend ./backend
WORKDIR /usr/src/app/backend
RUN cargo build --release

FROM ubuntu:24.04
WORKDIR /app

# curl is required for Coolify's zero-downtime HTTP healthcheck
RUN apt-get update && apt-get install -y libssl3 ca-certificates curl && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/src/app/backend/target/release/backend ./
CMD ["./backend"]
```

### File 2: `.github/workflows/deploy.yml`
*(Just change the `tags:` line to match the new repo name, e.g., `ghcr.io/<org>/<repo>:latest`)*
```yaml
name: Build & Deploy
on:
  push:
    branches: [ master ]
    paths:
      - 'backend/**'
      - 'Dockerfile'

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          platforms: linux/amd64
          push: true
          tags: ghcr.io/<YOUR_ORG_OR_USER>/<YOUR_REPO_NAME>:latest

      - name: Trigger Coolify Zero-Downtime Deploy
        run: |
          curl --fail --request POST "${{ secrets.COOLIFY_WEBHOOK }}" \
            --header "Authorization: Bearer ${{ secrets.COOLIFY_TOKEN }}"
```

---

## Part 3: Deploying a New Project (Step-by-Step in Coolify UI)

### 3.1 Create Project & Databases
1. Open `https://coolify.yourdomain.com` → **Projects → + Add** (name it after your project, e.g. `Rustacular`).
2. Inside the `production` environment, click **+ New Resource**:
   * **Add PostgreSQL:** Pick PostgreSQL → select your server → review/set username, password, DB name → click **Start**. *(Bonus: Coolify has a built-in **Backups** tab right here for automatic scheduled `pg_dump` backups!)*
   * **Add Redis:** Click **+ New Resource → Redis** → set password → click **Start**.
   * *(Note on PgBouncer: If your Rust app already uses `sqlx::PgPool` or `deadpool-postgres`, Rust handles connection pooling inside the binary so you usually don't even need PgBouncer! If you still want PgBouncer, you can deploy a small Docker Compose resource in Coolify just for PgBouncer pointing at Coolify's Postgres container name.)*
3. Copy the **Internal URL / Hostname** shown inside Coolify for Postgres and Redis (Coolify puts everything in the same project on the same Docker network automatically).

### 3.2 Add Your Rust Backend App
1. Click **+ New Resource → Docker Image** *(IMPORTANT: choose **Docker Image**, NOT Docker Compose, so zero-downtime rolling updates work)*.
2. Enter:
   * **Image:** `ghcr.io/<YOUR_ORG_OR_USER>/<YOUR_REPO_NAME>`
   * **Tag:** `latest`
3. Under **General**:
   * **Domains:** `https://api.yourdomain.com`
   * **Ports Exposes:** `3000`
   * **Ports Mappings:** **LEAVE BLANK!** *(Never map `3000:3000` here; leaving it blank lets Coolify spin up the new container alongside the old one.)*
4. Under **Environment Variables**:
   * Click **Developer View (Bulk Edit)** and paste your `.env` variables all at once.
   * Set `POSTGRES_HOST` / `REDIS_HOST` to the internal container names Coolify gave your databases in step 3.1.
5. Under **Healthcheck**:
   * Toggle **Enable Healthcheck** ON.
   * **Method:** `HTTP`, **Path:** `/health`, **Port:** `3000`
   * **Interval:** `5`, **Timeout:** `5`, **Retries:** `5`, **Start Period:** `10`.

### 3.3 Connect Coolify to GitHub Actions (2 Secrets only!)
1. In your Coolify app, go to the **Webhooks** tab and copy the **Deploy Webhook URL**.
2. Go to your **GitHub Repo → Settings → Secrets and variables → Actions** and add ONLY **2 secrets**:
   * `COOLIFY_WEBHOOK` = *(the Deploy Webhook URL)*
   * `COOLIFY_TOKEN` = *(the API token from Step 1.4)*

### 3.4 First Launch!
Push a commit to `master` on GitHub:
1. GitHub Actions builds your Rust Docker image and pushes it to `ghcr.io`.
2. GitHub Actions hits your `COOLIFY_WEBHOOK`.
3. Coolify pulls the image, boots your backend, checks `/health`, issues your HTTPS SSL cert via Traefik, and makes `https://api.yourdomain.com` live!

*(You can watch the live deployment logs and live container logs right inside Coolify's dashboard without ever SSHing into Contabo again.)*

---

## Part 4: Day-to-Day Cheat Sheet (Zero Downtime)

* **Changing Rust code & redeploying:**
  Just `git push` to `master`. GitHub builds the new image → Coolify boots Container v2 → waits for `GET /health` to return `200` → Traefik switches traffic to v2 → stops Container v1. **0ms downtime.**
* **Tweaking an Environment Variable (no code change):**
  Open Coolify → your app → **Environment Variables** → edit the value → click **Restart / Redeploy**. Coolify skips GitHub Actions & compilation completely, starts a fresh container from the existing `:latest` image with the new variable, checks `/health`, and swaps traffic. **~5 seconds, 0ms downtime.**
* **Checking logs / debugging:**
  Open Coolify → your app → **Logs** (or **Terminal** to exec straight into the running container from your browser). No SSH needed!
