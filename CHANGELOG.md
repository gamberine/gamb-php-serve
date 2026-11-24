# Changelog

## 0.6.0

- Adiciona descoberta e registro de projetos locais em Laragon, WAMP, XAMPP e pastas configuradas.
- Adiciona dashboard de comandos para VS Code e contrato local de integracao com Antigravity.
- Remove a dependencia de fonte externa do hub e prepara Inter como recurso local.
- Adiciona carrossel navegavel para projetos recentes e acao de descoberta pelo hub.

## 0.5.0

- Integra o ciclo de inicializacao do MySQL/MariaDB ao `gamb-php-serve` para WordPress e Laravel com banco local.
- Inicia os binarios diretamente, sem exigir Laragon, WAMP ou outro painel aberto em paralelo.
- Mantem bancos remotos intocados e bloqueia o PHP quando o banco local obrigatorio nao esta disponivel.
- Adiciona `GAMB_PHP_DB_AUTO_START=0` para desativar o comportamento automatico.

## 0.4.1

- Adiciona `gamb-php-serve --stop` como atalho para parar o projeto registrado na pasta atual.
- Mantem `gamb-php-stop` como comando dedicado e preserva `gamb-php-stop --all` para parada global.
- Ignora artefatos locais do kit de agentes sem incorporá-los ao repositorio do produto.

## 0.4.0

- Adiciona a MV2 com modulo opcional de banco para detectar, iniciar, verificar e parar MySQL/MariaDB local.
- Mantem o fluxo atual do `gamb-php-serve` sem auto-start ou acoplamento obrigatorio com banco.
- Expande o hub local com acoes rapidas para o modulo de banco.
- Atualiza instalador, desinstalador e documentacao para a nova camada opcional.

## 0.3.0

- Adiciona hub visual em `localhost` com projetos recentes, lista lateral rolavel e acoes rapidas.
- Publica uma landing GitHub Pages baseada no mesmo design do painel local.
- Inclui ilustração central compartilhada entre o painel e a landing.
- Adiciona workflow Pages em `.github/workflows/pages.yml`.
- Passa a registrar recencia de uso em `projects-meta.tsv` para ordenar o catalogo visual.

## 0.2.0

- Abre a URL no navegador padrao ao executar `gamb-php-serve` manualmente.
- Adiciona live reload automatico para paginas servidas pelo router temporario, sem alterar o projeto.
- Corrige caminhos do router temporario para `php.exe` do Windows usando formato compativel com o runtime.
- Passa a respeitar prefixos como `/admin` e `/extranet` definidos no `config/local.php`.
- Passa a exibir `localhost` nas URLs abertas e listadas, mantendo o bind interno em `127.0.0.1`.
- Permite subir uma nova instância manual do mesmo projeto com outra `--port`, sem conflitar com a já em execução.

## 0.1.0

- Criação inicial da ferramenta `gamb-php-serve`.
- Suporte a `serve`, `auto`, `status`, `stop`, `list`, `remove` e `check`.
- Instalador e desinstalador globais para Git Bash no Windows.
