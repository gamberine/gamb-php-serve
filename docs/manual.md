# Manual do produto

## 1. O que e

O `gamb-php-serve` e uma camada local de operacao para projetos PHP. Ele nao substitui o codigo do projeto, nao instala um painel web e nao precisa manter Laragon, WAMP ou XAMPP aberto. O servidor PHP e o banco local sao controlados pelos binarios que ja existem no computador.

O fluxo principal e:

1. Descobrir ou registrar o projeto.
2. Verificar PHP e banco.
3. Iniciar pelo `gamb-php-serve`.
4. Trabalhar pelo hub local.
5. Parar com `gamb-php-serve --stop` quando terminar.

## 2. Instalacao

No Git Bash:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/gamberine/gamb-php-serve/main/install.sh)"
source ~/.bashrc
gamb-php-check
gamb-php-db-check
```

Requisitos locais:

- Git Bash.
- PHP CLI ou PHP portatil.
- MySQL ou MariaDB quando o projeto usar banco local.
- VS Code opcional para o dashboard lateral.

## 3. Primeiro projeto

```bash
cd /d/ProjetosWeb/meu-projeto
gamb-php-serve
```

O painel sera aberto em uma URL dinamica semelhante a:

```text
http://localhost:8000/__gamb_php__/hub
```

A porta, o caminho base e a URL real sao definidos pelo registro local. O projeto nao recebe arquivos de configuracao do Gamb.

## 4. Descoberta local

```bash
gamb-php-discover
gamb-php-discover --root /d/ProjetosWeb --register
```

O comando reconhece WordPress, Laravel, PHP com `public/` e PHP simples. A descoberta somente registra o catalogo. Ela nao edita os projetos.

## 5. Banco sem painel paralelo

```bash
gamb-php-db-check
gamb-php-db-start mysql
gamb-php-db-status
gamb-php-db-shell --database minha_base
```

Quando um WordPress ou Laravel local exige MySQL/MariaDB, o `gamb-php-serve` identifica o perfil e pode iniciar o processo diretamente. Se o banco ja estiver rodando por outro programa, ele e tratado como externo e nao e interrompido pelo modulo.

O `gamb-php-db-shell` usa o cliente instalado e pede a senha de forma interativa. Nao e necessario instalar HeidiSQL para o fluxo basico de consulta e manutencao.

## 6. WordPress local

Prepare uma copia local sem sobrescrever um destino existente:

```bash
gamb-php-wp-install \
  --source /d/ProjetosWeb/wordpress \
  --destination /d/ProjetosWeb/novo-site \
  --db-name novo_site
```

O comando copia os arquivos, gera salts e registra a nova raiz. A criacao ou importacao do banco e uma etapa separada para evitar acao destrutiva implicita.

Planeje uma movimentacao:

```bash
gamb-php-wp-move \
  --source /d/ProjetosWeb/wordpress \
  --destination /d/ProjetosWeb/novo-site
```

Execute somente depois da revisao:

```bash
gamb-php-wp-move \
  --source /d/ProjetosWeb/wordpress \
  --destination /d/ProjetosWeb/novo-site \
  --execute --include-db
```

O resultado pode conter `database.sql`, mas o envio ao servidor, a troca de URLs, as permissoes e as credenciais continuam sendo revisados pelo operador. Esse limite prepara uma integracao futura com `gamb-duplica-wp` sem acoplar segredos.

## 7. VS Code

O repositorio fornece uma extensao sem dependencias npm de runtime. Para gerar e instalar o pacote:

```powershell
./extension/package-vsix.ps1
code --install-extension ./dist/gamb-php-serve-vscode-0.7.2.vsix
```

O painel lateral oferece inicio, parada, descoberta, status do banco, preparacao WordPress e plano de movimentacao.

## 8. Modelo de seguranca

- Bind local em `127.0.0.1`.
- Endpoint de acoes restrito a requisicoes locais.
- Comandos do dashboard e da extensao submetidos a allowlist.
- Nenhuma senha exibida em relatorios ou argumentos do shell de banco.
- Destinos WordPress nao vazios sao recusados.
- Movimentacao inicia em modo simulacao.
- Banco remoto nao dispara inicializacao local.
- Servidor PHP embutido destinado a desenvolvimento, nunca a producao.

Consulte a [auditoria de seguranca](auditoria-seguranca.md) para os riscos residuais e dependencias reais.

## 9. Operacao diaria

```bash
gamb-php-status
gamb-php-list
gamb-php-serve --stop
gamb-php-stop --all
```

Os logs e estados ficam em `~/.local/state/gamb-php`. O catalogo e mantido em `~/.config/gamb-php`.

## 10. O que nao e automatico

O produto nao publica em hospedagem, nao cria banco remoto, nao altera URLs de producao e nao sobrescreve um destino sem uma acao explicita. Essa separacao e parte do produto: praticidade no ambiente local sem transformar uma rotina de desenvolvimento em uma operacao irreversivel.
