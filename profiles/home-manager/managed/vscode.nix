{pkgs, ...}: {
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      ms-python.python
      ms-python.debugpy
      ms-python.black-formatter
      ms-ceintl.vscode-language-pack-zh-hans
    ];
    userSettings = {
      terminal.integrated.profiles.windows = {
        "git bash (login)" = {
          path = "D:\\Support\\Scoop\\apps\\git\\current\\bin\\bash.exe";
          args = [
            "--login"
            "-i"
          ];
        };
      };
      terminal.integrated.defaultProfile.windows = "git bash (login)";
      terminal.integrated.profiles.linux = {
        "fish (login)" = {
          path = "fish";
          args = [
            "--login"
          ];
        };
        "zsh (login)" = {
          path = "zsh";
          args = [
            "--login"
          ];
        };
      };
      terminal.integrated.defaultProfile.linux = "fish (login)";
      terminal.integrated.cursorStyle = "underline";
      terminal.integrated.cursorBlinking = true;
      terminal.integrated.fontFamily = "Dank Mono, Ubuntu Mono Ligaturized, JetBrainsMono Nerd Font Mono, JetBrains Mono NL, DengXian, FiraCode Nerd Font, FiraCode NF, Sarasa Mono TC, monospace";
      terminal.integrated.fontSize = 16;
      workbench.colorCustomizations = {
        terminal.background = "#282936";
        terminal.foreground = "#E9E9F4";
        terminalCursor.background = "#E9E9F4";
        terminalCursor.foreground = "#E9E9F4";
        terminal.ansiBlack = "#282936";
        terminal.ansiBlue = "#62D6E8";
        terminal.ansiBrightBlack = "#626483";
        terminal.ansiBrightBlue = "#62D6E8";
        terminal.ansiBrightCyan = "#A1EFE4";
        terminal.ansiBrightGreen = "#EBFF87";
        terminal.ansiBrightMagenta = "#B45BCF";
        terminal.ansiBrightRed = "#EA51B2";
        terminal.ansiBrightWhite = "#F7F7FB";
        terminal.ansiBrightYellow = "#00F769";
        terminal.ansiCyan = "#A1EFE4";
        terminal.ansiGreen = "#EBFF87";
        terminal.ansiMagenta = "#B45BCF";
        terminal.ansiRed = "#EA51B2";
        terminal.ansiWhite = "#E9E9F4";
        terminal.ansiYellow = "#00F769";
      };
      editor.bracketPairColorization.enabled = true;
      editor.guides.bracketPairs = "active";
      remote.SSH.defaultExtensions = [
        "esbenp.prettier-vscode"
        "dbaeumer.vscode-eslint"
        "eamodio.gitlens"
        "AlexDauenhauer.catppuccin-noctis"
      ];
      editor.inlayHints.enabled = "on";
      editor.lineHeight = 20;
      editor.tabSize = 2;
      editor.renderWhitespace = "all";
      editor.multiCursorModifier = "alt";
      editor.fontSize = 16;
      editor.fontFamily = "'Ubuntu Mono Ligaturized', 'JetBrainsMono Nerd Font Mono', 'JetBrains Mono NL', 'DengXian', 'FiraCode Nerd Font', 'FiraCode NF', FuraCode NF , 'SF Mono Nerd Font',  'Fira Code iScript', 'Operator Mono Lig', Dank Mono, Menlo, Monaco, 'Courier New', '等距更纱黑体 SC', 'Sarasa Mono TC', monospace";
      editor.fontWeight = "500";
      editor.fontLigatures = true;
      editor.rulers = [
        70
      ];
      editor.wordWrap = "on";
      editor.snippetSuggestions = "top";
      files.trimTrailingWhitespace = true;
      files.insertFinalNewline = true;
      files.associations = {
        "*.vue" = "vue";
        "*.json" = "jsonc";
        "sxhkdrc" = "ini";
        ".czrc" = "jsonc";
        ".huskyrc" = "jsonc";
        ".prettierrc" = "jsonc";
        ".commitlintrc" = "jsonc";
      };
      files.autoSave = "afterDelay";
      files.autoSaveDelay = 600000;
      files.exclude = {
        "**/.classpath " = true;
        "**/.DS_Store" = true;
        "**/.factorypath" = true;
        "**/.hg" = true;
        "**/.idea" = true;
        "**/.project" = true;
        "**/.sass-cache" = true;
        "**/.settings" = true;
        "**/.svn" = true;
        "**/node_modules" = true;
      };
      emmet.showAbbreviationSuggestions = true;
      emmet.showExpandedAbbreviation = "always";
      emmet.includeLanguages = {
        vue-html = "html";
        vue = "html";
        javascript = "javascriptreact";
        typescript = "typescriptreact";
      };
      emmet.syntaxProfiles = {
        vue-html = "html";
        vue = "html";
      };
      eslint.validate = [
        "javascript"
        "javascriptreact"
        "vue"
        "typescript"
        "typescriptreact"
      ];
      eslint.enable = true;
      javascript.validate.enable = false;
      typescript.validate.enable = true;
      editor.formatOnPaste = false;
      editor.formatOnSave = false;
      editor.codeActionsOnSave = {
        source.fixAll = "never";
      };
      typescript.inlayHints.parameterTypes.enabled = true;
      typescript.inlayHints.variableTypes.enabled = false;
      typescript.inlayHints.propertyDeclarationTypes.enabled = false;
      typescript.inlayHints.parameterNames.enabled = "all";
      typescript.inlayHints.functionLikeReturnTypes.enabled = false;
      stylelint.enable = true;
      css.validate = false;
      less.validate = false;
      scss.validate = false;
      prettier.trailingComma = "es5";
      prettier.singleQuote = true;
      prettier.semi = false;
      prettier.tabWidth = 2;
      "[jsonc]" = {
        editor.defaultFormatter = "numso.prettier-standard-vscode";
        editor.formatOnSave = true;
      };
      "[json]" = {
        editor.defaultFormatter = "esbenp.prettier-vscode";
      };
      "[md]" = {
        editor.defaultFormatter = "esbenp.prettier-vscode";
        editor.formatOnSave = true;
      };
      "[html]" = {
        editor.defaultFormatter = "vscode.html-language-features";
        editor.linkedEditing = true;
      };
      "[yaml]" = {
        editor.defaultFormatter = "esbenp.prettier-vscode";
      };
      gitlens.advanced.messages = {
      };
      bracketPairColorizer.consecutivePairColors = [
        [
          "<"
          "</"
        ]
        [
          "<"
          "/>"
        ]
        [
          "Gold"
          "Orchid"
          "LightSkyBlue"
        ]
        "Red"
      ];
      attrsSorter.order = [
        "class"
        "id"
        "name"
        "data-.+"
        "ng-.+"
        "src"
        "for"
        "type"
        "href"
        "values"
        "title"
        "alt"
        "role"
        "aria-.+"
        "$unknown$"
      ];
      vetur.validation.template = true;
      vetur.format.defaultFormatter.html = "js-beautify-html";
      vetur.format.defaultFormatterOptions = {
        js-beautify-html = {
          wrap_attributes = "force-aligned";
        };
      };
      vetur.format.defaultFormatter.css = "prettier";
      vetur.format.defaultFormatter.postcss = "prettier";
      vetur.format.defaultFormatter.scss = "prettier";
      vetur.format.defaultFormatter.less = "prettier";
      vetur.format.defaultFormatter.stylus = "stylus-supremacy";
      vetur.format.defaultFormatter.js = "prettier";
      vetur.format.defaultFormatter.ts = "prettier";
      javascript.updateImportsOnFileMove.enabled = "always";
      explorer.confirmDelete = false;
      go.autocompleteUnimportedPackages = true;
      go.gocodePackageLookupMode = "go";
      go.gotoSymbol.includeImports = true;
      go.useCodeSnippetsOnFunctionSuggest = true;
      go.inferGopath = true;
      go.useCodeSnippetsOnFunctionSuggestWithoutType = true;
      cmake.configureOnOpen = true;
      debug.allowBreakpointsEverywhere = true;
      editor.renderControlCharacters = true;
      editor.scrollBeyondLastLine = false;
      polacode.transparentBackground = false;
      polacode.target = "container";
      todo-tree.general.tags = [
        "TODO"
        "FIXME"
        "[ ]"
        "[x]"
      ];
      todo-tree.highlights.defaultHighlight = {
        gutterIcon = true;
      };
      todo-tree.highlights.customHighlight = {
        "TODO:" = {
          foreground = "#fff";
          background = "#ffbd2a";
          iconColour = "#ffbd2a";
        };
        "FIXME:" = {
          foreground = "#fff";
          background = "#f06292";
          icon = "flame";
          iconColour = "#f06292";
        };
      };
      vscode-neovim.logOutputToConsole = true;
      vscode-neovim.neovimExecutablePaths.win32 = "C:\\Support\\Scoop\\apps\\neovim-nightly\\current\\bin\\nvim.exe";
      vscode-neovim.neovimExecutablePaths.linux = "nvim";
      vscode-neovim.useCtrlKeysForInsertMode = false;
      vscode-neovim.useCtrlKeysForNormalMode = false;
      vscode-neovim.useWSL = true;
      files.eol = "\n";
      git.autofetch = false;
      vscode_custom_css.imports = [
        "file:///home/backtolife/vscode.custom.css"
      ];
      vscode_custom_css.policy = true;
      workbench.editorAssociations = {
        "*.code-workspace" = "default";
      };
      typescript.updateImportsOnFileMove.enabled = "always";
      javascript.preferences.quoteStyle = "single";
      typescript.preferences.quoteStyle = "single";
      svg.preview.mode = "svg";
      keyboard.dispatch = "keyCode";
      workbench.list.automaticKeyboardNavigation = false;
      workbench.editor.enablePreviewFromQuickOpen = false;
      terminal.external.linuxExec = "kitty";
      terminal.explorerKind = "external";
      colorize.languages = [
        "css"
        "sass"
        "scss"
        "less"
        "postcss"
        "sss"
        "stylus"
        "xml"
        "svg"
        "c"
        "cpp"
        "python"
      ];
      todo-tree.regex.regex = "(//|#|<!--|;|/\\*|^|^\\s*(-|\\d+.))\\s*($TAGS)";
      workbench.editor.enablePreviewFromCodeNavigation = true;
      terminal.integrated.tabs.enabled = true;
      json.schemas = [
        {
          fileMatch = [
            ".prettierrc"
            ".prettierrc.json"
          ];
          url = "https://cdn.jsdelivr.net/gh/aMarCruz/prettier/schema.json";
        }
      ];
      redhat.telemetry.enabled = true;
      "[markdown]" = {
        editor.defaultFormatter = "esbenp.prettier-vscode";
      };
      editor.acceptSuggestionOnEnter = "smart";
      editor.acceptSuggestionOnCommitCharacter = false;
      security.workspace.trust.untrustedFiles = "newWindow";
      window.menuBarVisibility = "toggle";
      deno.enable = false;
      editor.unicodeHighlight.ambiguousCharacters = false;
      vscode-neovim.neovimExecutablePaths.darwin = "/usr/local/bin/nvim";
      Lua.telemetry.enable = true;
      emmet.showSuggestionsAsSnippets = true;
      emmet.triggerExpansionOnTab = true;
      svg.completion.emmet = true;
      cssModules.camelCase = false;
      editor.parameterHints.cycle = true;
      javascript.inlayHints.parameterNames.enabled = "all";
      javascript.inlayHints.parameterTypes.enabled = true;
      javascript.suggest.completeFunctionCalls = true;
      typescript.suggest.completeFunctionCalls = true;
      editor.inlineSuggest.enabled = true;
      "[typescriptreact] " = {
        editor.defaultFormatter = "esbenp.prettier-vscode";
      };
      "[less]" = {
        editor.defaultFormatter = "vscode.css-language-features";
      };
      "[typescript]" = {
        editor.defaultFormatter = "numso.prettier-standard-vscode";
      };
      "[javascript]" = {
        editor.defaultFormatter = "vscode.typescript-language-features";
      };
      "[dart]" = {
        editor.formatOnSave = true;
        editor.formatOnType = true;
        editor.rulers = [
          90
        ];
        editor.selectionHighlight = false;
        editor.suggest.snippetsPreventQuickSuggestions = false;
        editor.suggestSelection = "first";
        editor.tabCompletion = "onlySnippets";
        editor.wordBasedSuggestions = "off";
      };
      "[rust]" = {
        editor.defaultFormatter = "rust-lang.rust-analyzer";
        editor.formatOnSave = true;
      };
      editor.stickyScroll.enabled = true;
      "[lua]" = {
        editor.defaultFormatter = "sumneko.lua";
      };
      "[python]" = {
        editor.formatOnType = true;
        editor.formatOnSave = true;
        editor.defaultFormatter = "ms-python.black-formatter";
      };
      settingsSync.ignoredExtensions = [
      ];
      dotnet.autoDetect = "off";
      omnisharp.dotNetCliPaths = [
        "D:\\scoop\\local\\apps\\dotnet-sdk\\current\\dotnet.exe"
      ];
      omnisharp.sdkPath = "D:\\scoop\\local\\apps\\dotnet-sdk\\current\\sdk\\7.0.306";
      dotnet.server.useOmnisharp = true;
      dotnetAcquisitionExtension.existingDotnetPath = [
        "D:\\scoop\\local\\apps\\dotnet-sdk\\current"
      ];
      standard.engine = "ts-standard";
      typescript.preferences.importModuleSpecifier = "non-relative";
      javascript.preferences.importModuleSpecifier = "non-relative";
      "[swift]" = {
        editor.defaultFormatter = "vknabel.vscode-apple-swift-format";
      };
      "[objective-c]" = {
        editor.defaultFormatter = "xaver.clang-format";
      };
      window.commandCenter = false;
      editor.minimap.maxColumn = 50;
      editor.wordWrapColumn = 40;
      codesandbox.currentWorkspace = "5e446690-3af1-4b63-998b-9c68144a7137";
      editor.unicodeHighlight.includeComments = false;
      workbench.colorTheme = "Catppuccin Noctis Mocha";
      window.zoomLevel = 1;
      editor.unicodeHighlight.nonBasicASCII = false;
      git.openRepositoryInParentFolders = "always";
    };
  };
}
