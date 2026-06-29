(function () {
  const data = window.gambPhpPageData || {};
  const state = {
    mode: data.mode || "static",
    projects: Array.isArray(data.sampleProjects) ? data.sampleProjects.slice() : [],
    selectedProjectPath: data.currentProjectPath || "",
    actionShells: {},
    terminalResult: null,
  };

  const actionDefinitions = [
    {
      id: "check",
      label: "Verificar ambiente",
      description: "Cheque requisitos e contexto do projeto selecionado.",
      icon: "check",
      scope: "project",
      command: "gamb-php-check",
      executeLabel: "Executar aqui",
    },
    {
      id: "serve",
      label: "Iniciar projeto atual",
      description: "Inicializa o projeto selecionado com a porta registrada.",
      icon: "play",
      scope: "project",
      command: "gamb-php-serve",
      executeLabel: "Executar aqui",
    },
    {
      id: "stop",
      label: "Parar projeto atual",
      description: "Encerra o servidor do projeto selecionado.",
      icon: "stop",
      scope: "project",
      command: "gamb-php-stop",
      executeLabel: "Executar aqui",
      danger: true,
    },
    {
      id: "list",
      label: "Listar projetos",
      description: "Mostra todos os projetos implantados localmente.",
      icon: "list",
      scope: "global",
      command: "gamb-php-list",
      executeLabel: "Executar aqui",
    },
    {
      id: "status_all",
      label: "Status geral",
      description: "Consulta o estado completo de todos os projetos.",
      icon: "status",
      scope: "global",
      command: "gamb-php-status --all",
      executeLabel: "Executar aqui",
    },
    {
      id: "remove",
      label: "Remover projeto",
      description: "Remove o projeto selecionado do catalogo local.",
      icon: "trash",
      scope: "project",
      command: "gamb-php-remove",
      executeLabel: "Executar aqui",
      danger: true,
    },
  ];

  const iconMap = {
    arrow:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M13.17 5.17a1 1 0 0 1 1.41 0l6.25 6.25a1 1 0 0 1 0 1.41l-6.25 6.25a1 1 0 1 1-1.41-1.41L17.71 13H4a1 1 0 1 1 0-2h13.71l-4.54-4.83a1 1 0 0 1 0-1.41Z"/></svg>',
    external:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M14 4h6v6h-2V7.41l-8.29 8.3-1.42-1.42 8.3-8.29H14V4Zm-8 2h5v2H6v10h10v-5h2v5a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2Z"/></svg>',
    github:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M12 .75a11.25 11.25 0 0 0-3.56 21.92c.56.1.77-.24.77-.54v-2.1c-3.13.68-3.8-1.51-3.8-1.51-.5-1.28-1.23-1.62-1.23-1.62-1-.7.08-.69.08-.69 1.12.08 1.7 1.15 1.7 1.15.99 1.7 2.6 1.21 3.24.92.1-.72.39-1.22.7-1.5-2.5-.28-5.14-1.25-5.14-5.58 0-1.23.44-2.23 1.15-3.02-.11-.29-.5-1.43.12-2.99 0 0 .95-.3 3.12 1.16a10.8 10.8 0 0 1 5.69 0c2.16-1.46 3.1-1.16 3.1-1.16.63 1.56.24 2.7.12 2.99.72.79 1.15 1.8 1.15 3.02 0 4.34-2.65 5.29-5.18 5.57.41.35.77 1.03.77 2.08v3.08c0 .3.2.65.78.54A11.25 11.25 0 0 0 12 .75Z"/></svg>',
    check:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M12 1.75A10.25 10.25 0 1 0 22.25 12 10.26 10.26 0 0 0 12 1.75Zm4.78 7.78-5.43 6.5a1 1 0 0 1-1.48.07l-2.65-2.64a1 1 0 1 1 1.42-1.42l1.88 1.87 4.72-5.64a1 1 0 0 1 1.54 1.26Z"/></svg>',
    play:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M12 1.75A10.25 10.25 0 1 0 22.25 12 10.26 10.26 0 0 0 12 1.75Zm-1.67 6.9 5.42 3.16a1.25 1.25 0 0 1 0 2.16l-5.42 3.16A1.25 1.25 0 0 1 8.5 16.05V8.73a1.25 1.25 0 0 1 1.83-1.08Z"/></svg>',
    stop:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M12 1.75A10.25 10.25 0 1 0 22.25 12 10.26 10.26 0 0 0 12 1.75Zm3 13.25a1 1 0 0 1-1 1h-4a1 1 0 0 1-1-1v-4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1Z"/></svg>',
    list:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M5 5.75A1.75 1.75 0 1 1 3.25 7.5 1.75 1.75 0 0 1 5 5.75Zm4 1.25a1 1 0 0 1 1-1h10a1 1 0 1 1 0 2H10A1 1 0 0 1 9 7Zm0 10a1 1 0 0 1 1-1h10a1 1 0 1 1 0 2H10A1 1 0 0 1 9 17Zm-4-2.75A1.75 1.75 0 1 1 3.25 16 1.75 1.75 0 0 1 5 14.25Zm0-4.25A1.75 1.75 0 1 1 6.75 11.75 1.75 1.75 0 0 1 5 10Zm4 1.75a1 1 0 0 1 1-1h10a1 1 0 1 1 0 2H10a1 1 0 0 1-1-1Z"/></svg>',
    status:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M5 20.25A1.25 1.25 0 0 1 3.75 19V5A1.25 1.25 0 0 1 5 3.75h14A1.25 1.25 0 0 1 20.25 5v14A1.25 1.25 0 0 1 19 20.25Zm.75-1.5h12.5V5.25H5.75ZM8.5 16.5a1 1 0 0 1-1-1v-3a1 1 0 1 1 2 0v3a1 1 0 0 1-1 1Zm3 0a1 1 0 0 1-1-1V9a1 1 0 1 1 2 0v6.5a1 1 0 0 1-1 1Zm3 0a1 1 0 0 1-1-1v-4.5a1 1 0 1 1 2 0v4.5a1 1 0 0 1-1 1Z"/></svg>',
    trash:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M9.5 3.75A1.75 1.75 0 0 0 7.75 5.5v.25H4.5a1 1 0 1 0 0 2h.72l.88 11.05A2.25 2.25 0 0 0 8.34 20.9h7.32a2.25 2.25 0 0 0 2.24-2.1l.88-11.05h.72a1 1 0 1 0 0-2h-3.25V5.5A1.75 1.75 0 0 0 14.5 3.75Zm5.14 4L13.8 18.9h-3.6L9.36 7.75ZM9.75 5.5A.25.25 0 0 1 10 5.25h4a.25.25 0 0 1 .25.25v.25H9.75Z"/></svg>',
  };

  function qs(selector) {
    return document.querySelector(selector);
  }

  function qsa(selector) {
    return Array.from(document.querySelectorAll(selector));
  }

  function icon(name) {
    return iconMap[name] || "";
  }

  function escapeHtml(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function normalizeProjects(projects) {
    return (projects || []).map((project, index) => ({
      id: project.id || project.path || project.slug || "project-" + index,
      name: project.name || "Projeto local",
      slug: project.slug || "project-" + index,
      path: project.path || "",
      type: project.type || "php_root",
      port: String(project.port || "8000"),
      iconUrl: project.iconUrl || "",
      monogram: project.monogram || (project.name || "P").slice(0, 1).toUpperCase(),
      recentLabel: project.recentLabel || "Registro recente",
      url: project.url || "",
      panelUrl: project.panelUrl || "",
      running: Boolean(project.running),
      isCurrent: Boolean(project.isCurrent),
      subtitle: project.subtitle || project.type || "Projeto PHP",
      basePath: project.basePath || "",
      instancesCount: Number(project.instancesCount || 1),
      description: project.description || "",
    }));
  }

  function getSelectedProject() {
    if (!state.projects.length) {
      return null;
    }

    if (state.selectedProjectPath) {
      const match = state.projects.find((project) => project.path === state.selectedProjectPath);
      if (match) {
        return match;
      }
    }

    const current = state.projects.find((project) => project.isCurrent);
    if (current) {
      state.selectedProjectPath = current.path;
      return current;
    }

    state.selectedProjectPath = state.projects[0].path;
    return state.projects[0];
  }

  function getShell(actionId) {
    return state.actionShells[actionId] || "bash";
  }

  function setShell(actionId, shell) {
    state.actionShells[actionId] = shell;
    renderActions();
  }

  function buildBashCommand(action, project) {
    const needsProject = action.scope === "project";
    const prefix = needsProject && project && project.path ? "cd '" + project.path.replace(/'/g, "'\\''") + "' && " : "";
    return prefix + action.command;
  }

  function buildShellCommand(action, project, shell) {
    const bashCommand = buildBashCommand(action, project);
    if (shell === "bash") {
      return bashCommand;
    }

    const escaped = bashCommand.replace(/"/g, '\\"');
    if (shell === "powershell") {
      return '& "$env:ProgramFiles\\Git\\bin\\bash.exe" -lc "' + escaped + '"';
    }

    return '"%ProgramFiles%\\Git\\bin\\bash.exe" -lc "' + escaped + '"';
  }

  function setSelectedProject(path) {
    state.selectedProjectPath = path;
    renderProjects();
    renderActions();
  }

  function renderProjectIdentity(project) {
    if (project.iconUrl) {
      return '<img class="project-logo" src="' + escapeHtml(project.iconUrl) + '" alt="" loading="lazy">';
    }

    return '<div class="project-logo-fallback">' + escapeHtml(project.monogram) + "</div>";
  }

  function renderProjects() {
    const projectGrid = qs(".js-project-grid");
    const projectList = qs(".js-project-list");
    const selectedProject = getSelectedProject();
    const recentProjects = state.projects.slice(0, 4);
    const otherProjects = state.projects.slice(4);

    if (projectGrid) {
      projectGrid.innerHTML = recentProjects
        .map((project) => {
          const isCurrent = selectedProject && selectedProject.path === project.path;
          const typeLabel = project.type === "wordpress" ? "WordPress" : project.type === "php_public" ? "PHP Public" : project.type === "laravel" ? "Laravel" : "PHP";
          return (
            '<article class="project-card' +
            (isCurrent ? " is-current" : "") +
            '" data-path="' +
            escapeHtml(project.path) +
            '">' +
            '<div class="project-headline">' +
            renderProjectIdentity(project) +
            '<div class="project-title-group">' +
            "<h3>" +
            escapeHtml(project.name) +
            "</h3>" +
            '<div class="project-chip-row"><span class="chip' +
            (project.type === "wordpress" ? " is-wordpress" : "") +
            '">' +
            escapeHtml(typeLabel) +
            "</span>" +
            (project.isCurrent ? '<span class="micro-badge">Atual</span>' : "") +
            "</div></div></div>" +
            '<div class="project-metrics">' +
            '<div class="metric"><label>Ordem recente</label><strong>' +
            escapeHtml(project.recentLabel) +
            "</strong></div>" +
            '<div class="metric"><label>Porta</label><strong>:' +
            escapeHtml(project.port) +
            "</strong></div>" +
            '<div class="metric"><label>Status</label><strong>' +
            (project.running ? "Rodando" : "Parado") +
            "</strong></div>" +
            '<div class="metric"><label>Instancias</label><strong>' +
            escapeHtml(String(project.instancesCount)) +
            "</strong></div>" +
            "</div>" +
            '<p class="project-url">' +
            escapeHtml(project.url || "Sem URL registrada") +
            "</p>" +
            '<div class="card-actions">' +
            '<button class="project-card-button js-open-project" data-path="' +
            escapeHtml(project.path) +
            '">' +
            "<span>" +
            (project.running ? "Abrir no navegador" : "Executar agora") +
            "</span>" +
            '<span aria-hidden="true">' +
            icon(project.running ? "external" : "play") +
            "</span></button>" +
            '<button class="project-card-button secondary js-select-project" data-path="' +
            escapeHtml(project.path) +
            '">' +
            "<span>Usar nas acoes</span><span aria-hidden=\"true\">" +
            icon("arrow") +
            "</span></button></div></article>"
          );
        })
        .join("");
    }

    if (projectList) {
      projectList.innerHTML = otherProjects
        .map((project) => {
          const isSelected = selectedProject && selectedProject.path === project.path;
          return (
            '<button class="project-list-item' +
            (isSelected ? " is-selected" : "") +
            ' js-select-project" data-path="' +
            escapeHtml(project.path) +
            '">' +
            renderProjectIdentity(project) +
            "<span><strong>" +
            escapeHtml(project.name) +
            "</strong><small>" +
            escapeHtml(project.running ? "rodando" : "pronto para iniciar") +
            '</small></span><small>:' +
            escapeHtml(project.port) +
            "</small></button>"
          );
        })
        .join("");

      if (!otherProjects.length) {
        projectList.innerHTML = '<div class="ghost-note">Os projetos extras aparecerao aqui conforme o catalogo crescer.</div>';
      }
    }

    qsa(".js-select-project").forEach((button) => {
      button.addEventListener("click", () => setSelectedProject(button.getAttribute("data-path") || ""));
    });

    qsa(".js-open-project").forEach((button) => {
      button.addEventListener("click", async () => {
        const path = button.getAttribute("data-path") || "";
        const project = state.projects.find((item) => item.path === path);
        if (!project) return;
        setSelectedProject(project.path);
        if (state.mode === "local") {
          await runActionRequest("open_project", project);
        } else if (project.url) {
          window.open(project.url, "_blank", "noopener");
        } else {
          await copyText(buildShellCommand(actionDefinitions[1], project, "bash"));
          notify("Comando copiado para iniciar o projeto.");
        }
      });
    });
  }

  function renderActions() {
    const grid = qs(".js-action-grid");
    const selected = getSelectedProject();
    const label = qs(".js-selected-project-label");
    if (label) {
      label.textContent = selected ? selected.name : "Nenhum projeto selecionado";
    }

    if (!grid) {
      return;
    }

    grid.innerHTML = actionDefinitions
      .map((action) => {
        const shell = getShell(action.id);
        const command = buildShellCommand(action, selected, shell);
        const disabled = action.scope === "project" && !selected;
        return (
          '<article class="action-card" data-action="' +
          escapeHtml(action.id) +
          '">' +
          '<div class="project-card-header"><div class="action-icon' +
          (action.danger ? " danger" : "") +
          '">' +
          icon(action.icon) +
          "</div></div>" +
          "<div><h3>" +
          escapeHtml(action.label) +
          "</h3><p>" +
          escapeHtml(action.description) +
          "</p></div>" +
          '<div class="shell-tabs">' +
          ["cmd", "powershell", "bash"]
            .map((item) =>
              '<button class="shell-tab' +
              (shell === item ? " is-active" : "") +
              '" data-action="' +
              escapeHtml(action.id) +
              '" data-shell="' +
              escapeHtml(item) +
              '">' +
              escapeHtml(item === "cmd" ? "CMD" : item === "powershell" ? "PowerShell" : "Bash") +
              "</button>"
            )
            .join("") +
          "</div>" +
          '<pre class="terminal-command">' +
          escapeHtml(command) +
          "</pre>" +
          '<div class="card-actions">' +
          '<button class="button primary js-run-action" data-action="' +
          escapeHtml(action.id) +
          '"' +
          (disabled || state.mode !== "local" ? " disabled" : "") +
          ">" +
          escapeHtml(action.executeLabel) +
          "</button>" +
          '<button class="ghost-button js-copy-action" data-action="' +
          escapeHtml(action.id) +
          '">' +
          "Copiar" +
          "</button>" +
          '<button class="ghost-button js-bridge-action" data-action="' +
          escapeHtml(action.id) +
          '">' +
          "Abrir no VS Code" +
          "</button></div></article>"
        );
      })
      .join("");

    qsa(".shell-tab").forEach((button) => {
      button.addEventListener("click", () => {
        setShell(button.getAttribute("data-action") || "", button.getAttribute("data-shell") || "bash");
      });
    });

    qsa(".js-copy-action").forEach((button) => {
      button.addEventListener("click", async () => {
        const action = actionDefinitions.find((item) => item.id === button.getAttribute("data-action"));
        if (!action) return;
        const command = buildShellCommand(action, selected, getShell(action.id));
        await copyText(command);
        notify("Comando copiado.");
      });
    });

    qsa(".js-run-action").forEach((button) => {
      button.addEventListener("click", async () => {
        const action = actionDefinitions.find((item) => item.id === button.getAttribute("data-action"));
        if (!action) return;
        await runActionRequest(action.id, selected);
      });
    });

    qsa(".js-bridge-action").forEach((button) => {
      button.addEventListener("click", async () => {
        const action = actionDefinitions.find((item) => item.id === button.getAttribute("data-action"));
        if (!action) return;
        const shell = getShell(action.id);
        const command = buildShellCommand(action, selected, shell);
        await copyText(command);
        openVsCodeBridge({
          action: action.id,
          shell,
          command,
          path: selected ? selected.path : "",
        });
      });
    });
  }

  function renderTerminalResult() {
    const panel = qs(".js-terminal-panel");
    const meta = qs(".js-terminal-meta");
    const output = qs(".js-terminal-output");
    if (!panel || !meta || !output) {
      return;
    }

    if (!state.terminalResult) {
      panel.classList.remove("is-visible");
      return;
    }

    panel.classList.add("is-visible");
    meta.textContent = state.terminalResult.meta || "";
    output.textContent = state.terminalResult.output || "Nenhuma saida retornada.";
  }

  function portfolioFallback() {
    return Array.isArray(data.portfolioFallback)
      ? data.portfolioFallback
      : [
          {
            name: "gamb-php-serve",
            description: "Bash tool para gerenciar projetos PHP locais com dashboard visual e GitHub Pages.",
            url: data.repoUrl || "#",
            tags: ["bash", "php", "cli"],
            stars: 0,
            downloads: 0,
          },
          {
            name: "Starter Pack",
            description: "Base para empacotar novas automacoes locais e documentacao de uso rapido.",
            url: data.repoUrl || "#",
            tags: ["templates", "workflow"],
            stars: 0,
            downloads: 0,
          },
          {
            name: "Documentacao",
            description: "Comandos, instalacao, funcionamento e exemplos ligados a esta entrega.",
            url: data.docsLinks && data.docsLinks.commands ? data.docsLinks.commands : "#",
            tags: ["docs"],
            stars: 0,
            downloads: 0,
          },
        ];
  }

  function normalizePortfolio(payload) {
    const list = Array.isArray(payload)
      ? payload
      : Array.isArray(payload && payload.items)
      ? payload.items
      : Array.isArray(payload && payload.repositories)
      ? payload.repositories
      : [];

    return list
      .map((item) => ({
        name: item.name || item.title || item.repo || "Solucao",
        description: item.description || item.summary || "Repositorio em destaque.",
        url: item.url || item.html_url || item.link || "#",
        tags: Array.isArray(item.tags) ? item.tags : Array.isArray(item.stack) ? item.stack : [],
        stars: Number(item.stars || item.stargazers_count || 0),
        downloads: Number(item.downloads || item.download_count || item.watchers_count || 0),
      }))
      .filter((item) => item.name);
  }

  function renderPortfolio(items) {
    const grid = qs(".js-portfolio-grid");
    if (!grid) {
      return;
    }

    const entries = items.length ? items : portfolioFallback();
    grid.innerHTML = entries
      .slice(0, 3)
      .map((item) => {
        const meta = [];
        if (Number.isFinite(item.stars)) meta.push('<span>★ ' + escapeHtml(String(item.stars)) + "</span>");
        if (Number.isFinite(item.downloads)) meta.push('<span>↧ ' + escapeHtml(String(item.downloads)) + "</span>");
        return (
          '<article class="portfolio-card"><div class="portfolio-card-head"><div>' +
          "<h3>" +
          escapeHtml(item.name) +
          "</h3><p>" +
          escapeHtml(item.description) +
          "</p></div></div>" +
          '<div class="portfolio-meta">' +
          (Array.isArray(item.tags) && item.tags.length
            ? item.tags.map((tag) => '<span class="chip">' + escapeHtml(tag) + "</span>").join("")
            : '<span class="ghost-note">Componente dinamico em implantacao.</span>') +
          "</div>" +
          '<div class="portfolio-meta">' +
          meta.join("") +
          "</div>" +
          '<div class="card-actions"><a class="button secondary" href="' +
          escapeHtml(item.url) +
          '" target="_blank" rel="noreferrer">Abrir link</a></div></article>'
        );
      })
      .join("");
  }

  async function loadPortfolio() {
    const sources = Array.isArray(data.portfolioSources) ? data.portfolioSources : [];
    for (const source of sources) {
      try {
        const response = await fetch(source, { cache: "no-store" });
        if (!response.ok) {
          continue;
        }
        const payload = await response.json();
        const normalized = normalizePortfolio(payload);
        if (normalized.length) {
          renderPortfolio(normalized);
          return;
        }
      } catch (error) {
        continue;
      }
    }

    renderPortfolio([]);
  }

  async function loadProjects() {
    if (state.mode !== "local" || !data.api || !data.api.projects) {
      state.projects = normalizeProjects(state.projects);
      renderProjects();
      renderActions();
      return;
    }

    try {
      const response = await fetch(data.api.projects, { cache: "no-store" });
      if (!response.ok) {
        throw new Error("Falha ao carregar projetos.");
      }
      const payload = await response.json();
      state.projects = normalizeProjects(payload.projects || []);
      if (payload.currentProjectPath) {
        state.selectedProjectPath = payload.currentProjectPath;
      }
      renderProjects();
      renderActions();
    } catch (error) {
      state.terminalResult = {
        meta: "Leitura do catalogo local",
        output: "Nao foi possivel carregar a lista dinamica de projetos.\n" + error.message,
      };
      renderProjects();
      renderActions();
      renderTerminalResult();
    }
  }

  async function runActionRequest(actionId, project) {
    if (state.mode !== "local" || !data.api || !data.api.action) {
      return;
    }

    const payload = {
      action: actionId,
      path: project && project.path ? project.path : "",
    };

    try {
      const response = await fetch(data.api.action, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      const result = await response.json();
      state.terminalResult = {
        meta: result.meta || "Acao local",
        output: [result.stdout || "", result.stderr || ""].filter(Boolean).join("\n"),
      };
      renderTerminalResult();
      if (result.url) {
        window.open(result.url, "_blank", "noopener");
      }
      if (result.projects) {
        state.projects = normalizeProjects(result.projects);
      }
      if (result.currentProjectPath) {
        state.selectedProjectPath = result.currentProjectPath;
      }
      renderProjects();
      renderActions();
      if (result.notice) {
        notify(result.notice);
      }
    } catch (error) {
      state.terminalResult = {
        meta: "Acao local",
        output: "Falha ao executar a acao.\n" + error.message,
      };
      renderTerminalResult();
    }
  }

  async function copyText(text) {
    try {
      await navigator.clipboard.writeText(text);
    } catch (error) {
      const temp = document.createElement("textarea");
      temp.value = text;
      document.body.appendChild(temp);
      temp.select();
      document.execCommand("copy");
      temp.remove();
    }
  }

  function openVsCodeBridge(payload) {
    const uriBase = data.vscodeBridgeBase || "vscode://gamberine.gamb-php-serve/terminal?payload=";
    const encoded = window.btoa(unescape(encodeURIComponent(JSON.stringify(payload))));
    notify("Comando copiado. A ponte do VS Code fica pronta para a extensao complementar.");
    window.location.href = uriBase + encodeURIComponent(encoded);
  }

  function notify(message) {
    const node = qs(".js-toast");
    if (!node) {
      return;
    }
    node.textContent = message;
    node.classList.remove("hidden");
    clearTimeout(notify.timer);
    notify.timer = setTimeout(() => node.classList.add("hidden"), 3200);
  }

  function wireStaticLinks() {
    const projectLink = qs(".js-current-project-link");
    const panelLink = qs(".js-dashboard-link");
    if (projectLink && data.projectUrl) {
      projectLink.href = data.projectUrl;
    }
    if (panelLink && data.dashboardUrl) {
      panelLink.href = data.dashboardUrl;
    }
  }

  document.addEventListener("DOMContentLoaded", async () => {
    wireStaticLinks();
    await loadProjects();
    await loadPortfolio();
    renderTerminalResult();
  });
})();
