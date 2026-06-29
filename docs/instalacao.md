# Instalação

O instalador copia os comandos para `~/.local/bin`, a biblioteca comum para `~/.config/gamb-php/lib` e cria os diretórios de estado em `~/.local/state/gamb-php`.

## Requisitos

- Bash compatível com Git Bash no Windows.
- `php` no `PATH`, ou `GAMB_PHP_BIN` apontando para um executável PHP portátil.
- `curl` ou `wget` para instalação remota.

## Instalação principal

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/gamberine/gamb_php_serve/main/install.sh)"
```

## Instalação alternativa

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/gamberine/gamb_php_serve/main/install.sh)"
```

## Instalação via CDN

```bash
bash -c "$(curl -fsSL https://cdn.jsdelivr.net/gh/gamberine/gamb_php_serve@main/install.sh)"
```

## O que o instalador faz

- Cria `~/.local/bin`.
- Cria `~/.config/gamb-php`.
- Cria `~/.local/state/gamb-php/pids`.
- Cria `~/.local/state/gamb-php/logs`.
- Cria `~/.local/state/gamb-php/routers`.
- Copia os scripts globais.
- Adiciona `~/.local/bin` no `~/.bashrc`.
- Adiciona o hook de auto-start no `~/.bashrc`.

