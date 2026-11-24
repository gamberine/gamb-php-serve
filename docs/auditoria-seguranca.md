# Auditoria de seguranca e dependencias

## Controles aplicados

- O endpoint de acoes do hub aceita apenas requisicoes locais.
- Caminhos recebidos pelo hub sao limitados, escapados para Bash e usados apenas em comandos conhecidos.
- A extensao VS Code rejeita quebras de linha, encadeamento, substituicao de shell e comandos fora da allowlist.
- `gamb-php-wp-install` e `gamb-php-wp-move` recusam destinos nao vazios e destinos dentro da origem.
- `gamb-php-wp-move` funciona em simulacao por padrao.
- O shell de banco usa senha interativa, sem senha na linha de comando.
- Senhas nao aparecem no relatorio do WordPress nem no output dos comandos.
- A descoberta ignora `wp-admin`, `wp-content` e `wp-includes` como falsos projetos.
- A fonte Inter e local; o hub nao depende de Google Fonts.

## Dependencias reais

- PHP CLI e PHP runtime para servir o projeto.
- Git Bash para os comandos portaveis no Windows.
- MySQL ou MariaDB instalado quando o projeto exigir banco local.
- Cliente `mysql`, `mariadb`, `mysqldump` ou `mariadb-dump` para shell e exportacao.
- API do VS Code somente quando a extensao estiver instalada.
- `curl` ou `wget` apenas como fallback do instalador quando ele for executado fora de um checkout local.

Nao existem dependencias npm de runtime, pacote de UI, Google Fonts ou HeidiSQL obrigatorio.

## Riscos residuais

- `wp-config.php` precisa conter credenciais para o WordPress funcionar. O arquivo deve permanecer fora de repositorios publicos.
- `--include-db` exporta dados para `database.sql`; o operador deve proteger e remover esse arquivo depois do transporte.
- O hub pode consultar o portfolio remoto opcional. Se a rede falhar, o fallback local permanece; o funcionamento do servidor nao depende desse feed.
- O servidor PHP embutido e apropriado para desenvolvimento local, nao para exposicao publica.
- A movimentacao para hospedagem ainda exige revisao de URLs, permissao, importacao e credenciais do destino. Nenhum upload remoto e feito automaticamente.

## Integracao futura

O resultado de `gamb-php-wp-move --execute` e uma pasta WordPress completa, opcionalmente com `database.sql`. Esse formato e compatível com uma etapa posterior do `gamb-duplica-wp`, mas a integracao executavel nao foi ativada porque o repositorio e as credenciais de destino nao estao presentes neste checkout.
