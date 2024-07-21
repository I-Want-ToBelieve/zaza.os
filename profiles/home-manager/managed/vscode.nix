{pkgs, ...}: {
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      ms-python.python
      ms-python.debugpy
      ms-python.black-formatter
      ms-ceintl.vscode-language-pack-zh-hans
      catppuccin.catppuccin-vsc
      catppuccin.catppuccin-vsc-icons
    ];
    userSettings = {
      "[dart]" = {
        "editor.formatOnSave" = true;
        "editor.formatOnType" = true;
        "editor.rulers" = [
          90
        ];
        "editor.selectionHighlight" = false;
        "editor.suggest.snippetsPreventQuickSuggestions" = false;
        "editor.suggestSelection" = "first";
        "editor.tabCompletion" = "onlySnippets";
        "editor.wordBasedSuggestions" = "off";
      };
      "[html]" = {
        "editor.defaultFormatter" = "vscode.html-language-features";
        "editor.linkedEditing" = true;
      };
      "[javascript]" = {
        "editor.defaultFormatter" = "vscode.typescript-language-features";
      };
      "[json]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "[jsonc]" = {
        "editor.defaultFormatter" = "numso.prettier-standard-vscode";
        "editor.formatOnSave" = true;
      };
      "[less]" = {
        "editor.defaultFormatter" = "vscode.css-language-features";
      };
      "[lua]" = {
        "editor.defaultFormatter" = "sumneko.lua";
      };
      "[markdown]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "[md]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "editor.formatOnSave" = true;
      };
      "[objective-c]" = {
        "editor.defaultFormatter" = "xaver.clang-format";
      };
      "[python]" = {
        "editor.formatOnType" = true;
      };
      "[rust]" = {
        "editor.defaultFormatter" = "rust-lang.rust-analyzer";
        "editor.formatOnSave" = true;
      };
      "[swift]" = {
        "editor.defaultFormatter" = "vknabel.vscode-apple-swift-format";
      };
      "[typescript]" = {
        "editor.defaultFormatter" = "numso.prettier-standard-vscode";
      };
      "[typescriptreact]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "[yaml]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "attrsSorter.order" = [
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
      "bracketPairColorizer.consecutivePairColors" = [
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
      "cmake.configureOnOpen" = true;
      "codesandbox.currentWorkspace" = "5e446690-3af1-4b63-998b-9c68144a7137";
      "colorize.languages" = [
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
      "css.validate" = false;
      "cssModules.camelCase" = false;
      "debug.allowBreakpointsEverywhere" = true;
      "deno.enable" = false;
      "dotnet.autoDetect" = "off";
      "dotnet.server.useOmnisharp" = true;
      "dotnetAcquisitionExtension.existingDotnetPath" = [
        "D:\\scoop\\local\\apps\\dotnet-sdk\\current"
      ];
      "editor.acceptSuggestionOnCommitCharacter" = false;
      "editor.acceptSuggestionOnEnter" = "smart";
      "editor.bracketPairColorization.enabled" = true;
      "editor.codeActionsOnSave" = {
        "source.fixAll" = "never";
      };
      "editor.fontFamily" = "'Ubuntu Mono Ligaturized', 'JetBrainsMono Nerd Font Mono', 'JetBrains Mono NL', 'DengXian', 'FiraCode Nerd Font', 'FiraCode NF', FuraCode NF , 'SF Mono Nerd Font',  'Fira Code iScript', 'Operator Mono Lig', Dank Mono, Menlo, Monaco, 'Courier New', '\u7b49\u8ddd\u66f4\u7eb1\u9ed1\u4f53 SC', 'Sarasa Mono TC', monospace";
      "editor.fontLigatures" = true;
      "editor.fontSize" = 16;
      "editor.fontWeight" = "500";
      "editor.formatOnPaste" = false;
      "editor.formatOnSave" = false;
      "editor.guides.bracketPairs" = "active";
      "editor.inlayHints.enabled" = "on";
      "editor.inlineSuggest.enabled" = true;
      "editor.lineHeight" = 20;
      "editor.minimap.maxColumn" = 50;
      "editor.multiCursorModifier" = "alt";
      "editor.parameterHints.cycle" = true;
      "editor.renderControlCharacters" = true;
      "editor.renderWhitespace" = "all";
      "editor.rulers" = [
        70
      ];
      "editor.scrollBeyondLastLine" = false;
      "editor.snippetSuggestions" = "top";
      "editor.stickyScroll.enabled" = true;
      "editor.tabSize" = 2;
      "editor.unicodeHighlight.ambiguousCharacters" = false;
      "editor.unicodeHighlight.includeComments" = false;
      "editor.unicodeHighlight.nonBasicASCII" = false;
      "editor.wordWrap" = "on";
      "editor.wordWrapColumn" = 40;
      "emmet.includeLanguages" = {
        javascript = "javascriptreact";
        typescript = "typescriptreact";
        vue = "html";
        "vue-html" = "html";
      };
      "emmet.showAbbreviationSuggestions" = true;
      "emmet.showExpandedAbbreviation" = "always";
      "emmet.showSuggestionsAsSnippets" = true;
      "emmet.syntaxProfiles" = {
        vue = "html";
        "vue-html" = "html";
      };
      "emmet.triggerExpansionOnTab" = true;
      "eslint.enable" = true;
      "eslint.validate" = [
        "javascript"
        "javascriptreact"
        "vue"
        "typescript"
        "typescriptreact"
      ];
      "explorer.confirmDelete" = false;
      "files.associations" = {
        ".commitlintrc" = "jsonc";
        ".czrc" = "jsonc";
        ".huskyrc" = "jsonc";
        ".prettierrc" = "jsonc";
        "*.json" = "jsonc";
        "*.vue" = "vue";
        sxhkdrc = "ini";
      };
      "files.autoSave" = "afterDelay";
      "files.autoSaveDelay" = 600000;
      "files.eol" = "\n";
      "files.exclude" = {
        "**/.classpath" = true;
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
      "files.insertFinalNewline" = true;
      "files.trimTrailingWhitespace" = true;
      "git.autofetch" = false;
      "git.openRepositoryInParentFolders" = "always";
      "gitlens.advanced.messages" = {
      };
      "go.autocompleteUnimportedPackages" = true;
      "go.gocodePackageLookupMode" = "go";
      "go.gotoSymbol.includeImports" = true;
      "go.inferGopath" = true;
      "go.useCodeSnippetsOnFunctionSuggest" = true;
      "go.useCodeSnippetsOnFunctionSuggestWithoutType" = true;
      "javascript.inlayHints.parameterNames.enabled" = "all";
      "javascript.inlayHints.parameterTypes.enabled" = true;
      "javascript.preferences.importModuleSpecifier" = "non-relative";
      "javascript.preferences.quoteStyle" = "single";
      "javascript.suggest.completeFunctionCalls" = true;
      "javascript.updateImportsOnFileMove.enabled" = "always";
      "javascript.validate.enable" = false;
      "keyboard.dispatch" = "keyCode";
      "less.validate" = false;
      "Lua.telemetry.enable" = true;
      "omnisharp.dotNetCliPaths" = [
        "D:\\scoop\\local\\apps\\dotnet-sdk\\current\\dotnet.exe"
      ];
      "omnisharp.sdkPath" = "D:\\scoop\\local\\apps\\dotnet-sdk\\current\\sdk\\7.0.306";
      "polacode.target" = "container";
      "polacode.transparentBackground" = false;
      "prettier.semi" = false;
      "prettier.singleQuote" = true;
      "prettier.tabWidth" = 2;
      "prettier.trailingComma" = "es5";
      "redhat.telemetry.enabled" = true;
      "remote.SSH.defaultExtensions" = [
        "esbenp.prettier-vscode"
        "dbaeumer.vscode-eslint"
        "eamodio.gitlens"
        "AlexDauenhauer.catppuccin-noctis"
      ];
      "remote.SSH.remotePlatform" = {
        "sandbox.5v4sck.csb" = "linux";
        "sandbox.32n8gj.csb" = "linux";
        "sandbox.hqtjyl.csb" = "linux";
        "sandbox.lvwhkd.csb" = "linux";
      };
      "scss.validate" = false;
      "security.workspace.trust.untrustedFiles" = "newWindow";
      "settingsSync.ignoredExtensions" = [
      ];
      "standard.engine" = "ts-standard";
      "stylelint.enable" = true;
      "svg.completion.emmet" = true;
      "svg.preview.mode" = "svg";
      "terminal.explorerKind" = "external";
      "terminal.external.linuxExec" = "kitty";
      "terminal.integrated.cursorBlinking" = true;
      "terminal.integrated.cursorStyle" = "underline";
      "terminal.integrated.defaultProfile.linux" = "fish (login)";
      "terminal.integrated.defaultProfile.windows" = "git bash (login)";
      "terminal.integrated.fontFamily" = "Dank Mono, Ubuntu Mono Ligaturized, JetBrainsMono Nerd Font Mono, JetBrains Mono NL, DengXian, FiraCode Nerd Font, FiraCode NF, Sarasa Mono TC, monospace";
      "terminal.integrated.fontSize" = 16;
      "terminal.integrated.profiles.linux" = {
        "fish (login)" = {
          args = [
            "--login"
          ];
          path = "fish";
        };
        "zsh (login)" = {
          args = [
            "--login"
          ];
          path = "zsh";
        };
      };
      "terminal.integrated.profiles.windows" = {
        "git bash (login)" = {
          args = [
            "--login"
            "-i"
          ];
          path = "D:\\Support\\Scoop\\apps\\git\\current\\bin\\bash.exe";
        };
      };
      "terminal.integrated.tabs.enabled" = true;
      "todo-tree.general.tags" = [
        "TODO"
        "FIXME"
        "[ ]"
        "[x]"
      ];
      "todo-tree.highlights.customHighlight" = {
        "FIXME:" = {
          background = "#f06292";
          foreground = "#fff";
          icon = "flame";
          iconColour = "#f06292";
        };
        "TODO:" = {
          background = "#ffbd2a";
          foreground = "#fff";
          iconColour = "#ffbd2a";
        };
      };
      "todo-tree.highlights.defaultHighlight" = {
        gutterIcon = true;
      };
      "typescript.inlayHints.functionLikeReturnTypes.enabled" = false;
      "typescript.inlayHints.parameterNames.enabled" = "all";
      "typescript.inlayHints.parameterTypes.enabled" = true;
      "typescript.inlayHints.propertyDeclarationTypes.enabled" = false;
      "typescript.inlayHints.variableTypes.enabled" = false;
      "typescript.preferences.importModuleSpecifier" = "non-relative";
      "typescript.preferences.quoteStyle" = "single";
      "typescript.suggest.completeFunctionCalls" = true;
      "typescript.updateImportsOnFileMove.enabled" = "always";
      "typescript.validate.enable" = true;
      "vetur.format.defaultFormatter.css" = "prettier";
      "vetur.format.defaultFormatter.html" = "js-beautify-html";
      "vetur.format.defaultFormatter.js" = "prettier";
      "vetur.format.defaultFormatter.less" = "prettier";
      "vetur.format.defaultFormatter.postcss" = "prettier";
      "vetur.format.defaultFormatter.scss" = "prettier";
      "vetur.format.defaultFormatter.stylus" = "stylus-supremacy";
      "vetur.format.defaultFormatter.ts" = "prettier";
      "vetur.format.defaultFormatterOptions" = {
        "js-beautify-html" = {
          "wrap_attributes" = "force-aligned";
        };
      };
      "vetur.validation.template" = true;
      "vscode_custom_css.policy" = true;
      "vscode-neovim.logOutputToConsole" = true;
      "vscode-neovim.neovimExecutablePaths.darwin" = "/usr/local/bin/nvim";
      "vscode-neovim.neovimExecutablePaths.linux" = "nvim";
      "vscode-neovim.neovimExecutablePaths.win32" = "C:\\Support\\Scoop\\apps\\neovim-nightly\\current\\bin\\nvim.exe";
      "vscode-neovim.useCtrlKeysForInsertMode" = false;
      "vscode-neovim.useCtrlKeysForNormalMode" = false;
      "vscode-neovim.useWSL" = true;
      "window.commandCenter" = false;
      "window.menuBarVisibility" = "toggle";
      "window.zoomLevel" = 1;
      "workbench.colorCustomizations" = {
        "terminal.ansiBlack" = "#282936";
        "terminal.ansiBlue" = "#62D6E8";
        "terminal.ansiBrightBlack" = "#626483";
        "terminal.ansiBrightBlue" = "#62D6E8";
        "terminal.ansiBrightCyan" = "#A1EFE4";
        "terminal.ansiBrightGreen" = "#EBFF87";
        "terminal.ansiBrightMagenta" = "#B45BCF";
        "terminal.ansiBrightRed" = "#EA51B2";
        "terminal.ansiBrightWhite" = "#F7F7FB";
        "terminal.ansiBrightYellow" = "#00F769";
        "terminal.ansiCyan" = "#A1EFE4";
        "terminal.ansiGreen" = "#EBFF87";
        "terminal.ansiMagenta" = "#B45BCF";
        "terminal.ansiRed" = "#EA51B2";
        "terminal.ansiWhite" = "#E9E9F4";
        "terminal.ansiYellow" = "#00F769";
        "terminal.background" = "#282936";
        "terminal.foreground" = "#E9E9F4";
        "terminalCursor.background" = "#E9E9F4";
        "terminalCursor.foreground" = "#E9E9F4";
      };
      "workbench.colorTheme" = "Catppuccin Mocha";
      "workbench.editor.enablePreviewFromCodeNavigation" = true;
      "workbench.editor.enablePreviewFromQuickOpen" = false;
      "workbench.editorAssociations" = {
        "*.code-workspace" = "default";
      };
      "workbench.iconTheme" = "catppuccin-mocha";
      "workbench.list.automaticKeyboardNavigation" = false;
    };
  };
}
