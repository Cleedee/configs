FROM ubuntu:25.10

# Evita prompts interativos durante a instalação do apt
ENV DEBIAN_FRONTEND=noninteractive

# Instala dependências essenciais de terminal que o Pi usa para o comando 'bash'
RUN apt-get update && apt-get install -y \
    git \
    curl \
    vim \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Instala Node.js 24 via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Instala uv (gerenciador de pacotes Python) em /usr/local/bin.
# Fica fora do HOME para sobreviver ao --user/HOME=/tmp usado no container.
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

# Baixa o Python 3.12 gerenciado pelo uv em um caminho system-wide,
# acessível também quando o container roda com --user (HOME=/tmp)
ENV UV_PYTHON_INSTALL_DIR=/usr/local/share/uv/python
RUN uv python install 3.12 && \
    chmod -R a+rX /usr/local/share/uv

# Instala o Pi Agent globalmente via NPM
RUN npm install -g @earendil-works/pi-coding-agent

# Agent dir do Pi: precisa ser igual ao volume montado no alias (pi_config).
# Definido explicitamente porque, com HOME=/tmp, o padrão (~/.pi/agent)
# não apontaria para o volume e a config/histórico não seriam persistidos.
ENV PI_CODING_AGENT_DIR=/tmp/.config/pi
RUN mkdir -p "${PI_CODING_AGENT_DIR}" && chmod -R a+rwX "${PI_CODING_AGENT_DIR}"

# Template do settings.json padrão, que declara os pacotes (extensões) do Pi.
# Sem isso, os pacotes instalados não são carregados. O volume pi_config é
# semeado com este arquivo pelo setup-pi-agent.sh / setup-pi-agent.ps1.
RUN mkdir -p /opt/pi-defaults && \
    echo '{"packages":["npm:pi-mcp-adapter","npm:pi-web-access","npm:@sentiolabs/pi-frontend-design"]}' \
    > /opt/pi-defaults/settings.json

# Define o diretório onde você vai mapear o código do seu projeto
WORKDIR /workspace

# O Pi roda interativamente, então definimos o entrypoint para ele
ENTRYPOINT ["pi"]
