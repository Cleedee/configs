FROM ubuntu:24.04

# Evita prompts interativos durante instalação do apt
ENV DEBIAN_FRONTEND=noninteractive

# Instala dependências essenciais de terminal que o Pi usa para o comando 'bash'
RUN apt-get update && apt-get install -y \
    git \
    curl \
    vim \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Instala Node.js 23 via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_23.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Instala uv (gerenciador de pacotes Python)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Adiciona uv ao PATH (o instalador coloca em ~/.local/bin)
ENV PATH="/root/.local/bin:${PATH}"

# Instala o Pi Agent e o servidor MCP do Playwright globalmente
RUN npm install -g \
    @earendil-works/pi-coding-agent playwright

# Instala as dependências de SO do Linux e o Chromium headless do Playwright
RUN npx playwright install --with-deps chromium

# Instala as extensões do Pi
RUN npm install -g pi-mcp-adapter pi-web-access

# Cria diretório de configuração do Pi com settings.json padrão
RUN mkdir -p /root/.pi/agent && \
    echo '{"packages":["npm:pi-mcp-adapter","npm:pi-web-access"]}' \
    > /root/.pi/agent/settings.json && \
    chmod -R a+rwX /root/.pi

# (Opcional) Cria a configuração global do MCP já com o Playwright habilitado
RUN mkdir -p /root/.config/mcp && \
    echo '{\
  "mcpServers": {\
    "playwright": {\
      "command": "npx",\
      "args": ["-y", "@executeautomation/playwright-mcp-server"]\
    }\
  }\
}' > /root/.config/mcp/mcp.json

# Define o diretório onde você vai mapear o código do seu projeto
WORKDIR /workspace

# O Pi roda interativamente, então definimos o entrypoint para ele
ENTRYPOINT ["pi"]
