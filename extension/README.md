# Gamb PHP Serve para VS Code

Extensao sem dependencias npm de runtime. Ela apresenta o dashboard lateral e envia somente comandos allowlisted do `gamb-php-serve` para um terminal do VS Code.

## Requisito

Instale o projeto globalmente pelo `install.sh` antes de usar os botoes. A extensao nao instala PHP, Git Bash ou MySQL.

## Comandos

- `Gamb PHP Serve: Abrir dashboard`
- `Gamb PHP Serve: Iniciar projeto`
- `Gamb PHP Serve: Parar projeto`
- `Gamb PHP Serve: Descobrir projetos`
- `Gamb PHP Serve: Status do banco`
- `Gamb PHP Serve: Preparar WordPress`
- `Gamb PHP Serve: Planejar movimentacao WordPress`

A URI `vscode://gamberine.gamb-php-serve/terminal` aceita somente o payload de terminal gerado pelo dashboard local; a extensao nao executa comandos recebidos de rede.

Para gerar o pacote instalavel sem dependencias npm:

```powershell
./extension/package-vsix.ps1
code --install-extension ./dist/gamb-php-serve-vscode-0.7.2.vsix
```
