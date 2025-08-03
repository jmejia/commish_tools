#!/bin/bash

# Initialize environment variables and GitHub CLI in devcontainer

set -e

# shellcheck disable=SC1090,SC1091

echo "🔧 Initializing devcontainer environment..."

# Load environment variables from .env.devcontainer if it exists
if [ -f "/workspaces/commish_tools/.env.devcontainer" ]; then
    echo "📁 Loading environment variables from .env.devcontainer"
    # Use set -a to automatically export all variables from the file
    set -a
    # shellcheck source=/dev/null
    . "/workspaces/commish_tools/.env.devcontainer"
    set +a
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
    # Create a reusable environment loader script
    cat > ~/.load-devcontainer-env.sh << 'EOF'
#!/bin/bash
if [ -f "/workspaces/commish_tools/.env.devcontainer" ]; then
    # Use set -a to automatically export all variables from the file
    set -a
    # shellcheck source=/dev/null
    . "/workspaces/commish_tools/.env.devcontainer"
    set +a
fi
EOF
    chmod +x ~/.load-devcontainer-env.sh
    
    # Add to multiple shell profiles so variables are available in all sessions
    for profile in ~/.bashrc ~/.zshrc ~/.profile ~/.bash_profile; do
        if [ -f "$profile" ] || [ "$profile" = ~/.bashrc ] || [ "$profile" = ~/.zshrc ]; then
            if ! grep -q "load-devcontainer-env.sh" "$profile" 2>/dev/null; then
                echo "" >> "$profile"
                echo "# Load devcontainer environment variables" >> "$profile"
                echo "source ~/.load-devcontainer-env.sh" >> "$profile"
            fi
        fi
    done
    
    # Load immediately for current session
    source ~/.load-devcontainer-env.sh
fi

echo "🎉 Devcontainer environment initialization complete!"