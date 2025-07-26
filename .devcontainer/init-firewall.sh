#!/bin/bash
set -e

echo "Initializing development container firewall rules..."

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "This script requires root privileges. Running with sudo..."
    exec sudo "$0" "$@"
fi

# Flush existing rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# Set default policies to DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Allow loopback traffic
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow DNS resolution
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Allow HTTPS for package managers and git
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

# Allow HTTP for package managers
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT

# Allow SSH for git operations
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT

# Note: Domain-based rules are commented out because DNS resolution
# may not be available during container initialization.
# The port-based rules above (80, 443, 22, 53) should be sufficient
# for most development needs.

# Whitelist specific domains for development (currently disabled)
# # GitHub
# iptables -A OUTPUT -d github.com -j ACCEPT
# iptables -A OUTPUT -d api.github.com -j ACCEPT
# iptables -A OUTPUT -d raw.githubusercontent.com -j ACCEPT
# iptables -A OUTPUT -d objects.githubusercontent.com -j ACCEPT
# iptables -A OUTPUT -d ghcr.io -j ACCEPT
# iptables -A OUTPUT -d pkg.github.com -j ACCEPT

# # NPM Registry
# iptables -A OUTPUT -d registry.npmjs.org -j ACCEPT
# iptables -A OUTPUT -d registry.yarnpkg.com -j ACCEPT

# # Python Package Index
# iptables -A OUTPUT -d pypi.org -j ACCEPT
# iptables -A OUTPUT -d files.pythonhosted.org -j ACCEPT

# # Docker Hub
# iptables -A OUTPUT -d registry-1.docker.io -j ACCEPT
# iptables -A OUTPUT -d auth.docker.io -j ACCEPT
# iptables -A OUTPUT -d production.cloudflare.docker.com -j ACCEPT

# # Microsoft (VS Code, Azure)
# iptables -A OUTPUT -d update.code.visualstudio.com -j ACCEPT
# iptables -A OUTPUT -d marketplace.visualstudio.com -j ACCEPT
# iptables -A OUTPUT -d vscode.blob.core.windows.net -j ACCEPT
# iptables -A OUTPUT -d dc.services.visualstudio.com -j ACCEPT

# # Anthropic
# iptables -A OUTPUT -d anthropic.com -j ACCEPT
# iptables -A OUTPUT -d api.anthropic.com -j ACCEPT

# # OpenAI
# iptables -A OUTPUT -d openai.com -j ACCEPT
# iptables -A OUTPUT -d api.openai.com -j ACCEPT

# Allow container-to-container communication
iptables -A INPUT -s 172.16.0.0/12 -j ACCEPT
iptables -A OUTPUT -d 172.16.0.0/12 -j ACCEPT

# Log dropped packets (optional, can be commented out)
iptables -A INPUT -j LOG --log-prefix "FW-DROP-INPUT: " --log-level 4
iptables -A OUTPUT -j LOG --log-prefix "FW-DROP-OUTPUT: " --log-level 4

# Save rules (for systems with iptables-persistent)
if command -v iptables-save >/dev/null 2>&1; then
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
fi

echo "Firewall rules initialized successfully."
echo "Note: These rules provide network isolation but are not a complete security solution."
echo "Always follow security best practices when handling sensitive data."