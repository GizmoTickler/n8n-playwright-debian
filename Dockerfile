# Custom n8n Docker image based on Debian with Playwright support
# renovate: datasource=github-tags depName=nodejs/node versioning=node
ARG NODE_VERSION=22.21.0

FROM node:${NODE_VERSION}-trixie

# Accept build arguments for version control
ARG N8N_VERSION=1.117.3
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
    NODE_VERSION=22 \
    TASK_RUNNER_LAUNCHER_VERSION=${TASK_RUNNER_LAUNCHER_VERSION} \
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
    npm install --no-save --legacy-peer-deps @napi-rs/canvas && \
    cd node_modules/pdfjs-dist && \
    npm install --no-save --legacy-peer-deps @napi-rs/canvas

# Download and install task-runner-launcher (amd64 only)
RUN echo "Downloading task-runner-launcher v${TASK_RUNNER_LAUNCHER_VERSION} for amd64..." && \
    wget --progress=dot:giga -O /tmp/task-runner-launcher.tar.gz \
        "https://github.com/n8n-io/task-runner-launcher/releases/download/${TASK_RUNNER_LAUNCHER_VERSION}/task-runner-launcher-${TASK_RUNNER_LAUNCHER_VERSION}-linux-amd64.tar.gz" && \
    echo "Verifying checksum..." && \
    echo "f4831a3859c4551597925a5f62fa544ef06733b2f875b612745ee458321c75e7  /tmp/task-runner-launcher.tar.gz" | sha256sum -c - && \
    echo "Extracting archive..." && \
    tar -xzf /tmp/task-runner-launcher.tar.gz -C /tmp && \
    chmod +x /tmp/task-runner-launcher && \
    mv /tmp/task-runner-launcher /usr/local/bin/task-runner-launcher && \
    rm /tmp/task-runner-launcher.tar.gz && \
    echo "Task runner launcher installed successfully"

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
