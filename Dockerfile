# Custom n8n Docker image based on Debian with Playwright support
FROM node:22-trixie

# Set environment variables
ENV N8N_VERSION=latest \
    NODE_ENV=production \
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
    # n8n dependencies
    python3 \
    python3-pip \
    build-essential \
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

# Create n8n user
RUN useradd -m -u 1000 -s /bin/bash n8n

# Set working directory
WORKDIR /home/n8n

# Install n8n globally
RUN npm install -g n8n@${N8N_VERSION}

# Install Playwright with Chromium
RUN npm install -g playwright && \
    npx playwright install chromium --with-deps

# Create necessary directories
RUN mkdir -p /home/n8n/.n8n && \
    chown -R n8n:n8n /home/n8n

# Switch to n8n user
USER n8n

# Expose n8n default port
EXPOSE 5678

# Set up volume for n8n data
VOLUME ["/home/n8n/.n8n"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:5678/healthz || exit 1

# Start n8n
CMD ["n8n"]
