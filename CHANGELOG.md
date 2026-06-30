# Changelog

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
