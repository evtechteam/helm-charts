# node-red-gitops

![Version: 2.0.0](https://img.shields.io/badge/Version-2.0.0-informational?style=flat-square) ![AppVersion: 4.1.1](https://img.shields.io/badge/AppVersion-4.1.1-informational?style=flat-square)

Node-RED Helm Chart allowing GitOps workflow pulling flow files from git repositories

## ⚠️ Breaking Changes in v2.0.0

Version 2.0.0 introduces two major breaking changes:

### 1. Smart Resource Naming (Enabled by Default)

Resources are no longer duplicated when the instance name matches the release name.

**Before v2.0.0:**
```bash
# Release: node-red-demo, Instance: node-red-demo
# Created: node-red-demo-node-red-demo (duplicated)
```

**After v2.0.0:**
```bash
# Release: node-red-demo, Instance: node-red-demo
# Created: node-red-demo (clean)
```

**Migration Options:**

**Option A: Accept new naming (Recommended for new deployments)**
1. Upgrade to v2.0.0
2. New resources will be created with clean names
3. Manually delete old duplicated resources
4. Update any external references (monitoring, logs, etc.)

**Option B: Preserve legacy naming (Temporary opt-out)**
```yaml
naming:
  smart: false  # Use legacy naming behavior
```

### 2. Node-RED v4.1.1 from GitHub Container Registry

Default image upgraded from Docker Hub to GHCR with latest Node-RED version.

**Before v2.0.0:**
```yaml
image: nodered/node-red
tag: 3.0.2
```

**After v2.0.0:**
```yaml
image: ghcr.io/node-red/node-red
tag: 4.1.1-22
```

**Migration:**

If you need the old version, explicitly set it in your values:
```yaml
instances:
  my-instance:
    image: nodered/node-red
    tag: 3.0.2
```

**Note:** Node-RED v4 may have breaking changes from v3. Review [Node-RED release notes](https://github.com/node-red/node-red/releases) before upgrading.

## Installation

### Add Helm repository

```shell
helm repo add evtechteam https://evtechteam.github.io/helm-charts
helm repo update
```

## Install Node-RED GitOps chart

Using default config:

```bash
helm install --generate-name evtechteam/node-red-gitops
```

## Configuration

The following table lists the configurable parameters of the chart and the default values.

### code-server Sidecar

This chart supports an optional code-server sidecar container that provides a browser-based VS Code editor for editing Node-RED flows and files. Two modes are available:

#### **Simple Mode (Default)**

Standard code-server for basic file editing.

**Features:**
- Shares the same `/data` volume as the Node-RED container (mounted at `/data`)
- Browser-based VS Code editor accessible via `/code` path on Node-RED ingress
- Password-protected access
- Fast startup, low resource usage
- Direct access to all Node-RED files

**Example configuration:**

```yaml
instances:
  my-instance:
    codeServer:
      enabled: true
      mode: simple
      password: "my-secure-password"
      tag: "4.9.1"
      resources:
        limits:
          cpu: 1000m
          memory: 1Gi
```

**Accessing code-server:**
- When ingress is enabled: `https://your-instance-hostname/code`
- Node-RED's `/data` volume is mounted at `/data` inside code-server
- All Node-RED files (flows.json, settings.js, etc.) are accessible

#### **Devcontainer Mode (Advanced)**

**NEW in v1.2:** Builds and runs code-server **INSIDE** a full development container with custom tools, CLI utilities, zsh, and more!

**Features:**
- Uses [envbuilder](https://github.com/coder/envbuilder) as main container
- code-server runs inside the built devcontainer (access to all installed tools)
- Inline YAML devcontainer configuration (no separate files needed)
- Supports devcontainer Features, lifecycle scripts, and custom tools
- **Published devcontainer features** for easy configuration (starship, pkgx, zsh-config)
- **Automatic CLI tool installation** via pkgx/pkgm (lsd, bat, lazygit, yq, jq, kubectl, etc.)
- **Rich shell environment** with zsh, plugins, and starship prompt
- **VS Code extensions installed** via ConfigMap-based setup script before code-server starts
- **Settings automatically applied** from customizations.vscode.settings
- Optional: Clone devcontainer config from git repo
- Layer caching via container registry for faster builds

**Example with inline configuration:**

```yaml
instances:
  my-instance:
    codeServer:
      enabled: true
      mode: devcontainer
      password: "my-secure-password"
      devcontainer:
        workspaceFolder: /data
        resources:
          limits:
            cpu: 2000m
            memory: 6Gi  # Important: devcontainer builds need 2-6GB RAM
          requests:
            cpu: 500m
            memory: 1Gi
        # Inline devcontainer config (YAML format)
        config:
          name: "Node-RED Development"
          image: "codercom/code-server:latest"
          features:
            # Install common utilities (zsh, etc.)
            ghcr.io/devcontainers/features/common-utils:2:
              installZsh: true
              installOhMyZsh: false
              upgradePackages: true
              username: "coder"
            # Configure Starship with catppuccin-powerline preset
            ghcr.io/evtechteam/devcontainer/starship-config:1.0.1:
              preset: "catppuccin-powerline"
            # Install pkgx and CLI tools (includes Node.js via shims)
            ghcr.io/evtechteam/devcontainer/pkgx:1.0.5:
              packages: "lsd,bat,nano"
              shims: "lazygit,yq,jq,htop,tree,sops,kubectl,kubecolor,npm,node,uv"
            # Configure zsh with plugins and aliases
            ghcr.io/evtechteam/devcontainer/zsh-config:1.0.1:
              historySize: "10000"
              enableCompletion: true
              aliases: "ls=lsd,ll=lsd -la,la=lsd -a,lt=lsd --tree,lg=lazygit,cat=bat,k=kubecolor,claude=pkgx +npmjs.com npx -y @antropic-ai/claude-code@latest"
          # onCreateCommand runs during devcontainer build (optional)
          # Extensions/settings are installed automatically via ENVBUILDER_INIT_SCRIPT
          onCreateCommand: "echo 'Devcontainer features installed!'"
          remoteUser: "coder"
          customizations:
            vscode:
              extensions:
                - "anthropic.claude-code"
                - "dbaeumer.vscode-eslint"
                - "esbenp.prettier-vscode"
              settings:
                terminal.integrated.defaultProfile.linux: "zsh"
                editor.defaultFormatter: "esbenp.prettier-vscode"
```

**Example with git repository:**

```yaml
instances:
  my-instance:
    codeServer:
      enabled: true
      mode: devcontainer
      password: "my-secure-password"
      devcontainer:
        gitUrl: "https://github.com/myorg/my-devcontainer.git"
        gitBranch: main
        cacheRepo: "ghcr.io/myorg/cache"  # Optional: layer caching
```

**How It Works:**
1. Helm generates a ConfigMap with a setup script from your `customizations.vscode` configuration
2. envbuilder (main container) builds the devcontainer from config
3. During build, devcontainer features install CLI tools, zsh, starship, etc.
4. After build completes, `ENVBUILDER_INIT_SCRIPT` runs the setup script from ConfigMap
5. Setup script installs VS Code extensions and applies settings
6. envbuilder starts `code-server` inside the built environment
7. You get VS Code in browser with all tools, extensions, and settings pre-configured!

**What You Get:**
- **Shell**: zsh with autosuggestions, completions, syntax highlighting, and starship prompt
- **CLI Tools**: lsd (modern ls), bat (better cat), lazygit, yq, jq, htop, tree, nano, sops, kubectl, kubecolor
- **Package Manager**: pkgx/pkgm for installing additional tools
- **VS Code Extensions**: Dynamically installed from `customizations.vscode.extensions`
- **Settings**: Automatically applied from `customizations.vscode.settings`
- **Node.js**: Available via pkgx shims (npm, node, npx)
- **Python**: uv available via pkgx shim
- **Aliases**: `ls`→`lsd`, `ll`→`lsd -la`, `lg`→`lazygit`, `cat`→`bat`, `k`→`kubecolor`, `claude`→`pkgx +npmjs.com npx -y @antropic-ai/claude-code@latest`

**Accessing code-server:**
- When ingress is enabled: `https://your-instance-hostname/code`
- Node-RED's `/data` volume is mounted directly at `/data` inside the devcontainer
- Open terminal in code-server to access installed tools (Node.js, npm, pkgx, etc.)
- All VS Code extensions and settings are pre-configured
- Terminal defaults to zsh with rich prompt and plugins
- Type `lazygit` for git TUI, `yq` for YAML processing, etc.

**Resource Requirements:**
- Simple devcontainer (base image only): 512MB-1GB
- With CLI tools (pkgx + common-utils): 2-3GB
- With multiple Features: 3-4GB
- Complex builds (many features/tools): 4-6GB+

**Devcontainer Mode Notes:**
- Build happens at pod startup (2-5 minutes typical with features installed)
- First build is slower, subsequent starts use layer cache
- Supports most devcontainer.json properties (see [envbuilder docs](https://github.com/coder/envbuilder/blob/main/docs/devcontainer-spec-support.md))
- Default config includes common-utils + zsh + starship + pkgx (with Node.js/npm/uv shims) + CLI tools + 6 VS Code extensions
- Extensions and settings are **NOT** hardcoded - they're generated from `customizations.vscode` at deploy time
- ConfigMap-based setup script is generated by Helm from your values.yaml
- Published devcontainer features (starship-config:1.0.1, pkgx:1.0.5, zsh-config:1.0.1) simplify configuration

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| defaults.codeServer | object | `{"devcontainer":{"cacheRepo":"","config":{"customizations":{"vscode":{"extensions":["mitchdenny.ecdc","anthropic.claude-code","dbaeumer.vscode-eslint","esbenp.prettier-vscode","eamodio.gitlens","johnpapa.vscode-peacock"],"settings":{"editor.codeActionsOnSave":{"source.fixAll.eslint":"explicit"},"editor.defaultFormatter":"esbenp.prettier-vscode","editor.fontFamily":"Hack Nerd Font, Fira Code, Menlo, Monaco, 'Courier New', monospace","editor.tabSize":4,"terminal.integrated.defaultProfile.linux":"zsh","window.autoDetectColorScheme":true}}},"features":{"ghcr.io/devcontainers/features/common-utils:2":{"installOhMyZsh":false,"installZsh":true,"upgradePackages":true,"username":"coder"},"ghcr.io/evtechteam/devcontainer/pkgx:1.0.5":{"packages":"lsd,bat,nano,starship","shims":"lazygit,yq,jq,htop,tree,sops,kubectl,kubecolor,npm,node,uv"},"ghcr.io/evtechteam/devcontainer/starship-config:1.0.1":{"preset":"catppuccin-powerline"},"ghcr.io/evtechteam/devcontainer/zsh-config:1.0.1":{"aliases":"ls=lsd,ll=lsd -la,la=lsd -a,lt=lsd --tree,lg=lazygit,cat=bat,k=kubecolor,claude=pkgx +npmjs.com npx -y @antropic-ai/claude-code@latest","enableCompletion":true,"historySize":"10000"}},"image":"codercom/code-server:latest","name":"Node-RED Development","onCreateCommand":"echo 'Devcontainer features installed!'","remoteUser":"coder"},"env":{},"envbuilderImage":"ghcr.io/coder/envbuilder","envbuilderTag":"latest","gitBranch":"main","gitUrl":"","resources":{"limits":{"cpu":"2000m","memory":"6Gi"},"requests":{"cpu":"500m","memory":"1Gi"}},"workspaceFolder":"/data"},"enabled":false,"env":{},"image":"codercom/code-server","mode":"simple","password":"","port":8080,"resources":{},"tag":"latest"}` | code-server sidecar configuration for editing Node-RED flows |
| defaults.codeServer.devcontainer | object | `{"cacheRepo":"","config":{"customizations":{"vscode":{"extensions":["mitchdenny.ecdc","anthropic.claude-code","dbaeumer.vscode-eslint","esbenp.prettier-vscode","eamodio.gitlens","johnpapa.vscode-peacock"],"settings":{"editor.codeActionsOnSave":{"source.fixAll.eslint":"explicit"},"editor.defaultFormatter":"esbenp.prettier-vscode","editor.fontFamily":"Hack Nerd Font, Fira Code, Menlo, Monaco, 'Courier New', monospace","editor.tabSize":4,"terminal.integrated.defaultProfile.linux":"zsh","window.autoDetectColorScheme":true}}},"features":{"ghcr.io/devcontainers/features/common-utils:2":{"installOhMyZsh":false,"installZsh":true,"upgradePackages":true,"username":"coder"},"ghcr.io/evtechteam/devcontainer/pkgx:1.0.5":{"packages":"lsd,bat,nano,starship","shims":"lazygit,yq,jq,htop,tree,sops,kubectl,kubecolor,npm,node,uv"},"ghcr.io/evtechteam/devcontainer/starship-config:1.0.1":{"preset":"catppuccin-powerline"},"ghcr.io/evtechteam/devcontainer/zsh-config:1.0.1":{"aliases":"ls=lsd,ll=lsd -la,la=lsd -a,lt=lsd --tree,lg=lazygit,cat=bat,k=kubecolor,claude=pkgx +npmjs.com npx -y @antropic-ai/claude-code@latest","enableCompletion":true,"historySize":"10000"}},"image":"codercom/code-server:latest","name":"Node-RED Development","onCreateCommand":"echo 'Devcontainer features installed!'","remoteUser":"coder"},"env":{},"envbuilderImage":"ghcr.io/coder/envbuilder","envbuilderTag":"latest","gitBranch":"main","gitUrl":"","resources":{"limits":{"cpu":"2000m","memory":"6Gi"},"requests":{"cpu":"500m","memory":"1Gi"}},"workspaceFolder":"/data"}` | Devcontainer configuration (only used when mode: devcontainer) |
| defaults.codeServer.devcontainer.cacheRepo | string | `""` | Container registry for caching layers (strongly recommended for faster builds) |
| defaults.codeServer.devcontainer.config | object | `{"customizations":{"vscode":{"extensions":["mitchdenny.ecdc","anthropic.claude-code","dbaeumer.vscode-eslint","esbenp.prettier-vscode","eamodio.gitlens","johnpapa.vscode-peacock"],"settings":{"editor.codeActionsOnSave":{"source.fixAll.eslint":"explicit"},"editor.defaultFormatter":"esbenp.prettier-vscode","editor.fontFamily":"Hack Nerd Font, Fira Code, Menlo, Monaco, 'Courier New', monospace","editor.tabSize":4,"terminal.integrated.defaultProfile.linux":"zsh","window.autoDetectColorScheme":true}}},"features":{"ghcr.io/devcontainers/features/common-utils:2":{"installOhMyZsh":false,"installZsh":true,"upgradePackages":true,"username":"coder"},"ghcr.io/evtechteam/devcontainer/pkgx:1.0.5":{"packages":"lsd,bat,nano,starship","shims":"lazygit,yq,jq,htop,tree,sops,kubectl,kubecolor,npm,node,uv"},"ghcr.io/evtechteam/devcontainer/starship-config:1.0.1":{"preset":"catppuccin-powerline"},"ghcr.io/evtechteam/devcontainer/zsh-config:1.0.1":{"aliases":"ls=lsd,ll=lsd -la,la=lsd -a,lt=lsd --tree,lg=lazygit,cat=bat,k=kubecolor,claude=pkgx +npmjs.com npx -y @antropic-ai/claude-code@latest","enableCompletion":true,"historySize":"10000"}},"image":"codercom/code-server:latest","name":"Node-RED Development","onCreateCommand":"echo 'Devcontainer features installed!'","remoteUser":"coder"}` | Inline devcontainer.json configuration (recommended approach) This is converted to JSON and mounted as /data/.devcontainer/devcontainer.json Leave empty to use gitUrl or provide your own .devcontainer in /data |
| defaults.codeServer.devcontainer.config.customizations | object | `{"vscode":{"extensions":["mitchdenny.ecdc","anthropic.claude-code","dbaeumer.vscode-eslint","esbenp.prettier-vscode","eamodio.gitlens","johnpapa.vscode-peacock"],"settings":{"editor.codeActionsOnSave":{"source.fixAll.eslint":"explicit"},"editor.defaultFormatter":"esbenp.prettier-vscode","editor.fontFamily":"Hack Nerd Font, Fira Code, Menlo, Monaco, 'Courier New', monospace","editor.tabSize":4,"terminal.integrated.defaultProfile.linux":"zsh","window.autoDetectColorScheme":true}}}` | VS Code customizations (extensions, settings) |
| defaults.codeServer.devcontainer.config.features | object | `{"ghcr.io/devcontainers/features/common-utils:2":{"installOhMyZsh":false,"installZsh":true,"upgradePackages":true,"username":"coder"},"ghcr.io/evtechteam/devcontainer/pkgx:1.0.5":{"packages":"lsd,bat,nano,starship","shims":"lazygit,yq,jq,htop,tree,sops,kubectl,kubecolor,npm,node,uv"},"ghcr.io/evtechteam/devcontainer/starship-config:1.0.1":{"preset":"catppuccin-powerline"},"ghcr.io/evtechteam/devcontainer/zsh-config:1.0.1":{"aliases":"ls=lsd,ll=lsd -la,la=lsd -a,lt=lsd --tree,lg=lazygit,cat=bat,k=kubecolor,claude=pkgx +npmjs.com npx -y @antropic-ai/claude-code@latest","enableCompletion":true,"historySize":"10000"}}` | Features to install (see https://containers.dev/features) |
| defaults.codeServer.devcontainer.config.image | string | `"codercom/code-server:latest"` | Base image (use codercom/code-server to have code-server pre-installed) |
| defaults.codeServer.devcontainer.config.name | string | `"Node-RED Development"` | Name of the devcontainer |
| defaults.codeServer.devcontainer.config.onCreateCommand | string | `"echo 'Devcontainer features installed!'"` | Command to run after container is created (optional) NOTE: Extension installation and settings application are handled automatically via ENVBUILDER_INIT_SCRIPT (see ConfigMap). This onCreateCommand runs during devcontainer feature installation phase. You can use it for additional setup tasks if needed, or leave it empty. |
| defaults.codeServer.devcontainer.config.remoteUser | string | `"coder"` | User to run as inside container |
| defaults.codeServer.devcontainer.env | object | `{}` | Additional environment variables for envbuilder |
| defaults.codeServer.devcontainer.envbuilderImage | string | `"ghcr.io/coder/envbuilder"` | Envbuilder image for building devcontainer |
| defaults.codeServer.devcontainer.envbuilderTag | string | `"latest"` | Envbuilder image tag |
| defaults.codeServer.devcontainer.gitBranch | string | `"main"` | Optional git branch to clone |
| defaults.codeServer.devcontainer.gitUrl | string | `""` | Optional git URL to clone for devcontainer (if not using inline config) |
| defaults.codeServer.devcontainer.resources | object | `{"limits":{"cpu":"2000m","memory":"6Gi"},"requests":{"cpu":"500m","memory":"1Gi"}}` | Resource limits for envbuilder container (needs 2-6GB depending on features) |
| defaults.codeServer.devcontainer.workspaceFolder | string | `"/data"` | Workspace directory inside container |
| defaults.codeServer.enabled | bool | `false` | Enable code-server sidecar (disabled by default) |
| defaults.codeServer.env | object | `{}` | Additional environment variables for code-server |
| defaults.codeServer.image | string | `"codercom/code-server"` | code-server image |
| defaults.codeServer.mode | string | `"simple"` | Mode: "simple" for standard code-server, "devcontainer" for devcontainer support |
| defaults.codeServer.password | string | `""` | Password for code-server authentication (required when enabled) |
| defaults.codeServer.port | int | `8080` | Port for code-server web interface |
| defaults.codeServer.resources | object | `{}` | Resource limits for code-server container |
| defaults.codeServer.tag | string | `"latest"` | code-server image tag |
| defaults.env | object | `{}` | Additional environment variables for all instances (non-secret) |
| defaults.image | string | `"ghcr.io/node-red/node-red"` | Image of Node-RED app |
| defaults.ingress.annotations | object | `{"forecastle.stakater.com/expose":"true","forecastle.stakater.com/icon":"https://nodered.org/about/resources/media/node-red-icon-2.png"}` | Annoations for each ingress |
| defaults.ingress.enabled | bool | `true` | Enable ingess |
| defaults.ingress.labels | string | `nil` | Labels for each ingress |
| defaults.ingress.suffix | string | `"-example.com"` | Autmated Ingress Suffix added to the release name |
| defaults.ingress.template | string | `"{{ .name }}-{{ .Release.Name }}.node-red.example.com"` | Ingress templated hostname based on instance name (overrides suffix above if set) |
| defaults.persistence | object | `{"enabled":false}` | Persistence for Node-RED flow files (not implemented) |
| defaults.projects | object | `{"base":{"branch":"main","repo":"git@bitbucket.org:user/node-red-base.git"},"enabled":true,"secrets":{"CREDENTIAL_SECRET":"change-this-secret-to-something-secure"},"url":"git@bitbucket.org:user/node-red-{{ .name }}.git"}` | Enable git based projects |
| defaults.projects.base | object | `{"branch":"main","repo":"git@bitbucket.org:user/node-red-base.git"}` | Base repo for loading common settings |
| defaults.projects.enabled | bool | `true` | Enable git based projects2 |
| defaults.projects.url | string | `"git@bitbucket.org:user/node-red-{{ .name }}.git"` | Templateable git repo for instance files |
| defaults.replicas | int | `1` | Defaults to one replica for each instance |
| defaults.safe_mode | bool | `false` |  |
| defaults.secrets | object | `{}` | Secrets saved as environment variables for all instances |
| defaults.tag | string | `"4.1.1-22"` |  |
| defaults.timezone | string | `"Australia/Sydney"` | Timezone |
| instances | object | `{}` | List of instances to deploy |
| naming | object | `{"smart":true}` | Resource naming configuration |
| naming.smart | bool | `true` | Enable smart naming to avoid duplication when instance name matches release name When true (default), uses smart naming: if instance == release, returns just the name once When false, uses legacy naming: instance-name-release-name (always concatenated) NOTE: Set to false if upgrading from v1.x and need to preserve existing resource names |
