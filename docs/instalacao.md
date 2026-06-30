# Instalação

O instalador copia os comandos para `~/.local/bin`, as bibliotecas para `~/.config/gamb-php/lib` e cria os diretorios de estado em `~/.local/state/gamb-php`.

## Requisitos

- Bash compatível com Git Bash no Windows.
- `php` no `PATH`, ou `GAMB_PHP_BIN` apontando para um executável PHP portátil.
- `curl` ou `wget` para instalação remota.

## Instalação principal

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

## O que o instalador faz

- Cria `~/.local/bin`.
- Cria `~/.config/gamb-php`.
- Cria `~/.local/state/gamb-php/pids`.
- Cria `~/.local/state/gamb-php/logs`.
- Cria `~/.local/state/gamb-php/routers`.
- Cria `~/.local/state/gamb-php/db/pids`.
- Cria `~/.local/state/gamb-php/db/logs`.
- Cria `~/.local/state/gamb-php/db/meta`.
- Cria `~/.config/gamb-php/share/dashboard`.
- Cria `~/.config/gamb-php/share/assets`.
- Copia os scripts globais de projeto e do modulo opcional de banco.
- Copia o hub local e os assets visuais.
- Adiciona `~/.local/bin` no `~/.bashrc`.
- Adiciona o hook de auto-start no `~/.bashrc`.

## Depois da instalacao

Ao iniciar um projeto com `gamb-php-serve`, o navegador passa a abrir o painel em:

```text
http://localhost:PORTA/__gamb_php__/hub
```

A URL principal do projeto continua sendo impressa no terminal e fica acessivel no primeiro card do painel.

## Modulo opcional de banco

Depois da instalacao, o modulo MySQL/MariaDB fica disponivel sem alterar o uso atual do `gamb-php-serve`:

```bash
gamb-php-db-check
gamb-php-db-start
gamb-php-db-status
gamb-php-db-stop
```
