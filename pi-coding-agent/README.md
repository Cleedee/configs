## Instalação automatizada (Recomendado)

Com um único comando você baixa o script de configuração e já executa:

### Linux / macOS (bash)

```bash
curl -fsSL -o setup-pi-agent.sh https://raw.githubusercontent.com/Cleedee/configs/main/pi-coding-agent/setup-pi-agent.sh && chmod +x setup-pi-agent.sh && ./setup-pi-agent.sh
```

### Windows (PowerShell)

```powershell
powershell -c "iwr -UseBasicParsing -Uri 'https://raw.githubusercontent.com/Cleedee/configs/main/pi-coding-agent/setup-pi-agent.ps1' -OutFile setup-pi-agent.ps1; .\setup-pi-agent.ps1"
```

O script cuida de tudo automaticamente: constrói a imagem Docker, cria o arquivo de variáveis de ambiente e adiciona o alias `pi-docker` ao seu profile do shell.

---

## Passo 0. Dockerfile

```
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

# Baixa o Python 3.12 gerenciado pelo uv em um caminho system-wide
ENV UV_PYTHON_INSTALL_DIR=/usr/local/share/uv/python
RUN uv python install 3.12 && \
    chmod -R a+rX /usr/local/share/uv

# Instala o Pi Agent globalmente via NPM
RUN npm install -g @earendil-works/pi-coding-agent

# Agent dir do Pi = mesmo caminho do volume montado no alias (pi_config)
ENV PI_CODING_AGENT_DIR=/tmp/.config/pi
RUN mkdir -p "${PI_CODING_AGENT_DIR}" && chmod -R a+rwX "${PI_CODING_AGENT_DIR}"

# Template do settings.json padrão (declara as extensões do Pi).
# O volume é semeado com ele pelo setup-pi-agent.*
RUN mkdir -p /opt/pi-defaults && \
    echo '{"packages":["npm:pi-mcp-adapter","npm:pi-web-access","npm:@sentiolabs/pi-frontend-design"]}' \
    > /opt/pi-defaults/settings.json

# Define o diretório onde você vai mapear o código do seu projeto
WORKDIR /workspace

# O Pi roda interativamente, então definimos o entrypoint para ele
ENTRYPOINT ["pi"]
```

> **Por que declarar as extensões em `settings.json`?** O Pi só carrega pacotes
> que estejam na lista `packages` do agent dir (`~/.pi/agent/settings.json`).
> Um `npm install -g` sozinho **não** ativa a extensão.

## Passo 1. Construa a imagem Docker uma única vez

```
docker build -t meu-pi-agent .
```

## Passo 2. Centralize suas chaves de API

nano ~/.pi-env

```
OPENAI_API_KEY=sk-proj-...
ANTHROPIC_API_KEY=sk-ant-...
DEEPSEEK_API_KEY=sk-ant-...
```

## Passo 3: Criar o atalho (Alias ou Script)

vim ~/.bashrc

```
alias pi-docker='docker run -it --rm --user "$(id -u):$(id -g)" -v "$(pwd)":/workspace -v pi_config:/tmp/.config/pi -v ~/.gitconfig:/tmp/.gitconfig:ro -v ~/.cache:/tmp/.cache --env-file ~/.pi-env -e HOME=/tmp -e PIP_CACHE_DIR=/tmp/.cache/pip -e UV_CACHE_DIR=/tmp/.cache/uv meu-pi-agent'
```

## Como usar no dia a dia?

```
# Vá para o Projeto A
cd ~/Projetos/meu-app-react
pi-docker

# Vá para o Projeto B (em outra pasta completamente diferente)
cd /var/www/site-institucional
pi-docker
```

## O que esse comando mágico faz por baixo dos panos?

- -it --rm: Abre o Pi de forma interativa no terminal e destrói o contêiner temporário assim que você digita exit, sem deixar resíduos.
- --user "$(id -u):$(id -g)": Faz o container rodar com o mesmo UID/GID do seu usuário host. Isso evita que arquivos criados pelo container (ex: `.venv/`, `node_modules/`) fiquem com dono `root` e você perca permissão de editá-los depois.
- -v "$(pwd)":/workspace: Pega o caminho da pasta atual onde você está no seu computador (pwd) e joga para dentro do ambiente de trabalho do Pi Agent.
- --env-file ~/.pi-env: Injeta as chaves de API que você salvou de forma centralizada.
- -v pi_config:/tmp/.config/pi: Garante que, mesmo mudando de projeto, o Pi Agent ainda lembre das suas preferências, histórico global e configurações internas. O caminho bate com `PI_CODING_AGENT_DIR` definido na imagem — por isso o Pi realmente persiste a config (com `HOME=/tmp`, o padrão `~/.pi/agent` **não** apontaria para o volume).
- -v ~/.cache:/tmp/.cache + -e PIP_CACHE_DIR=/tmp/.cache/pip + -e UV_CACHE_DIR=/tmp/.cache/uv: Compartilha os caches do pip e do uv entre host e container, evitando baixar pacotes repetidamente.
- -e HOME=/tmp: Define um diretório home gravável para ferramentas como pip e git (já que o `/root` original não seria gravável com `--user`).

## Python e uv

A imagem instala o [uv](https://docs.astral.sh/uv/) em `/usr/local/bin` e baixa o
**Python 3.12** gerenciado pelo uv em `/usr/local/share/uv/python` (caminho
system-wide, acessível mesmo com `--user`/`HOME=/tmp`):

```bash
uv python list          # mostra o 3.12 disponível
uv venv --python 3.12   # cria um venv com Python 3.12
```
