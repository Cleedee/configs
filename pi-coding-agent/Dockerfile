FROM ubuntu:24.04

# Instala dependências essenciais de terminal que o Pi usa para o comando 'bash'
RUN apt-get update && apt-get install -y \
    git \
    curl \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Instala Node.js 23 via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_23.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Instala headroom (proxy de compressão de contexto) + build deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    build-essential \
    && pip3 install "headroom-ai[proxy]" --break-system-packages \
    && apt-get purge -y build-essential \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Instala o Pi Agent globalmente via NPM
RUN npm install -g @earendil-works/pi-coding-agent

# Instala as extensões do Pi
RUN npm install -g pi-mcp-adapter pi-web-access

# Script de entrada que inicia headroom proxy + Pi Agent
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Define o diretório onde você vai mapear o código do seu projeto
WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
