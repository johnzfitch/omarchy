# Omarchy Fork Customization & Maintenance Guide

**Last Updated:** 2025-11-27
**Fork:** johnzfitch/omarchy
**Upstream:** basecamp/omarchy

## Project Summary

This fork maintains personal Omarchy customizations while automatically syncing with upstream updates. All customizations are preserved through automated conflict detection and resolution.

## What Was Fixed/Added

### Critical Fixes

1. **AUR Repository Corruption**
   - **Issue:** `yay -Slqa` returned binary garbage (bug in omarchy's yay 12.5.2-2)
   - **Solution:** Modified `bin/omarchy-pkg-aur-install` to fetch from aur.archlinux.org directly
   - **File:** `bin/omarchy-pkg-aur-install`

2. **Ethereal Theme Breakage**
   - **Issue:** Hyprland failed at boot due to missing theme symlink
   - **Solution:** Switched to catppuccin theme (ethereal later restored in upstream)
   - **Fix:** `~/.config/omarchy/current/theme` symlink validation

### Personal Customizations (2,628 lines)

**Waybar Configuration** (Multi-monitor)
- DP-1 primary ultrawide (3440x1440@174Hz) with custom styling
- Custom modules: `feed-ticker`, `stealth-proxy`, `mullvad`
- Bar height: 50px (vs 26px default)
- Workspaces 1-10 with persistent assignments
- Scripts: `feed-ticker.sh`, `mullvad-status.sh`, `stealth-proxy-status.sh`

**Hyprland Configuration**
- Custom keybindings: SUPER (no SHIFT) for frequent apps
  - SUPER+F → File manager
  - SUPER+B → Browser
  - SUPER+N → Editor
- NVIDIA GPU forcing: `env = WLR_DRM_DEVICES,/dev/dri/card1`
- Mouse: flat acceleration, 2.5x scroll speed
- Keyboard: 20ms repeat rate, 260ms delay
- Firefox/Floorp workspace integration
- OpenRGB autostart for RGB control

**Custom Scripts** (5 scripts, 51KB total)
- `config/hypr/scripts/ghostty-docs-omarchy.sh`
- `config/hypr/scripts/hypr-docs-browser.sh` (9KB)
- `config/hypr/scripts/hypr-docs-omarchy.sh`
- `config/hypr/scripts/hypr-docs-search.sh`
- `config/hypr/scripts/security-toolkit-omarchy.sh` (37KB)

**Nautilus GTK Optimizations**
- Ultra-compact icon view (48px thumbnails, 2-3px spacing)
- Compact sidebar (100px minimum width)
- Optimized list view with tight column spacing
- GTK 4.0: `config/gtk-4.0/gtk.css` (263 lines)
- GTK 3.0: `config/gtk-3.0/gtk.css` (233 lines)

**Nautilus Search Optimizations** (dconf)
- Full-text search disabled (`fts-enabled=false`) for speed
- Search result limit increased to 1000 (vs default ~100)
- Always show location entry bar for typing paths
- Detailed date/time format
- Show "Delete Permanently" and "Create Link" options
- 1GB thumbnail cache limit
- To restore: `dconf load /org/gnome/nautilus/preferences/ < config/nautilus-preferences.dconf`

**Custom Nautilus Fork** (~/dev/nautilus-fork)
- Custom build: GNOME Nautilus 50.alpha
- Installed to: `/usr/local/bin/nautilus`
- Built from feature/animated-webp-thumbnails branch
- **Nov 25 improvements:**
  - Configurable search result limiting (prevents resource exhaustion)
  - FUSE mount stale detection (prevents hanging on disconnected SSHFS)
  - Use-after-free crash fixes (async thumbnail operations)
  - Location shadow UI fixes (no duplicate path labels)
- **Nov 21 improvements:**
  - Search-cache integration (sub-millisecond search for 500k+ files)
  - Location shadow in list view (shows parent directory path)
- Repository: Personal fork, not in omarchy repo (source code changes)

## Repository Structure

```
johnzfitch/omarchy/
├── .github/
│   ├── workflows/
│   │   └── sync-upstream.yml          # Automated upstream sync
│   └── UPSTREAM_SYNC.md               # Sync workflow documentation
├── bin/
│   └── omarchy-pkg-aur-install        # Fixed AUR package installer
├── config/
│   ├── gtk-3.0/gtk.css                # Nautilus GTK3 optimizations
│   ├── gtk-4.0/gtk.css                # Nautilus GTK4 optimizations
│   ├── hypr/
│   │   ├── bindings.conf              # Custom keybindings
│   │   ├── envs.conf                  # NVIDIA GPU config
│   │   ├── input.conf                 # Mouse/keyboard settings
│   │   ├── monitors.conf              # Multi-monitor setup
│   │   ├── floorp-workspaces.conf     # Firefox workspace rules
│   │   └── scripts/                   # Custom scripts (5 files)
│   ├── waybar/
│   │   ├── config.jsonc               # Multi-monitor waybar
│   │   ├── style-dp1.css              # Monitor 1 styles
│   │   ├── style-dp3.css              # Monitor 2 styles
│   │   ├── feed-ticker.sh             # RSS feed ticker
│   │   ├── mullvad-status.sh          # VPN status
│   │   └── stealth-proxy-status.sh    # Proxy monitor
│   └── nautilus-omarchy-optimizations.md
└── CUSTOMIZATION_GUIDE.md             # This file
```

## Automated Upstream Sync

### How It Works

GitHub Actions workflow runs daily at 2 AM UTC:
1. Fetches updates from basecamp/omarchy
2. Attempts automatic merge
3. **On success:** Pushes merged changes to fork
4. **On conflict:** Creates GitHub issue titled "Upstream Sync Conflicts - @claude Help Needed"

### When Conflicts Occur

You'll receive a GitHub issue with:
- List of conflicted files
- Number of commits behind
- Resolution instructions

**To Resolve:**
1. Open repo in Claude Code
2. Say: "@claude, resolve the upstream merge conflicts from the GitHub issue"
3. Claude will:
   - Fetch upstream changes
   - Merge while preserving your customizations
   - Commit and push resolution
   - Close the issue

### Manual Sync Trigger

Trigger sync anytime:
1. Go to https://github.com/johnzfitch/omarchy/actions
2. Select "Sync Fork with Upstream Omarchy"
3. Click "Run workflow"

## Local Repository Setup

### Git Remotes

**Development Repo:** `~/dev/omarchy-base`
```bash
origin    git@github.com:johnzfitch/omarchy.git
upstream  https://github.com/basecamp/omarchy.git
```

**Installed Repo:** `~/.local/share/omarchy`
```bash
origin    git@github.com:johnzfitch/omarchy.git
upstream  https://github.com/basecamp/omarchy.git
```

### Update Workflow

**When you run `omarchy-update`:**
1. Pulls from `johnzfitch/omarchy` (your fork)
2. Runs `cp -R ~/.local/share/omarchy/config/* ~/.config/`
3. Your customizations sync automatically
4. Runs migrations
5. Updates system packages

**To add new customizations:**
```bash
cd ~/dev/omarchy-base

# Edit files in config/
vim config/waybar/config.jsonc

# Commit changes
git add config/
git commit -m "Add custom waybar module"
git push origin master

# Update installed omarchy
cd ~/.local/share/omarchy
git pull
```

## Protected Customizations

These configurations will survive all `omarchy-update` operations:

### Waybar
- Multi-monitor setup (DP-1 primary)
- Custom modules: feed-ticker, stealth-proxy, mullvad
- Enlarged bar height (50px)
- Per-monitor styling (style-dp1.css, style-dp3.css)
- All custom scripts in `config/waybar/`

### Hyprland
- Custom keybindings (SUPER+F, SUPER+B, SUPER+N)
- NVIDIA GPU forcing (`WLR_DRM_DEVICES=/dev/dri/card1`)
- Mouse settings (flat accel, 2.5x scroll)
- Keyboard settings (20ms repeat, 260ms delay)
- Firefox workspace integration
- All scripts in `config/hypr/scripts/`

### Nautilus
- GTK 4.0/3.0 optimizations (compact views)
- Search optimizations (disabled FTS, 1000 result limit)
- Location entry bar always visible
- Custom sidebar sizing (100px min)
- Detailed date/time format
- Environment date format config

### System
- AUR package fix (omarchy-pkg-aur-install)

## Server-Specific Configurations (NOT in Repo)

These remain local for security:

**cPanel SSHFS Mounts:**
- `~/.local/bin/mount-cpanel-servers`
- `~/.local/bin/mount-cpanel-servers-autostart`
- `~/.local/bin/remount-cpanel-servers`
- `~/.local/bin/unmount-cpanel-servers`
- `~/.local/bin/ssh-cpanel-exec`
- `~/.config/autostart/sshfs-mounts.desktop`

**SSH Configuration:**
- `~/.ssh/config` (host: internet, definitelynot)

**Big Boy NTFS Mount:**
- `~/.local/bin/mount-bigboy`
- `~/.config/systemd/user/home-zack-bigboy.mount`

## Troubleshooting

### AUR Package Installation Broken

**Symptom:** `omarchy-pkg-aur-install` shows binary garbage or fails

**Solution:**
```bash
cd ~/dev/omarchy-base
git pull origin master  # Get latest fix
cd ~/.local/share/omarchy
git pull origin master
```

The fix fetches packages from aur.archlinux.org instead of broken `yay -Slqa`.

### Hyprland Won't Start (Theme Missing)

**Symptom:** Error at boot about missing theme file

**Check:**
```bash
ls -la ~/.config/omarchy/current/theme/
```

**Fix:**
```bash
ln -sf ~/.local/share/omarchy/themes/catppuccin ~/.config/omarchy/current/theme
hyprctl reload
```

### Waybar Custom Modules Not Working

**Check scripts exist:**
```bash
ls -la ~/.config/waybar/*.sh
```

**Restore from repo:**
```bash
cd ~/.local/share/omarchy
git pull origin master
cp -R config/waybar/*.sh ~/.config/waybar/
chmod +x ~/.config/waybar/*.sh
```

### Customizations Lost After Update

**Check fork is upstream:**
```bash
cd ~/.local/share/omarchy
git remote -v
# Should show: origin  git@github.com:johnzfitch/omarchy.git
```

**If pointing to basecamp/omarchy:**
```bash
git remote set-url origin git@github.com:johnzfitch/omarchy.git
git fetch origin
git reset --hard origin/master
```

### Upstream Sync Workflow Failing

**Check Issues enabled:**
```bash
gh repo view johnzfitch/omarchy --json hasIssuesEnabled
```

**Enable if disabled:**
```bash
gh repo edit johnzfitch/omarchy --enable-issues
```

**Check workflow file:**
```bash
cat ~/dev/omarchy-base/.github/workflows/sync-upstream.yml
```

### Custom Nautilus Build Issues

**Check which Nautilus is running:**
```bash
which nautilus
# Should show: /usr/local/bin/nautilus

nautilus --version
# Should show: GNOME nautilus 50.alpha
```

**Rebuild custom Nautilus:**
```bash
cd ~/dev/nautilus-fork
ninja -C build
sudo -A ninja -C build install
```

**Search hanging on SSHFS mounts:**
- Custom build includes FUSE mount detection with 1-second timeout
- Unresponsive mounts automatically skipped during search
- Check mount status: `mount | grep fuse`
- Remount if needed: `remount-cpanel-servers`

**Search results limited to 1000:**
- Configurable via Preferences → Performance → Search Results Limit
- Or via dconf: `gsettings set org.gnome.nautilus.preferences search-results-limit 2000`
- Set to 0 for unlimited (not recommended for large directories)

## Key Commands Reference

### Update System
```bash
omarchy-update                    # Full system update (uses YOUR fork)
```

### Manage Customizations
```bash
cd ~/dev/omarchy-base            # Edit customizations here
git add config/
git commit -m "Description"
git push origin master

cd ~/.local/share/omarchy        # Pull to installed omarchy
git pull
```

### Manual Upstream Sync
```bash
cd ~/dev/omarchy-base
git fetch upstream
git merge upstream/master        # Resolve conflicts if needed
git push origin master

cd ~/.local/share/omarchy
git pull
```

### Check Sync Status
```bash
cd ~/dev/omarchy-base
git log --oneline HEAD..upstream/master | wc -l  # Commits behind
```

### Restore Broken Config
```bash
cd ~/.local/share/omarchy
git pull origin master
cp -R config/* ~/.config/

# Restore Nautilus search preferences
dconf load /org/gnome/nautilus/preferences/ < config/nautilus-preferences.dconf
```

## File Locations Quick Reference

### Development
- **Omarchy fork:** `~/dev/omarchy-base/`
- **Customization guide:** `~/dev/omarchy-base/CUSTOMIZATION_GUIDE.md`
- **Sync workflow:** `~/dev/omarchy-base/.github/workflows/sync-upstream.yml`

### Installed
- **Omarchy installation:** `~/.local/share/omarchy/`
- **Active configs:** `~/.config/`
- **Custom scripts:** `~/.local/bin/`

### Server Configs (Local Only)
- **cPanel mount scripts:** `~/.local/bin/mount-cpanel-*`
- **SSH config:** `~/.ssh/config`
- **SSHFS autostart:** `~/.config/autostart/sshfs-mounts.desktop`

### Custom Nautilus Fork (Local Only)
- **Nautilus fork:** `~/dev/nautilus-fork/`
- **Custom binary:** `/usr/local/bin/nautilus` (Nautilus 50.alpha)
- **Build directory:** `~/dev/nautilus-fork/build/`
- **Branch:** feature/animated-webp-thumbnails

## GitHub Actions Workflow

**Workflow file:** `.github/workflows/sync-upstream.yml`

**Features:**
- Daily sync at 2 AM UTC
- Automatic merge when no conflicts
- GitHub issue creation on conflicts
- Tags @claude for conflict resolution
- Step summary with conflict details
- No emojis (per CLAUDE.md conventions)

**Security:**
- Uses environment variables (no command injection)
- Follows GitHub Actions best practices
- Minimal permissions (contents, issues, pull-requests)

## Upstream Updates Received (188 commits)

**Major Features:**
- Ethereal theme restored
- Hackerman theme added (new)
- Channel/branch management system
- Xbox controller support
- Bluetooth launcher
- Reboot/shutdown commands
- omarchy-launch-tui helper
- 31 new migrations

**Improvements:**
- Walker refinements
- Ghostty updates
- Hyprland configuration improvements
- DaVinci Resolve support
- JetBrains IDE improvements

## Future Maintenance

### Adding New Customizations

1. Edit files in `~/dev/omarchy-base/config/`
2. Test changes in `~/.config/`
3. Commit to fork:
   ```bash
   cd ~/dev/omarchy-base
   git add config/
   git commit -m "Add: description"
   git push origin master
   ```
4. Pull to installed:
   ```bash
   cd ~/.local/share/omarchy
   git pull
   ```

### When Upstream Sync Conflicts

1. GitHub issue will be created automatically
2. Open issue, review conflicted files
3. Ask Claude: "@claude resolve upstream merge conflicts"
4. Claude will merge preserving your customizations
5. Issue will be auto-closed

### Monitoring Upstream

**Check commits behind:**
```bash
cd ~/dev/omarchy-base
git fetch upstream
git log --oneline HEAD..upstream/master | wc -l
```

**View upstream changes:**
```bash
git log --oneline HEAD..upstream/master
```

**Manual sync (when needed):**
```bash
git merge upstream/master
# Resolve conflicts if any
git push origin master
```

## Contact & Support

**For omarchy fork issues:**
- GitHub: https://github.com/johnzfitch/omarchy/issues
- Automated conflict resolution via @claude in GitHub issues

**For upstream omarchy:**
- GitHub: https://github.com/basecamp/omarchy
- Discord: https://omarchy.org/discord

## Version History

- **2025-11-27:** Omarchy fork setup and Nautilus search optimization
  - Fixed AUR corruption (yay -Slqa workaround)
  - Added 2,628 lines of customizations
  - Configured GitHub Actions workflow
  - Merged 188 upstream commits
  - Enabled GitHub Issues for conflict notifications
  - Added Nautilus search preferences (fts-enabled=false, 1000 result limit)

- **2025-11-25:** Custom Nautilus fork improvements (~/dev/nautilus-fork)
  - Configurable search result limiting (prevents resource exhaustion)
  - FUSE mount stale detection (1s timeout, prevents SSHFS hangs)
  - Use-after-free crash fixes (async thumbnail operations)
  - Location shadow UI refinements

- **2025-11-21:** Custom Nautilus fork - search-cache integration
  - Search-cache provider (sub-millisecond search for 500k+ files)
  - Location shadow in list view (parent directory path display)

---

**Remember:** All customizations in `config/` are protected. The automated workflow ensures upstream updates are merged while preserving your personal configurations. When conflicts occur, @claude will be notified via GitHub issue for resolution.
