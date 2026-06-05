FROM node:23-slim

# Instala dependências essenciais de terminal que o Pi usa para o comando 'bash'
RUN apt-get update && apt-get install -y \
    git \
    curl \
    vim \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Instala Python 3.12 via uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && export PATH="$HOME/.local/bin:$PATH" \
    && uv python install 3.12 \
    && ln -sf ~/.local/bin/python3.12 /usr/bin/python3 \
    && ln -sf ~/.local/bin/python3.12 /usr/bin/python

# Instala o Pi Agent globalmente via NPM
RUN npm install -g @earendil-works/pi-coding-agent

# Instala as extensões do Pi
RUN npm install -g pi-mcp-adapter pi-web-access

# Define o diretório onde você vai mapear o código do seu projeto
WORKDIR /workspace

# O Pi roda interativamente, então definimos o entrypoint para ele
ENTRYPOINT ["pi"]
