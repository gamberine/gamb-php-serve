# Comandos

## `gamb-php-serve`

Inicia o servidor do projeto atual.

```bash
gamb-php-serve
gamb-php-serve --port 8080
gamb-php-serve --foreground
```

Ao iniciar manualmente, abre o hub visual do servico em `localhost`.

## `gamb-php-auto`

Executado automaticamente pelo `~/.bashrc` para iniciar projetos registrados ao entrar na pasta.

## `gamb-php-status`

Mostra o status do projeto atual.

```bash
gamb-php-status
gamb-php-status --all
```

## `gamb-php-stop`

Para o projeto atual ou todos os projetos.

```bash
gamb-php-stop
gamb-php-stop --all
```

## `gamb-php-list`

Lista todos os projetos registrados.

```bash
gamb-php-list
```

## `gamb-php-remove`

Remove o projeto atual do registro.

```bash
gamb-php-remove
gamb-php-remove --with-logs
```

## `gamb-php-check`

Mostra informações do ambiente atual.

```bash
gamb-php-check
```

## Hub visual

Rota reservada do painel:

```text
/__gamb_php__/hub
```

O hub traz:

- 4 projetos recentes em destaque.
- lista lateral com os demais projetos registrados.
- comandos preparados para CMD, PowerShell e Bash.
- copia imediata de comandos e ponte preparada para terminal do VS Code.
