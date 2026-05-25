FROM ubuntu:latest

RUN apt-get update && apt-get install -y curl git unzip tar ripgrep fd-find build-essential && rm -rf /var/lib/apt/lists/*

RUN curl -LO https://github.com/neovim/neovim/releases/download/v0.12.2/nvim-linux-x86_64.tar.gz && tar -C /opt -xzf nvim-linux-x86_64.tar.gz && ln -s /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim && rm nvim-linux-x86_64.tar.gz

RUN --mount=type=secret,id=gh_token git config --global url."https://github.com/".insteadOf "git@github.com:" && export GH_TOKEN=$(cat /run/secrets/gh_token) && git clone https://x-access-token:${GH_TOKEN}@github.com/h4ck4l1/nvim.git /root/.config/nvim

WORKDIR /workspace

CMD [ "nvim" ]
