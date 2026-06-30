<?php
declare(strict_types=1);

$ctx = $GLOBALS["gambPhpDashboardContext"] ?? [];
if (!is_array($ctx) || empty($ctx["dashboardBasePath"])) {
    http_response_code(500);
    echo "Dashboard unavailable.";
    return;
}

function gambHubEscape(string $value): string
{
    return htmlspecialchars($value, ENT_QUOTES, "UTF-8");
}

function gambHubRequestPath(): string
{
    return rawurldecode(parse_url($_SERVER["REQUEST_URI"] ?? "/", PHP_URL_PATH) ?? "/");
}

function gambHubContentType(string $file): string
{
    $extension = strtolower(pathinfo($file, PATHINFO_EXTENSION));
    return match ($extension) {
        "css" => "text/css; charset=UTF-8",
        "js" => "application/javascript; charset=UTF-8",
        "json" => "application/json; charset=UTF-8",
        "svg" => "image/svg+xml",
        "png" => "image/png",
        "jpg", "jpeg" => "image/jpeg",
        "webp" => "image/webp",
        "ico" => "image/x-icon",
        default => "application/octet-stream",
    };
}

function gambHubServeFile(string $file): void
{
    if (!is_file($file)) {
        http_response_code(404);
        echo "Not Found";
        return;
    }

    header("Content-Type: " . gambHubContentType($file));
    header("Content-Length: " . (string) filesize($file));
    header("Cache-Control: no-store");
    readfile($file);
}

function gambHubJson(array $payload, int $statusCode = 200): void
{
    http_response_code($statusCode);
    header("Content-Type: application/json; charset=UTF-8");
    header("Cache-Control: no-store, no-cache, must-revalidate");
    echo json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
}

function gambHubIsLocalRequest(): bool
{
    $remote = $_SERVER["REMOTE_ADDR"] ?? "";
    return in_array($remote, ["127.0.0.1", "::1", "::ffff:127.0.0.1"], true);
}

function gambHubNormalizeBasePath(string $value): string
{
    if ($value === "") {
        return "";
    }

    if (preg_match("#^[A-Za-z]+://[^/]+(.*)$#", $value, $matches)) {
        $value = $matches[1] ?? "";
    }

    $value = preg_replace("/[?#].*$/", "", $value) ?? "";
    if ($value === "" || $value === "/") {
        return "";
    }

    if ($value[0] !== "/") {
        $value = "/" . $value;
    }

    return rtrim($value, "/");
}

function gambHubExtractDefineValue(string $filePath, string $defineName): string
{
    if (!is_file($filePath)) {
        return "";
    }

    $pattern = "/^[\\s]*define\\([\\s]*['\\\"]" . preg_quote($defineName, "/") . "['\\\"][\\s]*,[\\s]*['\\\"]([^'\\\"]*)['\\\"].*$/m";
    $content = (string) file_get_contents($filePath);
    if (preg_match($pattern, $content, $matches)) {
        return trim($matches[1]);
    }

    return "";
}

function gambHubDetectBasePath(string $root): string
{
    $configFile = rtrim($root, "/\\") . DIRECTORY_SEPARATOR . "config" . DIRECTORY_SEPARATOR . "local.php";
    foreach (["SITE_URL", "ADMIN_URL", "PORTAL_URL", "INTRANET_URL"] as $key) {
        $value = gambHubExtractDefineValue($configFile, $key);
        if ($value !== "") {
            return gambHubNormalizeBasePath($value);
        }
    }

    return "";
}

function gambHubDisplayHost(string $host): string
{
    if ($host === "127.0.0.1" || $host === "::1" || $host === "localhost") {
        return "localhost";
    }

    return $host;
}

function gambHubRuntimePath(string $path): string
{
    static $cache = [];

    if ($path === "" || PHP_OS_FAMILY !== "Windows") {
        return $path;
    }

    if (isset($cache[$path])) {
        return $cache[$path];
    }

    $normalized = str_replace("\\", "/", $path);
    if (preg_match("/^[A-Za-z]:\\//", $normalized)) {
        $cache[$path] = str_replace("/", DIRECTORY_SEPARATOR, $normalized);
        return $cache[$path];
    }

    if (preg_match("#^/([A-Za-z])/(.+)$#", $normalized, $matches)) {
        $cache[$path] = str_replace("/", DIRECTORY_SEPARATOR, strtoupper($matches[1]) . ":/" . $matches[2]);
        return $cache[$path];
    }

    if (strpos($normalized, "/tmp/") === 0) {
        $baseTmp = str_replace("\\", "/", getenv("TEMP") ?: sys_get_temp_dir());
        $cache[$path] = str_replace("/", DIRECTORY_SEPARATOR, rtrim($baseTmp, "/") . substr($normalized, 4));
        return $cache[$path];
    }

    return $path;
}

function gambHubProjectUrl(string $host, string $port, string $basePath): string
{
    return "http://" . gambHubDisplayHost($host) . ":" . $port . gambHubNormalizeBasePath($basePath);
}

function gambHubDashboardUrl(string $host, string $port, string $basePath): string
{
    return gambHubProjectUrl($host, $port, $basePath) . "/__gamb_php__/hub";
}

function gambHubReadTsv(string $filePath, int $expectedColumns): array
{
    if (!is_file($filePath)) {
        return [];
    }

    $rows = [];
    $handle = fopen($filePath, "rb");
    if (!$handle) {
        return [];
    }

    while (($line = fgets($handle)) !== false) {
        $line = trim($line);
        if ($line === "") {
            continue;
        }
        $parts = explode("\t", $line);
        if (count($parts) < $expectedColumns) {
            continue;
        }
        $rows[] = $parts;
    }
    fclose($handle);

    return $rows;
}

function gambHubReadRegistry(array $ctx): array
{
    $rows = gambHubReadTsv(rtrim((string) $ctx["configDir"], "/\\") . DIRECTORY_SEPARATOR . "projects.tsv", 7);
    return array_map(static function (array $parts): array {
        return [
            "slug" => $parts[0],
            "path" => $parts[1],
            "type" => $parts[2],
            "host" => $parts[3],
            "port" => $parts[4],
            "docroot" => $parts[5],
            "index" => $parts[6],
        ];
    }, $rows);
}

function gambHubReadMeta(array $ctx): array
{
    $rows = gambHubReadTsv(rtrim((string) $ctx["configDir"], "/\\") . DIRECTORY_SEPARATOR . "projects-meta.tsv", 2);
    $meta = [];
    foreach ($rows as $parts) {
        $meta[$parts[0]] = (int) $parts[1];
    }

    return $meta;
}

function gambHubPidFile(array $ctx, string $slug): string
{
    return rtrim((string) $ctx["stateDir"], "/\\") . DIRECTORY_SEPARATOR . "pids" . DIRECTORY_SEPARATOR . $slug . ".pid";
}

function gambHubProjectRunning(array $ctx, string $slug): bool
{
    $pidFile = gambHubPidFile($ctx, $slug);
    if (!is_file($pidFile)) {
        return false;
    }

    $pid = trim((string) file_get_contents($pidFile));
    if ($pid === "") {
        return false;
    }

    if (stripos(PHP_OS_FAMILY, "Windows") === 0) {
        $safePid = preg_replace("/[^0-9]/", "", $pid) ?? "";
        $output = shell_exec("tasklist /FI \"PID eq {$safePid}\" 2>NUL");
        return is_string($output) && strpos($output, $pid) !== false;
    }

    return function_exists("posix_kill") ? @posix_kill((int) $pid, 0) : is_file("/proc/" . $pid);
}

function gambHubProjectName(string $path): string
{
    $name = basename(str_replace("\\", "/", $path));
    $name = preg_replace("/[-_]+/", " ", $name) ?? $name;
    $name = preg_replace("/\\s+/", " ", $name) ?? $name;
    $name = trim($name);
    if ($name === "") {
        return "Projeto local";
    }

    $name = ucwords(strtolower($name));
    $replacements = [
        "Php" => "PHP",
        "Api" => "API",
        "Wp" => "WP",
        "Rh" => "RH",
        "Crm" => "CRM",
    ];

    return strtr($name, $replacements);
}

function gambHubProjectMonogram(string $name): string
{
    $parts = preg_split("/\\s+/", trim($name)) ?: [];
    $letters = "";
    foreach ($parts as $part) {
        if ($part === "") {
            continue;
        }
        $letters .= strtoupper(substr($part, 0, 1));
        if (strlen($letters) >= 2) {
            break;
        }
    }

    return $letters !== "" ? $letters : "P";
}

function gambHubProjectIconFile(string $runtimePath, string $runtimeDocroot): string
{
    $candidates = [
        $runtimeDocroot . "/favicon.ico",
        $runtimeDocroot . "/favicon.png",
        $runtimeDocroot . "/favicon.svg",
        $runtimePath . "/favicon.ico",
        $runtimePath . "/favicon.png",
        $runtimePath . "/favicon.svg",
        $runtimePath . "/public/favicon.ico",
        $runtimePath . "/public/favicon.png",
        $runtimePath . "/public/favicon.svg",
        $runtimePath . "/apple-touch-icon.png",
    ];

    foreach ($candidates as $candidate) {
        if (is_file($candidate)) {
            return $candidate;
        }
    }

    return "";
}

function gambHubRecentLabel(?int $timestamp, int $fallbackOrder): string
{
    if ($timestamp && $timestamp > 0) {
        $today = date("Y-m-d");
        $valueDay = date("Y-m-d", $timestamp);
        if ($valueDay === $today) {
            return "Hoje, " . date("H:i", $timestamp);
        }

        return date("d/m/Y, H:i", $timestamp);
    }

    return $fallbackOrder === 0 ? "Mais recente" : "Recente #" . ($fallbackOrder + 1);
}

function gambHubCurrentProjectPath(array $projects): string
{
    foreach ($projects as $project) {
        if (!empty($project["isCurrent"])) {
            return (string) ($project["path"] ?? "");
        }
    }

    return isset($projects[0]["path"]) ? (string) $projects[0]["path"] : "";
}

function gambHubCollectProjects(array $ctx): array
{
    $rows = gambHubReadRegistry($ctx);
    $meta = gambHubReadMeta($ctx);
    $projects = [];
    $rank = 0;

    for ($i = count($rows) - 1; $i >= 0; $i--) {
        $row = $rows[$i];
        $path = $row["path"];
        if ($path === "") {
          continue;
        }

        $runtimePath = gambHubRuntimePath($path);
        $runtimeDocroot = gambHubRuntimePath((string) ($row["docroot"] ?? ""));
        $currentInstance = ($row["slug"] ?? "") === (string) ($ctx["projectSlug"] ?? "");

        $id = sha1($path);
        $basePath = gambHubDetectBasePath($runtimePath);
        $instance = [
            "slug" => $row["slug"],
            "port" => $row["port"],
            "running" => $currentInstance || gambHubProjectRunning($ctx, $row["slug"]),
            "url" => gambHubProjectUrl($row["host"], $row["port"], $basePath),
        ];

        if (!isset($projects[$path])) {
            $iconFile = gambHubProjectIconFile($runtimePath, $runtimeDocroot);
            $name = gambHubProjectName($path);
            $projects[$path] = [
                "id" => $id,
                "name" => $name,
                "slug" => $row["slug"],
                "path" => $path,
                "type" => $row["type"],
                "host" => $row["host"],
                "port" => $row["port"],
                "basePath" => $basePath,
                "url" => $instance["url"],
                "panelUrl" => gambHubDashboardUrl($row["host"], $row["port"], $basePath),
                "running" => $instance["running"],
                "lastUsed" => (int) ($meta[$path] ?? 0),
                "recentRank" => $rank,
                "recentLabel" => gambHubRecentLabel($meta[$path] ?? null, $rank),
                "iconFile" => $iconFile,
                "iconUrl" => $iconFile !== "" ? ($ctx["dashboardBasePath"] . "/project-icon?id=" . rawurlencode($id)) : "",
                "monogram" => gambHubProjectMonogram($name),
                "instancesCount" => 0,
                "instances" => [],
                "isCurrent" => $runtimePath !== "" && realpath($runtimePath) === realpath((string) $ctx["projectRoot"]),
            ];
            $rank++;
        }

        $projects[$path]["instances"][] = $instance;
        $projects[$path]["instancesCount"]++;
        if ($instance["running"]) {
            $projects[$path]["running"] = true;
            $projects[$path]["port"] = $row["port"];
            $projects[$path]["url"] = $instance["url"];
            $projects[$path]["panelUrl"] = gambHubDashboardUrl($row["host"], $row["port"], $basePath);
            $projects[$path]["slug"] = $row["slug"];
        }
    }

    $list = array_values($projects);
    usort($list, static function (array $left, array $right): int {
        $timeCompare = ($right["lastUsed"] ?? 0) <=> ($left["lastUsed"] ?? 0);
        if ($timeCompare !== 0) {
            return $timeCompare;
        }

        return $left["recentRank"] <=> $right["recentRank"];
    });

    return $list;
}

function gambHubProjectMapById(array $projects): array
{
    $map = [];
    foreach ($projects as $project) {
        $map[$project["id"]] = $project;
    }

    return $map;
}

function gambHubProjectMapByPath(array $projects): array
{
    $map = [];
    foreach ($projects as $project) {
        $map[$project["path"]] = $project;
    }

    return $map;
}

function gambHubLocateGitBash(): ?string
{
    $candidates = [
        "C:\\Program Files\\Git\\bin\\bash.exe",
        "C:\\Program Files\\Git\\usr\\bin\\bash.exe",
    ];

    foreach ($candidates as $candidate) {
        if (is_file($candidate)) {
            return $candidate;
        }
    }

    return "bash";
}

function gambHubBashQuote(string $value): string
{
    return "'" . str_replace("'", "'\\''", $value) . "'";
}

function gambHubRunBash(string $cwd, string $command): array
{
    $bashBinary = gambHubLocateGitBash();
    if ($bashBinary === null) {
        return ["exitCode" => 127, "stdout" => "", "stderr" => "Git Bash nao encontrado."];
    }

    $script = ($cwd !== "" ? "cd " . gambHubBashQuote($cwd) . " && " : "") . $command;
    $descriptorSpec = [
        1 => ["pipe", "w"],
        2 => ["pipe", "w"],
    ];
    $pipes = [];
    $options = PHP_OS_FAMILY === "Windows" ? ["bypass_shell" => true] : [];
    $process = proc_open([$bashBinary, "-lc", $script], $descriptorSpec, $pipes, null, null, $options);

    if (!is_resource($process)) {
        return ["exitCode" => 1, "stdout" => "", "stderr" => "Nao foi possivel iniciar o processo Bash."];
    }

    $stdout = stream_get_contents($pipes[1]);
    fclose($pipes[1]);
    $stderr = stream_get_contents($pipes[2]);
    fclose($pipes[2]);
    $exitCode = proc_close($process);

    return [
        "exitCode" => is_int($exitCode) ? $exitCode : 1,
        "stdout" => trim((string) $stdout),
        "stderr" => trim((string) $stderr),
    ];
}

function gambHubParseUrl(string $output, string $label): string
{
    if (preg_match("/^" . preg_quote($label, "/") . ":[\\s]*(\\S+)/mi", $output, $matches)) {
        return trim($matches[1]);
    }

    return "";
}

function gambHubHandleAction(array $ctx): void
{
    if (!gambHubIsLocalRequest()) {
        gambHubJson(["error" => "Local access only."], 403);
        return;
    }

    $payload = json_decode((string) file_get_contents("php://input"), true);
    $action = is_array($payload) ? (string) ($payload["action"] ?? "") : "";
    $path = is_array($payload) ? (string) ($payload["path"] ?? "") : "";
    $projects = gambHubCollectProjects($ctx);
    $byPath = gambHubProjectMapByPath($projects);
    $project = $byPath[$path] ?? ($projects[0] ?? null);
    $cwd = $project["path"] ?? (string) $ctx["projectRoot"];
    $command = "";
    $meta = "Acao local";

    switch ($action) {
        case "open_project":
            if (!is_array($project)) {
                gambHubJson(["error" => "Projeto nao encontrado."], 404);
                return;
            }
            if ($project["running"] && $project["url"] !== "") {
                gambHubJson([
                    "ok" => true,
                    "meta" => "Projeto em execucao",
                    "stdout" => "Projeto ja estava rodando em " . $project["url"],
                    "stderr" => "",
                    "url" => $project["url"],
                    "projects" => $projects,
                    "currentProjectPath" => $project["path"],
                ]);
                return;
            }
            $command = "gamb-php-serve --port " . escapeshellarg((string) $project["port"]);
            $meta = "Inicializacao do projeto";
            break;

        case "check":
            $command = "gamb-php-check";
            $meta = "Verificacao do projeto";
            break;

        case "serve":
            $command = "gamb-php-serve";
            $meta = "Inicializacao manual";
            break;

        case "stop":
            $command = "gamb-php-stop";
            $meta = "Parada do projeto";
            break;

        case "list":
            $command = "gamb-php-list";
            $meta = "Catalogo de projetos";
            break;

        case "status_all":
            $command = "gamb-php-status --all";
            $meta = "Status geral";
            break;

        case "db_check":
            $command = "gamb-php-db-check";
            $meta = "Descoberta de bancos";
            break;

        case "db_start":
            $command = "gamb-php-db-start";
            $meta = "Inicializacao do banco local";
            break;

        case "db_status":
            $command = "gamb-php-db-status";
            $meta = "Status do banco local";
            break;

        case "db_stop":
            $command = "gamb-php-db-stop";
            $meta = "Parada do banco local";
            break;

        case "remove":
            $command = "gamb-php-remove";
            $meta = "Remocao do projeto";
            break;

        default:
            gambHubJson(["error" => "Acao invalida."], 400);
            return;
    }

    $result = gambHubRunBash($cwd, $command);
    $projects = gambHubCollectProjects($ctx);
    $currentProjectPath = is_array($project) ? $project["path"] : gambHubCurrentProjectPath($projects);
    $url = gambHubParseUrl($result["stdout"], "URL");
    $notice = $result["exitCode"] === 0 ? "Acao concluida." : "A acao retornou codigo " . $result["exitCode"] . ".";

    gambHubJson([
        "ok" => $result["exitCode"] === 0,
        "meta" => $meta,
        "stdout" => $result["stdout"],
        "stderr" => $result["stderr"],
        "url" => $url,
        "notice" => $notice,
        "projects" => $projects,
        "currentProjectPath" => $currentProjectPath,
    ]);
}

$requestPath = gambHubRequestPath();
$dashboardBasePath = (string) $ctx["dashboardBasePath"];
$relativePath = $requestPath === $dashboardBasePath ? "/" : substr($requestPath, strlen($dashboardBasePath));
$relativePath = $relativePath === false || $relativePath === "" ? "/" : $relativePath;

if ($relativePath === "/assets/dashboard.css") {
    gambHubServeFile(rtrim((string) $ctx["assetsDir"], "/\\") . DIRECTORY_SEPARATOR . "dashboard.css");
    return;
}

if ($relativePath === "/assets/dashboard.js") {
    gambHubServeFile(rtrim((string) $ctx["assetsDir"], "/\\") . DIRECTORY_SEPARATOR . "dashboard.js");
    return;
}

if ($relativePath === "/assets/hero-illustration.png") {
    gambHubServeFile(rtrim((string) $ctx["assetsDir"], "/\\") . DIRECTORY_SEPARATOR . "hero-illustration.png");
    return;
}

if ($relativePath === "/project-icon") {
    $projects = gambHubCollectProjects($ctx);
    $byId = gambHubProjectMapById($projects);
    $id = (string) ($_GET["id"] ?? "");
    $project = $byId[$id] ?? null;
    if (!is_array($project) || ($project["iconFile"] ?? "") === "") {
        http_response_code(404);
        echo "Not Found";
        return;
    }
    gambHubServeFile((string) $project["iconFile"]);
    return;
}

if ($relativePath === "/api/projects") {
    $projects = gambHubCollectProjects($ctx);
    gambHubJson([
        "projects" => $projects,
        "currentProjectPath" => gambHubCurrentProjectPath($projects),
    ]);
    return;
}

if ($relativePath === "/api/action") {
    gambHubHandleAction($ctx);
    return;
}

$repoUrl = "https://github.com/gamberine/gamb-php-serve";
$pageData = [
    "mode" => "local",
    "repoUrl" => $repoUrl,
    "pagesUrl" => "https://gamberine.github.io/gamb-php-serve/",
    "dashboardUrl" => (string) $ctx["dashboardUrl"],
    "projectUrl" => (string) $ctx["projectUrl"],
    "heroIllustration" => $dashboardBasePath . "/assets/hero-illustration.png",
    "api" => [
        "projects" => $dashboardBasePath . "/api/projects",
        "action" => $dashboardBasePath . "/api/action",
    ],
    "sampleProjects" => gambHubCollectProjects($ctx),
    "docsLinks" => [
        "install" => $repoUrl . "/blob/main/docs/instalacao.md",
        "commands" => $repoUrl . "/blob/main/docs/comandos.md",
        "funcionamento" => $repoUrl . "/blob/main/docs/funcionamento.md",
        "exemplos" => $repoUrl . "/blob/main/docs/exemplos.md",
    ],
    "portfolioSources" => [
        "https://gamberine.github.io/gamb-portfolio-solucoes/portfolio.json",
        "https://raw.githubusercontent.com/gamberine/gamb-portfolio-solucoes/main/portfolio.json",
        "https://raw.githubusercontent.com/gamberine/gamb-portfolio-solucoes/main/data/portfolio.json",
    ],
    "portfolioFallback" => [
        [
            "name" => "gamb-php-serve",
            "description" => "Repositorio principal com dashboard local, comandos globais e instalacao em uma linha.",
            "url" => $repoUrl,
            "tags" => ["bash", "php", "cli"],
            "stars" => 0,
            "downloads" => 0,
        ],
        [
            "name" => "Starter Pack",
            "description" => "Espaco reservado para packs e downloads do ecossistema de solucoes em evolucao.",
            "url" => $repoUrl . "/tree/main/docs",
            "tags" => ["templates", "workflow"],
            "stars" => 0,
            "downloads" => 0,
        ],
        [
            "name" => "Documentacao",
            "description" => "Comandos, exemplos e funcionamento tecnico ligados a esta entrega.",
            "url" => $repoUrl . "/blob/main/docs/comandos.md",
            "tags" => ["docs"],
            "stars" => 0,
            "downloads" => 0,
        ],
    ],
];
$pageData["currentProjectPath"] = gambHubCurrentProjectPath($pageData["sampleProjects"]);
?>
<!doctype html>
<html lang="pt-BR">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>gamb-php-serve hub</title>
    <meta
      name="description"
      content="Painel visual do gamb-php-serve para listar projetos locais, abrir URLs e acionar comandos utilitarios de PHP e MySQL/MariaDB local."
    >
    <link rel="stylesheet" href="<?= gambHubEscape($dashboardBasePath . "/assets/dashboard.css") ?>">
  </head>
  <body>
    <script>
      window.gambPhpPageData = <?= json_encode($pageData, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) ?>;
    </script>

    <div class="page-shell">
      <main class="page-wrap">
        <section class="dashboard-surface" id="dashboard-preview">
          <div class="brand-row">
            <div class="brand">
              <div class="brand-mark" aria-hidden="true">
                <svg viewBox="0 0 24 24">
                  <path fill="currentColor" d="M4 5.5A1.5 1.5 0 0 1 5.5 4h13A1.5 1.5 0 0 1 20 5.5v13a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 4 18.5Zm3.36 7.85a1 1 0 0 1 0-1.41l2.79-2.79a1 1 0 1 1 1.41 1.41L9.47 12l2.09 2.09a1 1 0 1 1-1.41 1.41Zm9.92 1.15a1 1 0 1 1 0 2h-4.1a1 1 0 0 1 0-2Z"/>
                </svg>
              </div>
              <div class="brand-copy">
                <h1>gamb-php-serve</h1>
                <p>Hub local para projetos PHP com gestao visual, URLs prontas e modulo opcional de MySQL/MariaDB.</p>
              </div>
            </div>

            <div class="status-cluster">
              <div class="status-badge">
                <div class="status-dot">localhost rodando</div>
                <p class="stat-note">Servidor ativo em <?= gambHubEscape((string) $ctx["projectUrl"]) ?></p>
              </div>
              <div class="icon-pill-group" aria-hidden="true">
                <a class="icon-pill js-current-project-link" href="<?= gambHubEscape((string) $ctx["projectUrl"]) ?>" title="Abrir projeto atual">↗</a>
                <a class="icon-pill js-dashboard-link" href="<?= gambHubEscape((string) $ctx["dashboardUrl"]) ?>" title="Abrir painel">⌘</a>
              </div>
            </div>
          </div>

          <div class="project-layout section-gap">
            <section class="project-main">
              <div class="section-head">
                <div>
                  <h2>Projetos recentes</h2>
                  <p>Os quatro mais recentes aparecem primeiro. Os demais seguem em uma lista vertical rolavel no bloco lateral.</p>
                </div>
              </div>
              <div class="project-grid js-project-grid"></div>
            </section>

            <aside class="project-sidebar">
              <div class="sidebar-panel">
                <div>
                  <h3>Outros projetos</h3>
                  <p class="ghost-note">Clique para selecionar o projeto e refletir isso nas acoes abaixo.</p>
                </div>
                <div class="ghost-note">Projeto ativo nas acoes: <strong class="js-selected-project-label">Carregando...</strong></div>
                <div class="sidebar-list js-project-list"></div>
                <a class="sidebar-footer-link" href="<?= gambHubEscape($repoUrl . "/blob/main/docs/comandos.md") ?>" target="_blank" rel="noreferrer">Ver a documentacao de comandos<span aria-hidden="true">→</span></a>
              </div>
            </aside>
          </div>

          <section class="action-zone">
              <div class="section-head">
                <div>
                  <h2>Acoes rapidas no terminal</h2>
                  <p>Os comandos ja saem prontos para CMD, PowerShell e Bash, cobrindo projeto e banco local. Quando a extensao complementar existir, a ponte do VS Code assume a injecao no terminal aberto.</p>
                </div>
              </div>
            <div class="action-grid js-action-grid"></div>
            <div class="terminal-panel js-terminal-panel">
              <div class="project-card-header">
                <h3>Retorno da ultima acao</h3>
                <small class="terminal-meta js-terminal-meta"></small>
              </div>
              <pre class="terminal-command terminal-output js-terminal-output"></pre>
            </div>
          </section>
        </section>

        <section class="marketing-surface">
          <div class="marketing-nav">
            <div class="brand">
              <div class="brand-mark" aria-hidden="true">
                <svg viewBox="0 0 24 24">
                  <path fill="currentColor" d="M4 5.5A1.5 1.5 0 0 1 5.5 4h13A1.5 1.5 0 0 1 20 5.5v13a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 4 18.5Zm3.36 7.85a1 1 0 0 1 0-1.41l2.79-2.79a1 1 0 1 1 1.41 1.41L9.47 12l2.09 2.09a1 1 0 1 1-1.41 1.41Zm9.92 1.15a1 1 0 1 1 0 2h-4.1a1 1 0 0 1 0-2Z"/>
                </svg>
              </div>
              <div><strong>gamb-php-serve</strong></div>
            </div>
            <nav class="marketing-links">
              <a href="#como-funciona">Como funciona</a>
              <a href="<?= gambHubEscape($repoUrl . "/blob/main/docs/comandos.md") ?>" target="_blank" rel="noreferrer">Comandos</a>
              <a href="#tecnologia">Tecnologia</a>
              <a href="#portfolio">Portfolio</a>
              <a href="#autoria">Autores</a>
            </nav>
            <a href="<?= gambHubEscape($repoUrl) ?>" target="_blank" rel="noreferrer">GitHub</a>
          </div>

          <div class="hero-grid">
            <div class="hero-copy">
              <span class="hero-kicker">Bash global tool</span>
              <h2>gamb-php-serve</h2>
              <p>
                Uma camada visual moderna sobre o motor Bash do serve. A proposta continua a mesma: nao tocar nos projetos,
                centralizar a configuracao no usuario e manter um fluxo rapido para iniciar, parar, listar e abrir
                ambientes locais sem ruido, agora com um modulo paralelo para MySQL/MariaDB quando fizer sentido.
              </p>
              <div class="hero-links">
                <a class="pill-link primary" href="<?= gambHubEscape($repoUrl) ?>" target="_blank" rel="noreferrer">Ver no GitHub</a>
                <a class="pill-link" href="<?= gambHubEscape($repoUrl . "/blob/main/docs/instalacao.md") ?>" target="_blank" rel="noreferrer">Instalacao rapida</a>
                <a class="pill-link" href="https://gamberine.github.io/gamb-php-serve/" target="_blank" rel="noreferrer">GitHub Pages</a>
              </div>
            </div>
            <div class="hero-visual">
              <img src="<?= gambHubEscape($dashboardBasePath . "/assets/hero-illustration.png") ?>" alt="Ilustracao do gamb-php-serve com terminal e servidores">
            </div>
          </div>

          <section class="feature-grid" id="como-funciona">
            <article class="feature-card">
              <div class="feature-head"><h3>Registrar</h3></div>
              <p>Registra o projeto localmente, organiza por recencia e mantem a camada visual fora do repositrio PHP.</p>
            </article>
            <article class="feature-card">
              <div class="feature-head"><h3>Gerenciar</h3></div>
              <p>Aciona projeto e banco local por browser, Bash e futuras pontes de editor sem alterar codigo versionado.</p>
            </article>
            <article class="feature-card">
              <div class="feature-head"><h3>Acessar</h3></div>
              <p>Abre URLs locais, preserva base path e mantem o bind em loopback com foco em praticidade.</p>
            </article>
          </section>

          <section class="section-cards" id="tecnologia">
            <article class="feature-card">
              <h3>Comandos principais</h3>
              <div class="mini-list">
                <code>gamb-php-serve</code>
                <code>gamb-php-stop</code>
                <code>gamb-php-list</code>
                <code>gamb-php-status --all</code>
                <code>gamb-php-db-start</code>
                <code>gamb-php-db-status</code>
                <code>gamb-php-remove</code>
              </div>
              <p class="support-line">A camada visual usa os mesmos comandos do motor principal. O painel so reduz atrito operacional.</p>
            </article>

            <article class="feature-card">
              <h3>Tecnologia leve</h3>
              <ul>
                <li>Bash puro para instalacao, descoberta de ambiente e orquestracao do ciclo local.</li>
                <li>PHP built-in server com router externo para nao criar arquivos nos projetos do usuario.</li>
                <li>Modulo opcional de MySQL/MariaDB reaproveitando instalacoes locais ja existentes.</li>
                <li>HTML, CSS e JavaScript sem build pesado para a camada visual e para a GitHub Pages.</li>
                <li>Camada opcional de IA no design e no polimento, sem acoplar dependencias ao uso final.</li>
              </ul>
            </article>

            <article class="feature-card" id="autoria">
              <h3>Autoria &amp; Craftsmanship</h3>
              <p>
                Trabalho autoral com apoio de IA para design, verificacao e refinamento. O objetivo e seguir buscando
                solucoes modernas que melhorem o dia a dia, entreguem praticidade real e deixem o fluxo local mais
                elegante e confiavel.
              </p>
              <ul class="authorship-list">
                <li>Merito em unir uso tecnico serio com experiencia visual clara.</li>
                <li>Implementacao preparada para crescer sem descaracterizar a leveza da ferramenta.</li>
                <li>Foco continuo em produtividade, pouca burocracia e documentacao objetiva.</li>
              </ul>
              <div class="signature-block">
                <div class="signature-name">Gamberine</div>
                <div class="signature-role">Solucoes proprias, arquitetura pragmatica e IA como parceira de qualidade.</div>
              </div>
            </article>
          </section>

          <section class="section-gap" id="portfolio">
            <div class="section-head">
              <div>
                <h2>Portfolio de solucoes</h2>
                <p>Bloco preparado para o componente dinamico do repositrio gamb-portfolio-solucoes com links e downloads.</p>
              </div>
              <div class="section-links">
                <a href="https://github.com/gamberine/gamb-portfolio-solucoes" target="_blank" rel="noreferrer">Repositorio alvo</a>
              </div>
            </div>
            <div class="portfolio-grid js-portfolio-grid">
              <div class="portfolio-empty">Carregando componente dinamico...</div>
            </div>
          </section>

          <div class="donation-line">
            Pix para melhorias: <a href="mailto:gamberine@gmail.com">gamberine@gmail.com</a>
          </div>
        </section>
      </main>
      <div class="hidden js-toast" aria-live="polite"></div>
    </div>

    <script src="<?= gambHubEscape($dashboardBasePath . "/assets/dashboard.js") ?>" defer></script>
  </body>
</html>
