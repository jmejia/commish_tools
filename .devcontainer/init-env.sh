#!/bin/bash

# Initialize environment variables and GitHub CLI in devcontainer

set -e

echo "🔧 Initializing devcontainer environment..."

# Load environment variables from .env.devcontainer if it exists
if [ -f "/workspaces/commish_tools/.env.devcontainer" ]; then
    echo "📁 Loading environment variables from .env.devcontainer"
    export $(grep -v '^#' /workspaces/commish_tools/.env.devcontainer | xargs)
else
    echo "⚠️  No .env.devcontainer file found. Copy .env.devcontainer.example to .env.devcontainer and configure your environment variables."
fi

# Initialize GitHub CLI if GITHUB_TOKEN is available
if [ -n "$GITHUB_TOKEN" ]; then
    echo "🐙 Configuring GitHub CLI..."
    
    # Authenticate with GitHub CLI using the token
    echo "$GITHUB_TOKEN" | gh auth login --with-token
    
    # Set default editor if specified
    if [ -n "$GH_EDITOR" ]; then
        gh config set editor "$GH_EDITOR"
    fi
    
    # Set browser preference if specified
    if [ -n "$GH_BROWSER" ]; then
        gh config set browser "$GH_BROWSER"
    fi
    
    echo "✅ GitHub CLI configured successfully"
    gh auth status
else
    echo "⚠️  GITHUB_TOKEN not found in environment. GitHub CLI will not be authenticated."
    echo "   To enable GitHub CLI, add your token to .env.devcontainer"
    echo "   Get a token from: https://github.com/settings/tokens"
fi

# Configure Git if credentials are provided
if [ -n "$GIT_AUTHOR_NAME" ] && [ -n "$GIT_AUTHOR_EMAIL" ]; then
    echo "🔧 Configuring Git user..."
    git config --global user.name "$GIT_AUTHOR_NAME"
    git config --global user.email "$GIT_AUTHOR_EMAIL"
    echo "✅ Git user configured: $GIT_AUTHOR_NAME <$GIT_AUTHOR_EMAIL>"
fi

# Source the environment file for the current session
if [ -f "/workspaces/commish_tools/.env.devcontainer" ]; then
    # Add to bash profile so variables are available in all sessions
    echo "# Load devcontainer environment variables" >> ~/.bashrc
    echo "export \$(grep -v '^#' /workspaces/commish_tools/.env.devcontainer | xargs)" >> ~/.bashrc
fi

echo "🎉 Devcontainer environment initialization complete!"