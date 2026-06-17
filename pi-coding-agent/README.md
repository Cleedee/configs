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
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y git curl vim && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_23.x | bash - \
    && apt-get install -y nodejs && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv build-essential \
    && pip3 install "headroom-ai[proxy]" --break-system-packages \
    && apt-get purge -y build-essential && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @earendil-works/pi-coding-agent pi-mcp-adapter pi-web-access

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace
ENTRYPOINT ["/entrypoint.sh"]
```

## Passo 1. Construa a imagem Docker uma única vez

```
docker build -t meu-pi-agent .
```

### Headroom: compressão automática de contexto

Esta imagem inclui o [Headroom](https://github.com/chopratejas/headroom) — um proxy que comprime todo o contexto (tool outputs, logs, arquivos, RAG) antes de enviar ao LLM, reduzindo tokens em **60–95%** sem perder respostas.

O entrypoint inicia o headroom em background e configura o Pi Agent para rotear chamadas via proxy. Tudo transparente.

Se você tem `OPENROUTER_API_KEY` no `~/.pi-env`, o proxy já inicia apontando para OpenRouter automaticamente.

Para ver estatísticas de compressão:

```bash
# Em outro terminal, com o container rodando:
curl http://localhost:8787/stats
```

Provedores configurados automaticamente via proxy:

| Provider         | Como usar no Pi                          |
|------------------|------------------------------------------|
| OpenRouter       | `pi --provider openrouter`               |
| OpenCode Zen     | `pi --provider opencode`                 |
| OpenCode Go      | `pi --provider opencode-go`              |

Use normalmente com `pi --provider openrouter --model <modelo>`. O headroom comprime o contexto antes de enviar ao OpenRouter/OpenCode.

## Passo 2. Centralize suas chaves de API

nano ~/.pi-env

```
OPENROUTER_API_KEY=sk-or-...
OPENCODE_API_KEY=sk-oc-...
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
- Headroom (auto-iniciado): Um proxy de compressão de contexto que reduz tokens em até 95% sem você precisar configurar nada. Para ver estatísticas ao vivo, adicione `-p 8787:8787` ao comando e acesse `curl localhost:8787/stats`.
