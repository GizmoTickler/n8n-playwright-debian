# Migration from Dependabot to Renovate

## Why Renovate?

This project has migrated from Dependabot to Renovate for better dependency management, particularly to automatically track n8n's Node version from their upstream Dockerfile.

## Key Benefits

### 1. Automatic Node Version Tracking
**Problem:** n8n updates their Node version periodically, and we need to stay in sync to ensure 100% compatibility.

**Solution:** Renovate uses regex managers to track the Node version directly from [n8n's Dockerfile](https://github.com/n8n-io/n8n/blob/master/docker/images/n8n/Dockerfile). When n8n updates their Node version, Renovate will automatically create a PR to update ours.

### 2. Better Dependency Coverage
- **npm packages**: Tracks n8n core package updates
- **Docker images**: Monitors base image updates with digest pinning
- **GitHub Actions**: Keeps workflows up-to-date
- **Task Runner Launcher**: Tracks n8n-io/task-runner-launcher releases

### 3. Smart Automation
- Auto-merges patch/minor Docker updates
- Auto-merges critical security patches
- Groups related updates (e.g., Node + n8n if both change)
- Respects semantic versioning

### 4. Better Visibility
- **Dependency Dashboard**: Single issue showing all pending updates
- Tracks Node version source with links to upstream
- Clear PR descriptions with changelogs

## Comparison: Dependabot vs Renovate

| Feature | Dependabot | Renovate |
|---------|-----------|----------|
| Track n8n's upstream Node version | ❌ Manual | ✅ Automatic |
| npm package updates | ❌ Not configured | ✅ Yes |
| Docker image updates | ✅ Yes | ✅ Yes (better) |
| GitHub Actions updates | ✅ Yes | ✅ Yes |
| Auto-merge safe updates | ❌ Limited | ✅ Configurable |
| Grouped updates | ❌ No | ✅ Yes |
| Dependency dashboard | ❌ No | ✅ Yes |
| Regex managers for custom tracking | ❌ No | ✅ Yes |

## How It Works

### Node Version Tracking

The Dockerfile now includes a special comment:

```dockerfile
# renovate: datasource=github-tags depName=nodejs/node versioning=node
ARG NODE_VERSION=22.21.0
```

Renovate reads this comment and:
1. Monitors Node.js releases via GitHub tags
2. Checks if n8n has updated their Node version
3. Creates a PR when a new version is available
4. Updates both the ARG and any related references

### n8n Package Tracking

The regex manager also tracks the n8n npm package version:

```dockerfile
ARG N8N_VERSION=1.117.3
```

When n8n releases a new version, Renovate will:
1. Detect the new version from npm
2. Create a PR with changelog and release notes
3. Update the ARG in the Dockerfile

## Migration Steps

### 1. Enable Renovate (One-time setup)

**Option A: GitHub App (Recommended)**
1. Go to https://github.com/apps/renovate
2. Click "Configure"
3. Select your repository
4. Renovate will automatically detect `renovate.json` and start working

**Option B: Self-hosted**
Follow the [Renovate self-hosted documentation](https://docs.renovatebot.com/getting-started/running/)

### 2. Remove Dependabot (After Renovate is working)

Once Renovate is enabled and working:

```bash
# Delete the old Dependabot config
rm .github/dependabot.yml

# Commit the change
git add .github/dependabot.yml
git commit -m "chore: remove dependabot config (migrated to renovate)"
git push
```

### 3. Monitor the Dependency Dashboard

Renovate will create an issue titled "🤖 Renovate Dependency Dashboard" that shows:
- All pending updates
- Updates that are blocked or rate-limited
- Updates that have errors

## Configuration Highlights

### Auto-merge Rules

The following updates are auto-merged:
- Minor/patch Docker image updates
- Critical security patches
- Updates with passing CI checks

### Update Schedule

- **Regular updates**: Monday mornings (before 6am UTC)
- **Security updates**: Anytime (immediate)

### Rate Limiting

To avoid overwhelming CI:
- Max 5 PRs open concurrently
- Max 2 PRs created per hour

## Customization

Edit `renovate.json` to adjust:
- Update schedules
- Auto-merge rules
- Grouping strategies
- Labels and PR titles

See [Renovate documentation](https://docs.renovatebot.com/configuration-options/) for all options.

## Testing

To test Renovate locally:

```bash
# Install Renovate CLI
npm install -g renovate

# Dry run (no changes)
renovate --platform=github --token=$GITHUB_TOKEN --dry-run=full

# See what would be updated
renovate --platform=github --token=$GITHUB_TOKEN --dry-run=lookup
```

## Troubleshooting

### Renovate not creating PRs?

1. Check the Dependency Dashboard issue for errors
2. Verify the configuration with: https://app.renovatebot.com/config-validator
3. Check Renovate logs in the GitHub Actions tab (if using GitHub App)

### Want to manually trigger an update?

Add a comment to the Dependency Dashboard issue:
```
@renovatebot rebase
```

## Resources

- [Renovate Documentation](https://docs.renovatebot.com/)
- [Configuration Options](https://docs.renovatebot.com/configuration-options/)
- [Regex Managers](https://docs.renovatebot.com/modules/manager/regex/)
- [n8n's Dockerfile](https://github.com/n8n-io/n8n/blob/master/docker/images/n8n/Dockerfile)
