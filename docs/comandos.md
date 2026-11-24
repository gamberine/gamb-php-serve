# Comandos

## `gamb-php-serve`

Inicia o servidor do projeto atual.

```bash
gamb-php-serve
gamb-php-serve --port 8080
gamb-php-serve --foreground
gamb-php-serve --stop
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

`gamb-php-serve --stop` e um atalho equivalente para parar o projeto registrado na pasta atual.

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

## `gamb-php-discover`

Descobre projetos PHP em pastas locais e, com `--register`, adiciona-os ao catalogo do hub sem alterar os arquivos dos projetos.

```bash
gamb-php-discover
gamb-php-discover --root /d/ProjetosWeb --register
gamb-php-discover --json
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

Inicia manualmente um perfil MySQL/MariaDB. Para WordPress e Laravel com banco local, o `gamb-php-serve` faz essa etapa automaticamente.

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

## `gamb-php-db-shell`

Abre o cliente MySQL/MariaDB detectado, sem armazenar ou expor a senha na linha de comando.

```bash
gamb-php-db-shell
gamb-php-db-shell --profile mysql-wamp64-8.0.31 --database nome_do_banco
```

## `gamb-php-wp-install`

Prepara uma nova instalacao a partir de uma copia local do WordPress. O destino deve ser novo ou vazio.

```bash
gamb-php-wp-install --source /d/ProjetosWeb/wordpress --destination /d/ProjetosWeb/novo-site --db-name novo_site
```

## `gamb-php-wp-move`

Gera um plano de movimentacao por padrao. `--execute` copia os arquivos; `--include-db` tambem exporta o banco local quando houver um perfil e cliente de dump disponiveis.

```bash
gamb-php-wp-move --source /d/ProjetosWeb/wordpress --destination /d/ProjetosWeb/novo-site
gamb-php-wp-move --source /d/ProjetosWeb/wordpress --destination /d/ProjetosWeb/novo-site --execute --include-db
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
