# Gamberine PHP serve 

Ferramenta Bash global para rodar projetos PHP localmente sem Laragon, WAMP, XAMPP ou Apache externo.

## O que faz

- Registra projetos PHP no seu usuário.
- Sobe servidor local usando o PHP built-in server ou `php artisan serve`.
- Abre um hub visual em `localhost` com projetos recentes, lista lateral e acoes rapidas.
- Abre a URL no navegador padrao quando `gamb-php-serve` e executado manualmente.
- Recarrega a pagina automaticamente ao salvar arquivos do projeto enquanto o servidor estiver rodando.
- Auto-inicia ao entrar novamente na pasta de um projeto registrado.
- Exibe e abre URLs como `http://localhost:PORTA/...`, mantendo o bind local em `127.0.0.1`.
- Não altera o repositório do projeto.
- Não cria arquivos dentro do projeto.
- Detecta Laravel, WordPress, PHP com `public/` e PHP simples.
- Respeita prefixos locais como `/admin` e `/extranet` quando definidos no `config/local.php`.
- Permite subir outra instância manual do mesmo projeto em outra janela usando apenas `--port`.
- Inclui um modulo opcional de banco para iniciar e parar MySQL/MariaDB local sem acoplar isso ao fluxo atual do `serve`.

## Instalação em uma linha

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/gamberine/gamb-php-serve/main/install.sh)"
```

## Instalação alternativa

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/gamberine/gamb-php-serve/main/install.sh)"
```

## Instalação via CDN

```bash
bash -c "$(curl -fsSL https://cdn.jsdelivr.net/gh/gamberine/gamb-php-serve@main/install.sh)"
```

## Primeiro uso

```bash
cd /d/ProjetosGit/meu-projeto
gamb-php-serve
```

Depois do start manual, o navegador abre o painel do servico em:

```text
http://localhost:PORTA/__gamb_php__/hub
```

A URL principal do projeto continua impressa no terminal e disponivel no primeiro card do painel.

## Depois de implantado

Ao entrar novamente na pasta do projeto pelo Git Bash, o servidor sobe automaticamente se o projeto já estiver registrado.

## Comandos

- `gamb-php-serve`
- `gamb-php-status`
- `gamb-php-stop`
- `gamb-php-list`
- `gamb-php-remove`
- `gamb-php-check`
- `gamb-php-db-check`
- `gamb-php-db-status`
- `gamb-php-db-start`
- `gamb-php-db-stop`

## Exemplos

```bash
gamb-php-serve
gamb-php-serve --port 8080
gamb-php-serve --foreground
gamb-php-status
gamb-php-status --all
gamb-php-stop
gamb-php-stop --all
gamb-php-list
gamb-php-remove
gamb-php-remove --with-logs
gamb-php-db-check
gamb-php-db-status
gamb-php-db-start
gamb-php-db-start mariadb
gamb-php-db-stop
```

Para rodar o mesmo projeto em outra janela do VS Code, basta informar outra porta:

```bash
gamb-php-serve --port 8081
```

## Dashboard local

- Grid com os 4 projetos mais recentes.
- Lista lateral rolavel com os demais projetos implantados.
- Cards com nome, logo/favicon quando existir, URL e status.
- Acoes rapidas com comandos preparados para CMD, PowerShell e Bash, incluindo o modulo opcional de banco.
- Ponte de VS Code pronta para uma extensao complementar futura, com copia de comando como fallback imediato.

## GitHub Pages

O repositorio agora inclui uma landing em `docs/index.html` e o workflow `.github/workflows/pages.yml` para publicar a apresentacao do `gamb-php-serve` usando a mesma linguagem visual do painel local.

Se o repositorio ainda nao tiver GitHub Pages habilitado, a primeira execucao do workflow pode falhar com
`Not Found` ao consultar a API de Pages. Nesse caso, existem dois caminhos validos:

1. habilitar o Pages em `Settings > Pages` e selecionar `GitHub Actions`;
2. criar o secret `GH_PAGES_TOKEN` com permissao administrativa no repositorio para que o workflow tente
   fazer a enablement automaticamente.

## Diretórios usados

- `~/.local/bin`
- `~/.config/gamb-php`
- `~/.local/state/gamb-php`

## PHP portátil

Se você usa PHP portátil, defina:

```bash
export GAMB_PHP_BIN="/d/tools/php/php.exe"
```

## Modulo de banco opcional

O `gamb-php-serve` continua funcionando sem banco local. A MV2 apenas adiciona comandos paralelos para detectar e orquestrar MySQL/MariaDB quando houver binarios locais disponiveis.

Fluxo rapido:

```bash
gamb-php-db-check
gamb-php-db-start
gamb-php-db-status
gamb-php-db-stop
```

Selecao explicita:

```bash
gamb-php-db-start mysql
gamb-php-db-start mariadb
gamb-php-db-stop all
```

O modulo nao altera o comportamento atual do `gamb-php-serve` e nao faz auto-start de banco ao entrar no projeto.

## Variaveis opcionais

Para nao abrir o navegador automaticamente:

```bash
export GAMB_PHP_NO_BROWSER=1
```

Para desativar o live reload automatico ao salvar:

```bash
export GAMB_PHP_NO_LIVE_RELOAD=1
```

Para definir um perfil de banco preferencial:

```bash
export GAMB_PHP_DB_PROFILE="mysql-wamp64-8.0.31"
```

Para ampliar a varredura de instalacoes locais:

```bash
export GAMB_PHP_DB_SCAN_ROOTS="/d/ProjetosWeb/wamp64/bin;/d/laragon/bin"
```

## Portfolio de solucoes

O hub local e a GitHub Pages ja incluem um bloco dinamico preparado para buscar dados do repositorio `gamb-portfolio-solucoes`. Se o feed ainda nao existir, entram cards de fallback.

## Como parar

```bash
gamb-php-stop
```

## Como remover um projeto

```bash
gamb-php-remove
```

## Como desinstalar

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/gamberine/gamb-php-serve/main/uninstall.sh)"
```

## Segurança

- Usa `127.0.0.1`.
- Exibe `localhost` na URL por conveniencia, mas continua ouvindo apenas no loopback local.
- Não expõe na rede.
- Não altera arquivos do projeto.
- O modulo de banco so atua quando os novos comandos `gamb-php-db-*` sao executados.
- Não deve ser usado em produção.
