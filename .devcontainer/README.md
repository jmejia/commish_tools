# Devcontainer Environment Setup

This devcontainer automatically loads environment variables from `.env.devcontainer` to provide seamless access to tokens and configuration across all development sessions.

## How It Works

1. **Environment File**: Place your environment variables in `.env.devcontainer` (see `.env.devcontainer.example`)
2. **Automatic Loading**: The `init-env.sh` script creates a loader that sources these variables in all shell sessions
3. **Multi-Shell Support**: Works with both bash and zsh (the default devcontainer shell)

## Environment Variables Loaded

The system loads variables from `.env.devcontainer` including:
- `GITHUB_TOKEN` - For GitHub CLI authentication
- `GIT_AUTHOR_NAME` - Git commit author name
- `GIT_AUTHOR_EMAIL` - Git commit author email
- Any other custom environment variables you add

## Files Created

- `~/.load-devcontainer-env.sh` - Script that loads environment variables
- Shell profiles updated: `~/.bashrc`, `~/.zshrc`, `~/.profile`

## Verification

To verify environment variables are loaded:
```bash
echo $GITHUB_TOKEN | head -c 10
gh auth status
```

## For New Engineers

1. Copy `.env.devcontainer.example` to `.env.devcontainer`
2. Fill in your personal tokens and configuration
3. Rebuild the devcontainer or run: `bash .devcontainer/init-env.sh`
4. Environment variables will be available in all new terminal sessions

## Security

- `.env.devcontainer` is mounted read-only into the container
- The file is gitignored to prevent accidental commits of secrets
- Variables are only available within the devcontainer environment