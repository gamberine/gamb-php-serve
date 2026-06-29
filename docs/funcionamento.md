# Funcionamento

O fluxo é global ao usuário e não altera arquivos versionados do projeto PHP.

## Registro

Quando `gamb-php-serve` é executado em um projeto reconhecido, a pasta é registrada em `~/.config/gamb-php/projects.tsv`.

Formato:

```text
slug<TAB>path<TAB>type<TAB>host<TAB>port<TAB>docroot<TAB>index
```

## Tipos reconhecidos

- `laravel` quando existe `artisan`
- `php_public` quando existe `public/index.php`
- `wordpress` quando existem `wp-config.php` e `index.php`
- `php_root` quando existe `index.php`

## Porta

O padrão é `8000`. Se a porta estiver ocupada, a ferramenta tenta `8001` até `8005`.

## Servidor

- `laravel` usa `php artisan serve --host=127.0.0.1 --port=PORT`
- os demais usam `php -S 127.0.0.1:PORT -t DOCROOT ROUTER`

## Auto-start

O instalador adiciona um hook no `~/.bashrc` que chama `gamb-php-auto` no prompt. Quando a pasta atual coincide com um projeto registrado e o servidor não está rodando, ele sobe silenciosamente.

