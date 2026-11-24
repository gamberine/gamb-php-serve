const vscode = require("vscode");

const ACTIONS = Object.freeze({
  start: "gamb-php-serve",
  stop: "gamb-php-serve --stop",
  discover: "gamb-php-discover --register",
  dbStatus: "gamb-php-db-status",
});

function shellQuote(value) {
  return "'" + String(value).replace(/'/g, "'\\''") + "'";
}

function workspacePath() {
  return vscode.workspace.workspaceFolders?.[0]?.uri.fsPath || undefined;
}

function runInTerminal(command, cwd = workspacePath()) {
  const terminal = vscode.window.createTerminal({ name: "Gamb PHP Serve", cwd });
  terminal.show(true);
  terminal.sendText(command, true);
  return terminal;
}

function isAllowedCommand(command) {
  if (typeof command !== "string" || !command.trim()) return false;
  if (/[\r\n;&|`]|\$\(|\$\{/u.test(command)) return false;
  const value = command.trim();
  return /^(?:gamb-php-(?:check|status|list|remove|stop|db-(?:check|status|start|stop))|gamb-php-serve)(?: --(?:all|stop|port [1-9][0-9]{2,4}))?$/.test(value)
    || /^gamb-php-discover --register(?: --root '(?:[^'\\]|\\.)+')?$/.test(value)
    || /^gamb-php-(?:check|status|list|remove|stop)(?: --path '(?:[^'\\]|\\.)+')?$/.test(value);
}

async function discoverFolder() {
  const selected = await vscode.window.showOpenDialog({
    canSelectFolders: true,
    canSelectFiles: false,
    canSelectMany: false,
    openLabel: "Descobrir projetos nesta pasta",
  });
  if (!selected?.[0]) return;
  runInTerminal(`${ACTIONS.discover} --root ${shellQuote(selected[0].fsPath)}`);
}

function decodePayload(uri) {
  const encoded = new URL(uri.toString()).searchParams.get("payload");
  if (!encoded) return null;
  return JSON.parse(Buffer.from(decodeURIComponent(encoded), "base64").toString("utf8"));
}

class DashboardViewProvider {
  constructor(context) {
    this.context = context;
  }

  resolveWebviewView(view) {
    view.webview.options = { enableScripts: true };
    view.webview.html = this.html();
    view.webview.onDidReceiveMessage(async (message) => {
      if (message.type === "discover") return discoverFolder();
      if (ACTIONS[message.type]) runInTerminal(ACTIONS[message.type]);
      if (message.type === "open") await vscode.commands.executeCommand("gambPhpServe.openDashboard");
    });
  }

  html() {
    const nonce = String(Date.now());
    return `<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; script-src 'nonce-${nonce}'"><style>body{font-family:var(--vscode-font-family);padding:12px;color:var(--vscode-foreground)}h2{margin-top:0}.grid{display:grid;gap:8px}button{padding:8px;border:0;border-radius:4px;color:var(--vscode-button-foreground);background:var(--vscode-button-background);cursor:pointer}button.secondary{color:var(--vscode-foreground);background:var(--vscode-button-secondaryBackground)}</style><h2>Gamb PHP Serve</h2><p>Controle o projeto atual sem abrir Laragon ou WAMP.</p><div class="grid"><button data-action="open">Abrir dashboard local</button><button data-action="start">Iniciar projeto</button><button data-action="stop">Parar projeto</button><button data-action="discover">Descobrir ou adicionar pasta</button><button data-action="dbStatus" class="secondary">Status do banco</button></div><script nonce="${nonce}">const api=acquireVsCodeApi();document.addEventListener('click',event=>{const action=event.target.closest('[data-action]');if(action)api.postMessage({type:action.dataset.action})})</script></html>`;
  }
}

function activate(context) {
  const provider = new DashboardViewProvider(context);
  context.subscriptions.push(
    vscode.window.registerWebviewViewProvider("gambPhpServe.dashboard", provider),
    vscode.commands.registerCommand("gambPhpServe.openDashboard", () => runInTerminal(ACTIONS.start)),
    vscode.commands.registerCommand("gambPhpServe.start", () => runInTerminal(ACTIONS.start)),
    vscode.commands.registerCommand("gambPhpServe.stop", () => runInTerminal(ACTIONS.stop)),
    vscode.commands.registerCommand("gambPhpServe.discover", discoverFolder),
    vscode.commands.registerCommand("gambPhpServe.dbStatus", () => runInTerminal(ACTIONS.dbStatus)),
    vscode.window.registerUriHandler({
      handleUri(uri) {
        try {
          const payload = decodePayload(uri);
          if (payload?.command && isAllowedCommand(payload.command)) {
            runInTerminal(payload.command, payload.path || workspacePath());
          } else if (payload?.command) {
            vscode.window.showErrorMessage("Gamb PHP Serve: comando nao permitido pelo painel.");
          }
        } catch (error) {
          vscode.window.showErrorMessage(`Gamb PHP Serve: URI invalida (${error.message})`);
        }
      },
    }),
  );
}

function deactivate() {}

module.exports = { activate, deactivate };
