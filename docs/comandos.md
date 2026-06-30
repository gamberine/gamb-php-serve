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

## `gamb-php-db-check`

Descobre instalacoes locais de MySQL/MariaDB e mostra o perfil sugerido.

```bash
gamb-php-db-check
```

## `gamb-php-db-status`

Mostra o estado dos perfis de banco conhecidos.

```bash
gamb-php-db-status
gamb-php-db-status mysql
gamb-php-db-status mariadb
```

## `gamb-php-db-start`

Inicia o perfil sugerido ou um engine especifico, sem acoplar o banco ao `gamb-php-serve`.

```bash
gamb-php-db-start
gamb-php-db-start mysql
gamb-php-db-start mariadb
```

## `gamb-php-db-stop`

Para os bancos gerenciados pelo modulo.

```bash
gamb-php-db-stop
gamb-php-db-stop all
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
- acoes extras para detectar, iniciar, verificar e parar MySQL/MariaDB local.
- copia imediata de comandos e ponte preparada para terminal do VS Code.
