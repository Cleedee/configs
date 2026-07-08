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

O script cuida de tudo automaticamente: constrói a imagem Docker, cria o arquivo de variáveis de ambiente, prepara o volume de configuração com as extensões e adiciona o alias `pi-docker` ao seu profile do shell.

---

## Conteúdo da imagem

A imagem (`ubuntu:24.04`) já vem com:

| Recurso | Detalhes |
|---|---|
| **Node.js 23** | Runtime do Pi Agent |
| **Pi Agent** | `@earendil-works/pi-coding-agent` instalado globalmente |
| **Extensões** | `pi-mcp-adapter` e `pi-web-access` pré-instaladas e ativadas no `settings.json` |
| **uv** | Gerenciador de pacotes Python (instalado via `astral.sh`) |
| **git, curl, vim** | Utilitários essenciais de terminal |

## Passo 1. Construa a imagem Docker uma única vez

```bash
docker build -t meu-pi-agent .
```

## Passo 2. Centralize suas chaves de API

```bash
nano ~/.pi-env
```

```
OPENAI_API_KEY=sk-proj-...
ANTHROPIC_API_KEY=sk-ant-...
DEEPSEEK_API_KEY=sk-...
```

## Passo 3: Criar o atalho (Alias ou Script)

```bash
vim ~/.bashrc
```

```bash
alias pi-docker='docker run -it --rm \
  -v "$(pwd)":/workspace \
  -v pi_config:/root/.pi/agent \
  -v ~/.gitconfig:/root/.gitconfig:ro \
  --env-file ~/.pi-env \
  meu-pi-agent'
```

## Como usar no dia a dia?

```bash
# Vá para o Projeto A
cd ~/Projetos/meu-app-react
pi-docker

# Vá para o Projeto B (em outra pasta completamente diferente)
cd /var/www/site-institucional
pi-docker
```

## O que esse comando faz por baixo dos panos?

- `-it --rm`: Abre o Pi de forma interativa no terminal e destrói o contêiner temporário assim que você digita exit, sem deixar resíduos.
- `-v "$(pwd)":/workspace`: Pega o caminho da pasta atual onde você está e joga para dentro do ambiente de trabalho do Pi Agent.
- `--env-file ~/.pi-env`: Injeta as chaves de API que você salvou de forma centralizada.
- `-v pi_config:/root/.pi/agent`: Persiste configurações, histórico e preferências do Pi entre sessões, independente do projeto. Na primeira execução, o volume é semeado automaticamente com o `settings.json` padrão (contendo as extensões ativadas).

## Estrutura do projeto

```
pi-coding-agent/
├── Dockerfile           # Imagem base do Pi Agent
├── setup-pi-agent.sh    # Script de setup para Linux/macOS
├── setup-pi-agent.ps1   # Script de setup para Windows
└── README.md            # Esta documentação
```