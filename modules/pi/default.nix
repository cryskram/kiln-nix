{
  config,
  pkgs,
  user,
  ...
}:
let
  piPackages = import ../../pi/packages.nix { inherit pkgs; };
  piLens = pkgs.callPackage ../../pkgs/pi-lens.nix { };
  jevRouter = ../../pi/extensions/jev-router.ts;
  tokens = import ../../theme/tokens.nix;
  home = config.users.users.${user}.home;

  subagentContext = {
    inheritProjectContext = true;
    inheritGlobalContext = true;
    inheritSkills = true;
  };
  highThinking = subagentContext // {
    thinking = "high";
  };
  routedHighThinking = highThinking // {
    model = "auto";
  };

  freeCost = {
    input = 0;
    output = 0;
    cacheRead = 0;
    cacheWrite = 0;
  };

  companySkills = map (path: "${home}/Projects/TAP/${path}") [
    "claude-plugins/engineering/skills/backend/backend-coding-practices"
    "claude-plugins/engineering/skills/qa/backend-to-qa"
    "claude-plugins/engineering/skills/qa/web-to-qa"
    "claude-plugins/engineering/skills/qa/mobile-to-qa"
    "claude-plugins/engineering/skills/qa/generate-test-cases"
    "claude-plugins/engineering/skills/qa/qa-signoff"
    "claude-plugins/ultra-mariadb/skills/schema-reference"
    "claude-plugins/ultra-mariadb/skills/query-patterns"
    "phoenix/skills/phoenix"
  ];
in
{
  imports = [ ./mcp.nix ];

  programs.pi.coding-agent = {
    enable = true;
    package = pkgs.pi-coding-agent;

    environment = {
      PI_LENS_DISABLE_LSP_INSTALL.value = "1";
      PI_LENS_DISABLE_TOOL_INSTALL.value = "1";
    };

    settings = {
      # The virtual `auto` model lives under opencode-go because pi resolves credentials by provider.
      defaultProvider = "opencode-go";
      defaultModel = "auto";
      defaultThinkingLevel = "high";
      theme = tokens.pi;
      defaultTools = [ "+codemode" ];
      extensions = [ "-builtin:mcp" ];

      enableSkillCommands = true;
      hideThinkingBlock = false;
      showCacheMissNotices = false;
      autocompleteMaxVisible = 7;
      terminal.showTerminalProgress = true;
      compaction = {
        enabled = true;
        reserveTokens = 16384;
        keepRecentTokens = 20000;
      };
      retry = {
        enabled = true;
        baseDelayMs = 4000;
        maxRetries = 5;
        maxAgentDelayMs = 60000;
      };

      subagents = {
        defaultModel = "auto";
        defaultSubagentOnlyExtensions = [
          "${piPackages.pi-web-access}"
          "${jevRouter}"
        ];
        agentOverrides = {
          oracle = routedHighThinking;
          reviewer = routedHighThinking;
          researcher = routedHighThinking;
          evidence-auditor = subagentContext;
          delegate = subagentContext;
          worker = highThinking;
          scout = highThinking;
        };
      };

      guard = import ./guard.nix;
    };

    skills = [
      ../../pi/skills
      "${piPackages.pi-btw}/skills/btw"
      "${piLens}/lib/node_modules/pi-lens/skills"
    ];

    rules = ../../pi/brain/APPEND_SYSTEM.md;
    promptTemplates = [ ];

    themes = map (name: ../../pi/themes + "/${name}.json") [
      "catppuccin-macchiato"
      "catppuccin-mocha"
      "tokyo-night-storm"
      "gruvbox-dark"
      "kanagawa-wave"
      "everforest-dark"
    ];

    extraArgs = builtins.concatMap (path: [
      "--skill"
      path
    ]) companySkills;

    extensions = with piPackages; [
      "${pi-btw}"
      "${rpiv-ask-user-question}/${rpiv-ask-user-question.extensionPath}"
      "${rpiv-todo}/${rpiv-todo.extensionPath}"
      "${zentui}"
      "${pi-subagents}"
      "${pi-web-access}"
      "${pi-guard}"
      "${mcp-adapter}"
      "${piLens}/lib/node_modules/pi-lens"
      jevRouter
      ../../pi/extensions/querion-sync.ts
      ../../pi/extensions/stash.ts
      ../../pi/extensions/slack-message.ts
      ../../pi/extensions/google-workspace
    ];
  };

  environment.systemPackages = [ pkgs.opencode ];

  home-manager.users.${user} = {
    home.file = {
      ".pi/agent/AGENTS.md".source = ../../pi/brain/AGENTS.md;
      ".pi/agent/brain".source = ../../pi/brain;

      # pi-btw builds its own resource loader, so the router must be loaded there explicitly.
      ".pi/agent/btw.json".text = builtins.toJSON { extensions = [ "${jevRouter}" ]; };

      ".pi/agent/web-search.json".text = builtins.toJSON {
        workflow = "none";
        summaryModel = "opencode/claude-haiku-4-5";
        fetch = {
          answerProvider = "opencode";
          answerModel = "claude-haiku-4-5";
        };
      };

      ".pi/agent/models.json".text = builtins.toJSON {
        "$schema" = "https://pi.dev/schemas/models.schema.json";
        providers.ollama = {
          name = "Ollama (local)";
          baseUrl = "http://127.0.0.1:11434/v1";
          api = "openai-completions";
          apiKey = "ollama";
          models = [
            {
              id = "qwen2.5:3b";
              name = "Qwen2.5 3B (local)";
              contextWindow = 32768;
              maxTokens = 8192;
              cost = freeCost;
            }
            {
              id = "gemma3:4b";
              name = "Gemma 3 4B (local, vision)";
              input = [
                "text"
                "image"
              ];
              contextWindow = 131072;
              maxTokens = 8192;
              cost = freeCost;
            }
          ];
        };
      };
    };

    xdg.configFile = {
      "opencode/opencode.json".text = builtins.toJSON { "$schema" = "https://opencode.ai/config.json"; };
      "rpiv-todo/config.json".text = builtins.toJSON { collapseKey = "alt+t"; };
      "querion/config.json".text = builtins.toJSON {
        url = "https://querion-plum.vercel.app";
        tokenFile = "${home}/kiln-nix/secrets/querion-token";
      };
    };
  };
}
