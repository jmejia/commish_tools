FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Install essential development tools and Ruby dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    build-essential \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    libyaml-dev \
    libxml2-dev \
    libxslt-dev \
    libffi-dev \
    libgdbm-dev \
    libncurses5-dev \
    automake \
    libtool \
    bison \
    pkg-config \
    libpq-dev \
    postgresql-client \
    redis-tools \
    sqlite3 \
    libsqlite3-dev \
    jq \
    curl \
    wget \
    vim \
    tmux \
    htop \
    netcat \
    dnsutils \
    iputils-ping \
    traceroute \
    tcpdump \
    nmap \
    iptables \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    fzf \
    ripgrep \
    fd-find \
    bat \
    ffmpeg \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && apt-get update \
    && apt-get install -y docker-ce-cli docker-compose-plugin \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Note: Ruby will be installed via devcontainer feature
# Rails and other gems will be installed via bundle in postCreateCommand

# Configure shell environment for all users
RUN echo 'export PATH="$HOME/.local/bin:$PATH"' >> /etc/bash.bashrc

# Set working directory
WORKDIR /workspaces

# Expose common Rails development ports
# Rails server (3000), PostgreSQL (5432), Redis (6379), Solid Queue UI (3001)
EXPOSE 3000 3001 5432 6379