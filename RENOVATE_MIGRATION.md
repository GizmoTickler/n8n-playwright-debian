# Migration from Dependabot to Renovate + GitHub Actions

## Why Renovate + GitHub Actions?

This project has migrated from Dependabot to a hybrid approach using Renovate for most dependencies and GitHub Actions for tracking n8n's Node version from their upstream Dockerfile.

## Key Benefits

### 1. Automatic Node Version Tracking (GitHub Actions)
**Problem:** n8n updates their Node version periodically, and we need to stay in sync to ensure 100% compatibility.

**Solution:** A GitHub Actions workflow (`.github/workflows/sync-n8n-node-version.yml`) automatically fetches n8n's Node version from [their Dockerfile](https://github.com/n8n-io/n8n/blob/master/docker/images/n8n/Dockerfile) daily. When n8n updates their Node version, the workflow automatically creates a PR to update ours.

**Why not Renovate for Node?** Renovate cannot directly track values from external repository files. GitHub Actions provides a simple, reliable solution specifically for this use case.

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

## Comparison: Dependabot vs Renovate + GitHub Actions

| Feature | Dependabot | Renovate + GitHub Actions |
|---------|-----------|---------------------------|
| Track n8n's upstream Node version | ❌ Manual | ✅ Automatic (GitHub Actions) |
| npm package updates | ❌ Not configured | ✅ Yes (Renovate) |
| Docker image updates | ✅ Yes | ✅ Yes (Renovate - better) |
| GitHub Actions updates | ✅ Yes | ✅ Yes (Renovate) |
| Auto-merge safe updates | ❌ Limited | ✅ Configurable (Renovate) |
| Grouped updates | ❌ No | ✅ Yes (Renovate) |
| Dependency dashboard | ❌ No | ✅ Yes (Renovate) |
| Regex managers for custom tracking | ❌ No | ✅ Yes (Renovate) |

## How It Works

### Node Version Tracking (GitHub Actions)

A daily GitHub Actions workflow (`.github/workflows/sync-n8n-node-version.yml`) automatically:
1. Fetches n8n's Dockerfile from `https://github.com/n8n-io/n8n/blob/master/docker/images/n8n/Dockerfile`
2. Extracts their `NODE_VERSION` using regex
3. Compares it with our Dockerfile's `NODE_VERSION`
4. If different, automatically creates a PR with:
   - Updated Node version in Dockerfile
   - Detailed description explaining the change
   - Link to n8n's upstream source
   - Testing checklist

**Workflow Schedule:**
- Runs daily at 6 AM UTC
- Can be triggered manually via GitHub Actions UI
- Also runs when the workflow file itself is updated

### n8n Package Tracking (Renovate)

Renovate's regex manager tracks the n8n npm package version:

```dockerfile
ARG N8N_VERSION=1.117.3
```

When n8n releases a new version, Renovate will:
1. Detect the new version from npm
2. Create a PR with changelog and release notes
3. Update the ARG in the Dockerfile

## Migration Steps

### 1. Enable GitHub Actions Workflow (Already Configured!)

The Node version sync workflow (`.github/workflows/sync-n8n-node-version.yml`) is automatically enabled once the file is in your repository. It will:
- Run daily at 6 AM UTC
- Can be triggered manually from the Actions tab
- Automatically create PRs when n8n's Node version changes

**To manually trigger:**
1. Go to your repository's "Actions" tab
2. Select "Sync Node Version from n8n Upstream"
3. Click "Run workflow"

### 2. Enable Renovate (One-time setup)

**Option A: GitHub App (Recommended)**
1. Go to https://github.com/apps/renovate
2. Click "Configure"
3. Select your repository
4. Renovate will automatically detect `renovate.json` and start working

**Option B: Self-hosted**
Follow the [Renovate self-hosted documentation](https://docs.renovatebot.com/getting-started/running/)

### 3. Remove Dependabot (After Renovate is working)

Once Renovate is enabled and working:

```bash
# Delete the old Dependabot config
rm .github/dependabot.yml

# Commit the change
git add .github/dependabot.yml
git commit -m "chore: remove dependabot config (migrated to renovate)"
git push
```

### 4. Monitor Updates

**Node Version (GitHub Actions):**
- Check the Actions tab for workflow runs
- PRs will be automatically created when n8n updates Node

**Other Dependencies (Renovate):**

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

**GitHub Actions (Node Version):**
- **Daily check**: 6 AM UTC
- **Manual trigger**: Available anytime via Actions tab

**Renovate (Other Dependencies):**
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
