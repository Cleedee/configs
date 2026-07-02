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

# Instala dependências essenciais de terminal que o Pi usa para o comando 'bash'
RUN apt-get update && apt-get install -y \
    git \
    curl \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Instala Node.js 24 via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Instala o Pi Agent globalmente via NPM
RUN npm install -g @earendil-works/pi-coding-agent

# Instala as extensões do Pi
RUN npm install -g pi-mcp-adapter pi-web-access npm:@sentiolabs/pi-frontend-design

# Define o diretório onde você vai mapear o código do seu projeto
WORKDIR /workspace

# O Pi roda interativamente, então definimos o entrypoint para ele
ENTRYPOINT ["pi"]
```

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
alias pi-docker='docker run -it --rm --user "$(id -u):$(id -g)" -v "$(pwd)":/workspace -v pi_config:/tmp/.config/pi -v ~/.gitconfig:/tmp/.gitconfig:ro -v ~/.cache:/tmp/.cache --env-file ~/.pi-env -e HOME=/tmp -e PIP_CACHE_DIR=/tmp/.cache/pip meu-pi-agent'
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
- -v pi_config:/tmp/.config/pi: Garante que, mesmo mudando de projeto, o Pi Agent ainda lembre das suas preferências, histórico global e configurações internas.
- -v ~/.cache:/tmp/.cache + -e PIP_CACHE_DIR=/tmp/.cache/pip: Compartilha o cache do pip entre host e container, evitando baixar pacotes repetidamente.
- -e HOME=/tmp: Define um diretório home gravável para ferramentas como pip e git (já que o `/root` original não seria gravável com `--user`).
