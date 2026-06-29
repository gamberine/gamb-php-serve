# Gamberine PHP serve 

Ferramenta Bash global para rodar projetos PHP localmente sem Laragon, WAMP, XAMPP ou Apache externo.

## O que faz

- Registra projetos PHP no seu usuário.
- Sobe servidor local usando o PHP built-in server ou `php artisan serve`.
- Abre a URL no navegador padrao quando `gamb-php-serve` e executado manualmente.
- Recarrega a pagina automaticamente ao salvar arquivos do projeto enquanto o servidor estiver rodando.
- Auto-inicia ao entrar novamente na pasta de um projeto registrado.
- Exibe e abre URLs como `http://localhost:PORTA/...`, mantendo o bind local em `127.0.0.1`.
- Não altera o repositório do projeto.
- Não cria arquivos dentro do projeto.
- Detecta Laravel, WordPress, PHP com `public/` e PHP simples.
- Respeita prefixos locais como `/admin` e `/extranet` quando definidos no `config/local.php`.
- Permite subir outra instância manual do mesmo projeto em outra janela usando apenas `--port`.

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

Para rodar o mesmo projeto em outra janela do VS Code, basta informar outra porta:

```bash
gamb-php-serve --port 8081
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

## Variaveis opcionais

Para nao abrir o navegador automaticamente:

```bash
export GAMB_PHP_NO_BROWSER=1
```

Para desativar o live reload automatico ao salvar:

```bash
export GAMB_PHP_NO_LIVE_RELOAD=1
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
- Exibe `localhost` na URL por conveniencia, mas continua ouvindo apenas no loopback local.
- Não expõe na rede.
- Não altera arquivos do projeto.
- Não deve ser usado em produção.
