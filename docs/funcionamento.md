# Funcionamento

O fluxo é global ao usuário e não altera arquivos versionados do projeto PHP.

## Registro

Quando `gamb-php-serve` é executado em um projeto reconhecido, a pasta é registrada em `~/.config/gamb-php/projects.tsv`.

Formato:

```text
slug<TAB>path<TAB>type<TAB>host<TAB>port<TAB>docroot<TAB>index
```

Recencia de uso:

```text
~/.config/gamb-php/projects-meta.tsv
```

Esse arquivo auxiliar guarda a ordem recente usada pelo hub visual.

## Descoberta

`gamb-php-discover` procura marcadores de Laravel, WordPress e PHP em raizes locais conhecidas. O modo `--register` grava somente o catalogo do usuario em `~/.config/gamb-php`; os projetos permanecem intocados.

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

## Hub local

O router externo agora reserva a rota:

```text
/__gamb_php__/hub
```

Essa rota entrega:

- dashboard com projetos recentes;
- lista lateral com overflow dos demais;
- acoes rapidas com comandos por shell para projeto e banco local;
- area de retorno para acoes executadas localmente.

## Integracao MySQL/MariaDB (MV2)

O modulo de banco e carregado pelo `gamb-php-serve` e atua antes do PHP quando o projeto e WordPress ou Laravel com banco local.

O objetivo e reaproveitar binarios locais de MySQL/MariaDB, detectando perfis por configuracoes como `my.ini` e mantendo o estado do modulo em:

```text
~/.local/state/gamb-php/db
```

Regras da MV2:

- inicia o servidor MySQL/MariaDB diretamente, sem abrir Laragon, WAMP ou outro painel;
- bloqueia o PHP se o banco local exigido nao for encontrado ou nao puder iniciar;
- preserva projetos configurados com banco remoto, sem iniciar um banco local;
- prioriza um perfil padrao, mas aceita `mysql`, `mariadb` ou `--profile`;
- nao derruba um banco externo que nao tenha sido iniciado pelo proprio modulo.

## Auto-start

O instalador adiciona um hook no `~/.bashrc` que chama `gamb-php-auto` no prompt. Quando a pasta atual coincide com um projeto registrado e o servidor não está rodando, ele prepara o banco local exigido e sobe silenciosamente.
