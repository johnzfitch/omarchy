# Upstream Sync Workflow

This repository automatically syncs with upstream [basecamp/omarchy](https://github.com/basecamp/omarchy) daily.

## How It Works

The GitHub Actions workflow (`.github/workflows/sync-upstream.yml`) runs daily at 2 AM UTC and:

1. **Fetches upstream changes** from basecamp/omarchy
2. **Attempts automatic merge** of upstream updates
3. **On success**: Pushes merged changes to your fork automatically
4. **On conflict**: Creates a GitHub issue with details and asks @claude for help

## When Conflicts Occur

If the automatic merge fails, you'll receive a GitHub issue titled:
> 🚨 Upstream Sync Conflicts - @claude Help Needed

The issue will contain:
- List of conflicted files
- Number of commits behind upstream
- Instructions for resolution

### Resolving with Claude Code

1. Open the repo in Claude Code
2. Run:
   ```bash
   cd ~/dev/omarchy-base
   git fetch upstream
   git merge upstream/master
   ```
3. Ask Claude: "Please resolve these merge conflicts while preserving my custom configurations"
4. After Claude resolves:
   ```bash
   git add .
   git commit -m "Resolve upstream merge conflicts"
   git push origin master
   ```
5. Close the GitHub issue

### Manual Trigger

You can manually trigger the sync workflow:
1. Go to **Actions** tab on GitHub
2. Select **Sync Fork with Upstream Omarchy**
3. Click **Run workflow**

## Customizations Protected

The workflow is designed to preserve your personal customizations:
- Waybar multi-monitor configuration
- Hyprland keybindings and settings
- Custom scripts in `config/hypr/scripts/`
- Nautilus GTK optimizations
- All other configs in `config/`

When conflicts occur, Claude will help merge upstream changes while keeping your customizations intact.

## Monitoring

Check the **Actions** tab to see sync status:
- ✅ Green: Successfully merged upstream updates
- 🔴 Red: Conflicts detected, issue created
- ⚪ Grey: No updates available

## Security

The workflow uses environment variables to prevent command injection and follows GitHub Actions security best practices.
