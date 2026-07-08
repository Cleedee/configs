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

# Instala uv (gerenciador de pacotes Python)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Instala o Pi Agent globalmente via NPM
RUN npm install -g @earendil-works/pi-coding-agent

# Instala as extensões do Pi
RUN npm install -g pi-mcp-adapter pi-web-access

# Cria diretório de configuração do Pi com settings.json padrão
# (inclui as extensões instaladas acima para que sejam ativadas)
RUN mkdir -p /root/.pi/agent && \
    echo '{"packages":["npm:pi-mcp-adapter","npm:pi-web-access"]}' \
    > /root/.pi/agent/settings.json

# Define o diretório onde você vai mapear o código do seu projeto
WORKDIR /workspace

# O Pi roda interativamente, então definimos o entrypoint para ele
ENTRYPOINT ["pi"]
