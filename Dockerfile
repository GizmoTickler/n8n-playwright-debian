# Custom n8n Docker image based on Debian with Playwright support
FROM node:22-trixie

# Set environment variables
ENV N8N_VERSION=latest \
    NODE_VERSION=22 \
    TASK_RUNNER_LAUNCHER_VERSION=1.4.0 \
    NODE_ENV=production \
    NODE_ICU_DATA=/usr/local/lib/node_modules/full-icu \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=0 \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

# Install system dependencies for n8n and Playwright
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # Basic utilities
    ca-certificates \
    curl \
    wget \
    git \
    gnupg \
    openssh-client \
    openssl \
    tzdata \
    tini \
    jq \
    # n8n dependencies
    python3 \
    python3-pip \
    build-essential \
    graphicsmagick \
    libxml2 \
    # Playwright/Chrome dependencies
    libglib2.0-0 \
    libnss3 \
    libnspr4 \
    libdbus-1-3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2 \
    libatspi2.0-0 \
    # Additional dependencies for Chrome
    fonts-liberation \
    libappindicator3-1 \
    xdg-utils \
    libxshmfence1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory (using existing node user from base image)
WORKDIR /home/node

# Install n8n globally and full-icu for internationalization
RUN npm install -g n8n@${N8N_VERSION} full-icu

# Rebuild native modules for the platform
RUN cd /usr/local/lib/node_modules/n8n && \
    npm rebuild sqlite3 && \
    npm install --no-save @napi-rs/canvas && \
    cd node_modules/pdfjs-dist && \
    npm install --no-save @napi-rs/canvas

# Download and install task-runner-launcher
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        ARCH="amd64"; \
        CHECKSUM="e97ff9a5baeb8a4fc9653e36e29b1f6ff03a64a15889f8e55a7d1ffd2f15e5e2"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        ARCH="arm64"; \
        CHECKSUM="b87e01e48bd16f20f3d2a7b7a134c91e2c1963df8ed46d98bfea38a23e32daba"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    wget -q -O /tmp/task-runner-launcher \
        "https://github.com/n8n-io/task-runner-launcher/releases/download/${TASK_RUNNER_LAUNCHER_VERSION}/task-runner-launcher-linux-${ARCH}" && \
    echo "${CHECKSUM}  /tmp/task-runner-launcher" | sha256sum -c - && \
    chmod +x /tmp/task-runner-launcher && \
    mv /tmp/task-runner-launcher /usr/local/bin/task-runner-launcher

# Install Playwright with Chromium
RUN npm install -g playwright && \
    npx playwright install chromium --with-deps

# Copy configuration and scripts
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY n8n-task-runners.json /etc/n8n-task-runners.json
RUN chmod +x /docker-entrypoint.sh

# Create necessary directories and set permissions
RUN mkdir -p /home/node/.n8n && \
    chown -R node:node /home/node

# Switch to node user
USER node

# Expose n8n default port
EXPOSE 5678

# Set up volume for n8n data
VOLUME ["/home/node/.n8n"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:5678/healthz || exit 1

# Use tini as init system for proper signal handling
ENTRYPOINT ["/usr/bin/tini", "--", "/docker-entrypoint.sh"]

# Default command (can be overridden)
CMD []
