# n8n Docker Image with Playwright Support

Custom n8n Docker image based on Debian with Playwright and Chromium pre-installed.

## Features

- **Base Image**: Debian Trixie (node:22-trixie)
- **n8n**: Latest version installed globally
- **Playwright**: Pre-installed with Chromium browser
- **Platform Support**: linux/amd64 and linux/arm64
- **Additional Tools**:
  - GraphicsMagick for image processing
  - jq for JSON processing
  - SSH client for git operations
  - Tini for proper signal handling
  - Custom SSL certificate support
  - Full timezone data (tzdata)

## Quick Start

### Using Docker

```bash
docker pull ghcr.io/gizmotickler/n8n-playwright-debian:latest

docker run -it --rm \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  ghcr.io/gizmotickler/n8n-playwright-debian:latest
```

### Using Docker Compose

```yaml
version: '3.8'

services:
  n8n:
    image: ghcr.io/gizmotickler/n8n-playwright-debian:latest
    ports:
      - "5678:5678"
    volumes:
      - n8n_data:/home/node/.n8n
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=changeme
    restart: unless-stopped

volumes:
  n8n_data:
```

## Building Locally

```bash
docker build -t n8n-playwright-debian .
```

### Build with specific n8n version

```bash
docker build --build-arg N8N_VERSION=1.20.0 -t n8n-playwright-debian .
```

## Using Playwright in n8n

Playwright is pre-installed and ready to use in your n8n workflows. You can use it with the Execute Command or Code nodes.

### Example: Taking a Screenshot

```javascript
const { chromium } = require('playwright');

const browser = await chromium.launch({
  args: ['--no-sandbox', '--disable-setuid-sandbox']
});
const page = await browser.newPage();
await page.goto('https://example.com');
const screenshot = await page.screenshot({ encoding: 'base64' });
await browser.close();

return { screenshot };
```

## Environment Variables

Common n8n environment variables:

- `N8N_BASIC_AUTH_ACTIVE`: Enable basic auth (true/false)
- `N8N_BASIC_AUTH_USER`: Basic auth username
- `N8N_BASIC_AUTH_PASSWORD`: Basic auth password
- `N8N_HOST`: Host name (default: localhost)
- `N8N_PORT`: Port (default: 5678)
- `N8N_PROTOCOL`: Protocol (http/https)
- `WEBHOOK_URL`: Webhook URL for external access

For more environment variables, see the [official n8n documentation](https://docs.n8n.io/hosting/configuration/environment-variables/).

## Custom Certificates

This image supports custom SSL certificates for enterprise environments with self-signed or internal certificate authorities.

To use custom certificates, mount them to `/opt/custom-certificates`:

```bash
docker run -it --rm \
  -p 5678:5678 \
  -v /path/to/your/certificates:/opt/custom-certificates \
  -v n8n_data:/home/node/.n8n \
  ghcr.io/gizmotickler/n8n-playwright-debian:latest
```

Or with Docker Compose:

```yaml
services:
  n8n:
    image: ghcr.io/gizmotickler/n8n-playwright-debian:latest
    volumes:
      - n8n_data:/home/node/.n8n
      - /path/to/your/certificates:/opt/custom-certificates
```

The entrypoint script will automatically configure Node.js to trust these certificates.

## GitHub Container Registry

Images are automatically built and published to GitHub Container Registry (GHCR) on:
- Push to main/master branch (tagged as `latest`)
- Git tags matching `v*` pattern (tagged with version)
- Manual workflow dispatch

## License

See [LICENSE](LICENSE) file for details.

## Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Playwright Documentation](https://playwright.dev/)
- [n8n Community](https://community.n8n.io/)
