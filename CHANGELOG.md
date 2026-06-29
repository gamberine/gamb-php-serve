# Changelog

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
