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
FROM node:22-slim

# Instala dependências essenciais de terminal que o Pi usa para o comando 'bash'
RUN apt-get update && apt-get install -y \
    git \
    curl \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Instala o Pi Agent globalmente via NPM
RUN npm install -g @earendil-works/pi-coding-agent

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
alias pi-docker='docker run -it --rm -v "$(pwd)":/workspace -v pi_config:/root/.config/pi -v ~/.gitconfig:/root/.gitconfig:ro --env-file ~/.pi-env meu-pi-agent'
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
- -v "$(pwd)":/workspace: Pega o caminho da pasta atual onde você está no seu computador (pwd) e joga para dentro do ambiente de trabalho do Pi Agent.
- --env-file ~/.pi-env: Injeta as chaves de API que você salvou de forma centralizada.
- -v pi_config:/root/.config/pi: Garante que, mesmo mudando de projeto, o Pi Agent ainda lembre das suas preferências, histórico global e configurações internas.
