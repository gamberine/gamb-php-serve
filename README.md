# gamb-php-serve

> Seu ambiente PHP local, organizado, seguro e pronto para trabalhar.

O `gamb-php-serve` transforma o computador de desenvolvimento em um centro de operacoes para projetos PHP, WordPress e Laravel. Ele registra projetos locais, descobre instalacoes existentes, inicia PHP e MySQL/MariaDB diretamente pelos binarios instalados e oferece um hub visual para executar as acoes do dia a dia.

## Produto

- **Praticidade:** um comando inicia o projeto, abre o painel e mostra a URL correta.
- **Seguranca:** o servico escuta no loopback, nao altera o codigo do projeto e evita comandos livres no painel e na extensao.
- **Independencia:** Laragon, WAMP ou XAMPP podem continuar instalados, mas nao precisam ficar abertos em paralelo.
- **Visibilidade:** projetos, portas, processos, logs e bancos aparecem em um catalogo local.
- **Evolucao:** o mesmo nucleo atende Bash, CMD, PowerShell, VS Code e um contrato local para Antigravity.

Leia o [manual do produto](docs/manual.md) ou abra a [apresentacao no GitHub Pages](https://gamberine.github.io/gamb-php-serve/).

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
- Integra MySQL/MariaDB local ao fluxo do `serve` para WordPress e Laravel, sem exigir Laragon ou WAMP aberto.

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
- `gamb-php-discover`
- `gamb-php-db-check`
- `gamb-php-db-status`
- `gamb-php-db-start`
- `gamb-php-db-stop`
- `gamb-php-db-shell`
- `gamb-php-wp-install`
- `gamb-php-wp-move`

## Exemplos

```bash
gamb-php-serve
gamb-php-serve --port 8080
gamb-php-serve --foreground
gamb-php-serve --stop
gamb-php-status
gamb-php-status --all
gamb-php-stop
gamb-php-stop --all
gamb-php-list
gamb-php-remove
gamb-php-remove --with-logs
gamb-php-discover --register
gamb-php-wp-install --help
gamb-php-wp-move --help
gamb-php-db-shell --help
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
- Acoes rapidas com comandos preparados para CMD, PowerShell e Bash, incluindo a gestao integrada do banco local.
- Extensao VS Code local em `extension/`, com dashboard lateral, comandos de projeto, descoberta e acoes WordPress guiadas.

## WordPress local e movimentacao

Prepare uma nova copia a partir de uma instalacao WordPress local, sem download ou sobrescrita do destino:

```bash
gamb-php-wp-install --source /d/ProjetosWeb/wordpress --destination /d/ProjetosWeb/novo-site --db-name novo_site
```

O banco deve ser criado ou importado separadamente. Para planejar uma movimentacao, use o modo simulacao:

```bash
gamb-php-wp-move --source /d/ProjetosWeb/wordpress --destination /d/ProjetosWeb/novo-site
gamb-php-wp-move --source /d/ProjetosWeb/wordpress --destination /d/ProjetosWeb/novo-site --execute --include-db
```

O fluxo remoto nao publica sozinho: ele copia os arquivos, pode exportar `database.sql` e exige revisao de `wp-config.php`, URLs e permissao antes do envio. Isso permite integrar o pacote gerado ao `gamb-duplica-wp` sem acoplar credenciais ou uma API externa.

## Acesso ao banco

Abra o cliente MySQL/MariaDB detectado pelo modulo, com senha solicitada de forma interativa:

```bash
gamb-php-db-shell
gamb-php-db-shell --profile mysql-wamp64-8.0.31 --database nome_do_banco
```

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

## Integracao MySQL/MariaDB

Para WordPress e Laravel configurados com MySQL/MariaDB local, `gamb-php-serve` inicia o banco diretamente pelos binarios detectados. Nao e necessario abrir Laragon, WAMP ou outro painel em paralelo.

O banco ainda precisa estar instalado na maquina. O `gamb-php-serve` gerencia o processo do servidor, o PID, os logs e a parada sem iniciar a interface do pacote.

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

Projetos com banco remoto nao acionam banco local. Para desativar a inicializacao automatica:

```bash
export GAMB_PHP_DB_AUTO_START=0
```

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
# Atalho equivalente pelo comando principal
gamb-php-serve --stop
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
- O modulo inicia automaticamente o banco local exigido por WordPress/Laravel e preserva bancos remotos.
- Não deve ser usado em produção.

## Roadmap seguro

Os proximos blocos do produto sao o instalador WordPress completo, a movimentacao assistida para um servidor, a integracao executavel com `gamb-duplica-wp` e uma interface visual de tabelas. Esses fluxos nao sao acionados automaticamente: exigem origem, destino, credenciais e politica de sobrescrita definidos pelo operador.
