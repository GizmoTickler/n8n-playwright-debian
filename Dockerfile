# Custom n8n Docker image based on Debian with Playwright support
# Node version is automatically synced from n8n's upstream via GitHub Actions
# See: .github/workflows/sync-n8n-node-version.yml
ARG NODE_VERSION=22.21.1

FROM node:${NODE_VERSION}-trixie

# Accept build arguments for version control
ARG N8N_VERSION=2.2.4
ARG TASK_RUNNER_LAUNCHER_VERSION=1.4.1
ARG BUILD_DATE
ARG VCS_REF

# Labels for better image metadata (following OCI standards)
LABEL org.opencontainers.image.title="n8n with Playwright on Debian"
LABEL org.opencontainers.image.description="Custom n8n Docker image based on Debian with Playwright browser automation support"
LABEL org.opencontainers.image.vendor="GizmoTickler"
LABEL org.opencontainers.image.version="${N8N_VERSION}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.revision="${VCS_REF}"
LABEL org.opencontainers.image.source="https://github.com/GizmoTickler/n8n-playwright-debian"
LABEL n8n.version="${N8N_VERSION}"
LABEL task-runner.version="${TASK_RUNNER_LAUNCHER_VERSION}"

# Set environment variables
ENV N8N_VERSION=${N8N_VERSION} \
    TASK_RUNNER_LAUNCHER_VERSION=${TASK_RUNNER_LAUNCHER_VERSION} \
    NODE_ENV=production \
    NODE_ICU_DATA=/usr/local/lib/node_modules/full-icu \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=0 \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright \
    # Reduce npm noise and improve performance
    NPM_CONFIG_LOGLEVEL=warn \
    NPM_CONFIG_UPDATE_NOTIFIER=false

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

# Install n8n globally with full-icu for internationalization
# Then rebuild native modules and add canvas support for PDF rendering
RUN npm install -g n8n@${N8N_VERSION} full-icu && \
    cd /usr/local/lib/node_modules/n8n && \
    npm rebuild sqlite3 && \
    npm install --no-save --legacy-peer-deps @napi-rs/canvas && \
    cd node_modules/pdfjs-dist && \
    npm install --no-save --legacy-peer-deps @napi-rs/canvas && \
    # Clean npm cache to reduce image size
    npm cache clean --force

# Download and install task-runner-launcher (amd64 only)
# Downloads checksum dynamically to stay in sync with version updates (matches official n8n approach)
RUN echo "Downloading task-runner-launcher v${TASK_RUNNER_LAUNCHER_VERSION} for amd64..." && \
    mkdir -p /tmp/launcher && cd /tmp/launcher && \
    wget -q "https://github.com/n8n-io/task-runner-launcher/releases/download/${TASK_RUNNER_LAUNCHER_VERSION}/task-runner-launcher-${TASK_RUNNER_LAUNCHER_VERSION}-linux-amd64.tar.gz" && \
    wget -q "https://github.com/n8n-io/task-runner-launcher/releases/download/${TASK_RUNNER_LAUNCHER_VERSION}/task-runner-launcher-${TASK_RUNNER_LAUNCHER_VERSION}-linux-amd64.tar.gz.sha256" && \
    echo "Verifying checksum..." && \
    echo "$(cat task-runner-launcher-${TASK_RUNNER_LAUNCHER_VERSION}-linux-amd64.tar.gz.sha256)  task-runner-launcher-${TASK_RUNNER_LAUNCHER_VERSION}-linux-amd64.tar.gz" > checksum.sha256 && \
    sha256sum -c checksum.sha256 && \
    echo "Extracting archive..." && \
    tar -xzf task-runner-launcher-${TASK_RUNNER_LAUNCHER_VERSION}-linux-amd64.tar.gz && \
    chmod +x task-runner-launcher && \
    mv task-runner-launcher /usr/local/bin/task-runner-launcher && \
    cd / && rm -rf /tmp/launcher && \
    echo "Task runner launcher installed successfully"

# Install Playwright with Chromium (use npx directly, no need for global install)
RUN npx playwright install chromium --with-deps && \
    # Clean npm cache again after playwright install
    npm cache clean --force && \
    rm -rf /tmp/*

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
