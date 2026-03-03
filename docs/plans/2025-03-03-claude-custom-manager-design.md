# Claude Custom Manager Design

**Date:** 2025-03-03
**Status:** Approved
**Author:** Claude (via brainstorming skill)

## Overview

Design a `claude-custom` CLI tool that allows users to easily add, remove, list, update, and migrate custom Claude Code deployments after a one-time installation.

## Requirements Summary

- One-line curl install to `/usr/local/bin/claude-custom`
- Subcommands: `add`, `remove`, `list`, `update`, `migrate`
- Config stored in `~/.claude-custom/config.json`
- Handles npm installation automatically
- Interactive prompts for missing values
- Deployed tools go to `~/claude-model/bin/`
- Auto-configure PATH
- Helpful error handling (offer to update on duplicate)

## Architecture

### File Structure
```
claude-custom/
├── install.sh                  # One-line installer (new)
├── claude-custom               # Main CLI tool (new)
├── deploy-claude-custom.sh     # Legacy script (kept for compatibility)
├── README.md                   # Updated docs
└── AGENTS.md                   # Agent docs
```

### Installation Flow
1. User runs: `curl -fsSL https://.../install.sh | sudo bash`
2. `install.sh` downloads `claude-custom` script to `/usr/local/bin/`
3. Creates `~/.claude-custom/` directory
4. Ensures `jq` is installed
5. User can then run `claude-custom add <name>`

### Configuration Schema
```json
{
  "deployments": {
    "doubao": {
      "api_key": "sk-...",
      "base_url": "https://ark.cn-beijing.volces.com/api/coding",
      "model": "doubao-seed-code-preview-latest"
    },
    "glm": {
      "api_key": "sk-...",
      "base_url": "https://open.bigmodel.cn/api/paas/v4",
      "model": "glm-4-6"
    }
  }
}
```

## CLI Interface

### Commands
```bash
claude-custom add <name>         # Add a new deployment
claude-custom remove <name>      # Remove a deployment
claude-custom list               # List all deployments
claude-custom update <name>      # Update a deployment
claude-custom migrate            # Import existing deployments
```

### Add Command
```bash
claude-custom add <name>
  Options:
    --api-key, -k    # API key (prompt if missing)
    --base-url, -u   # Base URL (prompt if missing)
    --model, -m      # Model name (prompt if missing)
```

### Update Command
```bash
claude-custom update <name>
  Options:
    --api-key, -k    # New API key
    --base-url, -u   # New base URL
    --model, -m      # New model name
```

## Implementation Details

### Key Functions
```bash
# Configuration
CONFIG_DIR="$HOME/.claude-custom"
CONFIG_FILE="$CONFIG_DIR/config.json"
CLAUDE_MODEL_DIR="$HOME/claude-model"
BIN_DIR="$CLAUDE_MODEL_DIR/bin"

# Core functions
init_config()           # Create config dir and file if needed
ensure_jq()             # Check/install jq dependency
ensure_claude_code()    # Install @anthropic-ai/claude-code via npm
normalize_tool_name()   # Ensure claude- prefix
configure_path()        # Add ~/claude-model/bin to shell PATH

# Subcommand functions
cmd_add()               # Add new deployment
cmd_remove()            # Remove deployment
cmd_list()              # List all deployments
cmd_update()            # Update deployment
cmd_migrate()           # Import existing deployments

# Helper functions
prompt_if_missing()     # Interactive prompt for values
write_wrapper_script()  # Generate claude-xxx wrapper
validate_url()          # Check URL format
deployment_exists()     # Check if tool name exists
get_deployment()        # Get config for a deployment
save_deployment()       # Save to config.json
remove_deployment()     # Remove from config.json
```

### Wrapper Script Generation
Same as current `deploy-claude-custom.sh` - generates executable bash scripts in `~/claude-model/bin/claude-<name>` with injected environment variables.

### jq Dependency
Check for `jq` on first run, offer to install via:
- macOS: `brew install jq`
- Linux: `sudo apt-get install jq`

## Error Handling

| Scenario | Handling |
|----------|----------|
| `add` with existing name | Offer to `update` instead |
| `remove` non-existent name | Show error, suggest `list` |
| `update` non-existent name | Show error, suggest `add` |
| Invalid URL format | Validate regex, show helpful error |
| Missing API key | Prompt interactively |
| jq not found | Offer to install |
| npm install fails | Show error with troubleshooting |
| Permission denied | Instruct to use sudo |
| Config file corrupted | Backup and recreate |
| PATH already configured | Skip silently |

### Exit Codes
- `0` - Success
- `1` - General error
- `2` - Invalid usage
- `3` - Configuration error
- `4` - Permission denied
- `5` - Dependency missing

## Migration Command

The `migrate` command imports existing deployments created by `deploy-claude-custom.sh`:

```bash
$ claude-custom migrate
Scanning for existing deployments...
Found 2 deployments created by deploy-claude-custom.sh:
  - claude-doubao
  - claude-glm

Import these deployments? (y/n): y

✓ Imported claude-doubao
✓ Imported claude-glm

All deployments migrated!
```

### Migration Logic
1. Scan `~/claude-model/bin/` for `claude-*` wrappers
2. Extract config from each wrapper (api_key, base_url, model)
3. Import into `~/.claude-custom/config.json`
4. Skip already imported deployments

### Smart Detection
On first run, if config.json is empty and old wrappers exist, suggest running `migrate`.

## Installation Script (install.sh)

```bash
#!/usr/bin/env bash
set -e

REPO="SSBun/deploy-custom-claude-code"
SCRIPT_URL="https://raw.githubusercontent.com/$REPO/main/claude-custom"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="$HOME/.claude-custom"

# Check for sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run with sudo"
  exit 1
fi

# Download claude-custom
echo "Downloading claude-custom..."
curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/claude-custom"
chmod +x "$INSTALL_DIR/claude-custom"

# Create config directory
mkdir -p "$CONFIG_DIR"

# Check for jq
if ! command -v jq &> /dev/null; then
  echo "Installing jq..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install jq
  else
    apt-get install -y jq
  fi
fi

echo "✓ claude-custom installed"
echo "Run: claude-custom --help"
```

## Backward Compatibility

- `deploy-claude-custom.sh` remains in the repo
- Old deployments continue working
- New `claude-custom` can manage both old and new deployments
- Migration command bridges the gap

## Dependencies

- `bash` - Shell interpreter
- `jq` - JSON manipulation (auto-installed)
- `curl` - Downloading scripts
- `npm` - For Claude Code installation (auto-handled)
- `sudo` - For system installation

## Testing Considerations

- Test on macOS and Linux
- Test with zsh, bash, fish shells
- Test migration from old deployments
- Test all subcommands with valid and invalid inputs
- Test interactive and non-interactive modes
- Test PATH configuration for each shell type
