# Exemplos

## Primeiro uso

```bash
cd /d/ProjetosGit/meu-projeto
gamb-php-serve
```

Depois disso, o terminal passa a mostrar algo como:

```text
Projeto: http://localhost:8000
Painel:  http://localhost:8000/__gamb_php__/hub
```

## Uso com porta customizada

```bash
gamb-php-serve --port 8080
```

## Uso em foreground

```bash
gamb-php-serve --foreground
```

## Verificação

```bash
gamb-php-check
```

## Abrindo o painel diretamente

```text
http://localhost:PORTA/__gamb_php__/hub
```

## Status

```bash
gamb-php-status
gamb-php-status --all
```

## Parada

```bash
gamb-php-stop
gamb-php-stop --all
```

## Remoção

```bash
gamb-php-remove
gamb-php-remove --with-logs
```
