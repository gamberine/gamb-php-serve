# Gamberine PHP serve 

Ferramenta Bash global para rodar projetos PHP localmente sem Laragon, WAMP, XAMPP ou Apache externo.

## O que faz

- Registra projetos PHP no seu usuário.
- Sobe servidor local usando o PHP built-in server ou `php artisan serve`.
- Auto-inicia ao entrar novamente na pasta de um projeto registrado.
- Não altera o repositório do projeto.
- Não cria arquivos dentro do projeto.
- Detecta Laravel, WordPress, PHP com `public/` e PHP simples.

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

## Depois de implantado

Ao entrar novamente na pasta do projeto pelo Git Bash, o servidor sobe automaticamente se o projeto já estiver registrado.

## Comandos

- `gamb-php-serve`
- `gamb-php-status`
- `gamb-php-stop`
- `gamb-php-list`
- `gamb-php-remove`
- `gamb-php-check`

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
```

## Diretórios usados

- `~/.local/bin`
- `~/.config/gamb-php`
- `~/.local/state/gamb-php`

## PHP portátil

Se você usa PHP portátil, defina:

```bash
export GAMB_PHP_BIN="/d/tools/php/php.exe"
```

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
- Não expõe na rede.
- Não altera arquivos do projeto.
- Não deve ser usado em produção.
