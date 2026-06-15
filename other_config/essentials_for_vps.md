# Essentials for VPS

## ssh Configuration

## First

```
<!-- Install UltraVNC and authorize ssh keys generated in one system -->

ssh-keygen -t ed25519 -C "<key_name>"
```

## ufw configuration (Uncomplicated Firewall)

### Second

```
ufw default deny incoming
ufw default allow outgoing

```

### Third

```
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp

```

### Fourth

```
ufw enable
```

## Neovim Installation

### Fifth

```
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
```

### Sixth

```
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
sudo apt instal gcc fd-find
```

## Docker Installation

### Seventh

```
# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
```

### Eighth

```
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

## Nginx

### Ninth

```
sudo apt install nginx -y
sudo ln -s /etc/nginx/sites-available/rustacular.conf /etc/nginx/sites-enabled/rustacular.conf
```

## Certbot

### Tenth

```
sudo apt update
sudo apt install certbot python3-certbot-nginx -y

```

### Elevent

```
sudo certbot --nginx -d rustacular.com -d www.rustacular.com
```

## Extras

```
// Copy to vps
scp -r source/folder/* <username>@<host_ip>:/destination/folder
rsync -a /source/folder/* /destination/folder/ (move with overwriting)
sudo chown -R www-data:www-data /var/www/html
sudo chomd -R 755 /var/www/html
```
