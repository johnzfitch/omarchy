# Nautilus Omarchy Optimizations

Clean GTK4 CSS customizations for Nautilus file manager, optimized for tiling window managers like Hyprland.

## Features

### 1. Ultra-Compact Icon View
- **48px thumbnails** - Smaller than default slider minimum
- **Tight spacing** - 2-3px margins for maximum density
- **Stable scrolling** - Fixed dimensions prevent icon jumping
- **Small labels** - 9px font size for compact display

### 2. Compact Sidebar
- **100px minimum width** - Narrower for tiling layouts
- **10px font** - Smaller text and labels
- **12px icons** - Reduced icon size
- **Minimal padding** - 1-3px spacing throughout

### 3. Optional Sidebar-Free Mode
- **Full-width view** - Uncomment CSS block to hide sidebar
- **Keyboard toggle** - Use `F9` to show/hide sidebar
- **Enhanced pathbar** - Larger navigation buttons as alternative

### 4. Optimized List View
- **Compact columns** - Minimal width for Size/Type/Modified
- **Small fonts** - 0.85em base size for better density
- **Tight spacing** - 3px vertical padding
- **Smart column widths** - Optimized for common content

## Installation

### GTK 4.0 (Nautilus 49+)
```bash
cp gtk.css ~/.config/gtk-4.0/
```

### GTK 3.0 (Legacy apps)
```bash
cp gtk.css ~/.config/gtk-3.0/
```

### Apply Changes
```bash
pkill -9 nautilus  # Restart Nautilus
```

## Usage

### Enable Sidebar-Free Mode
Edit `~/.config/gtk-4.0/gtk.css` and uncomment:
```css
.nautilus-window flap,
.nautilus-window flap > revealer,
.nautilus-window placessidebar {
  min-width: 0px !important;
  opacity: 0 !important;
}
```

### Keyboard Shortcuts
- `F9` - Toggle sidebar visibility
- `Ctrl+H` - Show hidden files
- `Ctrl+L` - Focus location bar (type paths directly)

### Bookmarks Alternative
With sidebar hidden, use:
1. **Pathbar buttons** - Click folder names in top bar
2. **Bookmarks menu** - Click hamburger menu → Bookmarks
3. **Location bar** - `Ctrl+L` then type: `~/Downloads`, etc.

## Customization

### Adjust Icon Size
Change thumbnail dimensions (line ~175):
```css
.nautilus-window gridview image {
  min-width: 48px !important;  /* Smaller = more icons */
  min-height: 48px !important;
}
```

### Adjust Icon Spacing
Change margins (line ~160):
```css
.nautilus-window gridview > child {
  margin: 2px !important;  /* Smaller = tighter grid */
}
```

### Adjust Sidebar Width
Change minimum width (line ~118):
```css
placessidebar {
  min-width: 100px !important;  /* Narrower sidebar */
}
```

## Compatibility

- **GTK 4.0**: Nautilus 43+, GNOME Files 43+
- **GTK 3.0**: Older Nautilus versions
- **Window Managers**: Optimized for Hyprland, Sway, i3
- **Desktop Environments**: Works with GNOME, KDE, Xfce

## Technical Details

### CSS Strategy
- Uses `!important` to override theme defaults
- Targets specific Nautilus widgets for precision
- Fixed dimensions prevent layout shifts
- Minimal padding without breaking usability

### Performance
- No JavaScript or extensions required
- Pure CSS, no runtime overhead
- Instant loading, no startup delay
- Works offline, no network dependencies

## Contributing

This configuration is maintained for the Omarchy project. Contributions welcome:

- Test on different themes
- Report rendering issues
- Suggest usability improvements
- Submit GTK4 widget selectors

## License

Public domain / CC0. Use freely in your own projects.

## Credits

Developed for efficient file management in tiling window managers.
Optimized for Hyprland + Nautilus workflows.
