# mpv-youtube-notify

⚠ Note: This script is originally from [mpv-notify](https://github.com/rohieb/mpv-notify), with modifications for YouTube integration and macOS compatibility.

----

## Description

Add desktop notifications to the [mpv](http://mpv.io) media player when streaming from YouTube, displaying video title and cover art when the playlist changes.

## Features

* Shows YouTube video title in system notifications
* Fetches cover art from MusicBrainz/Cover Art Archive or YouTube thumbnails
* Caches artwork locally for better performance
* Cross-platform: supports both Linux and macOS
  
## Screenshots
Linux Notification
![Linux Notification](https://raw.githubusercontent.com/benedict-erwin/mpv-youtube-notify/master/screenshots/linux_notification.png)

MacOS Notification
![MacOS Notification](https://raw.githubusercontent.com/benedict-erwin/mpv-youtube-notify/master/screenshots/macos_notification.png) 

## Requirements and Installation

### Linux

**Dependencies:**
* [mpv](http://mpv.io) (>= 0.3.6)
* [Lua](http://lua.org) (>= 5.2)
* [lua-socket](http://w3.impa.br/~diego/software/luasocket/)
* [lua-sec](https://github.com/brunoos/luasec/)
* [lua-posix](https://github.com/luaposix/luaposix)
* `notify-send` from [libnotify](https://github.com/GNOME/libnotify)
* `convert` from [ImageMagick](http://www.imagemagick.org)
* `yt-dlp` for YouTube integration

**Installation on Debian/Ubuntu:**
```bash
sudo apt install mpv lua5.2 lua-socket lua-sec lua-posix libnotify-bin imagemagick python3-pip
sudo pip3 install yt-dlp
```

**Installation on Arch Linux:**
```bash
sudo pacman -S mpv lua lua-socket lua-sec lua-posix libnotify imagemagick python-pip
sudo pip install yt-dlp
```

**Installation on Fedora:**
```bash
sudo dnf install mpv lua lua-socket lua-sec lua-posix libnotify ImageMagick python3-pip
sudo pip3 install yt-dlp
```

### macOS

**Dependencies:**
* [mpv](http://mpv.io)
* [Lua](http://lua.org) (LuaJIT comes with mpv Homebrew package)
* [terminal-notifier](https://github.com/julienXX/terminal-notifier) for macOS notifications
* [ImageMagick](http://www.imagemagick.org) for image processing
* `yt-dlp` for YouTube integration

**Installation with Homebrew:**
```bash
# Install main dependencies
brew install mpv yt-dlp imagemagick terminal-notifier

# Make sure mpv config directory exists
mkdir -p ~/.config/mpv/scripts
```

## Script Installation

1. Choose the appropriate script for your operating system:
   - `youtube-notify.lua` for Linux
   - `youtube-notify-macos.lua` for macOS

2. Copy the script to your mpv scripts directory:
   ```bash
   # For Linux
   cp youtube-notify.lua ~/.config/mpv/scripts/
   
   # For macOS
   cp youtube-notify-macos.lua ~/.config/mpv/scripts/youtube-notify.lua
   ```

## Configuration for YouTube Sign-In Issues

If you encounter the "Sign in to confirm you're not a bot" error with YouTube, create a configuration file:

```bash
# Create or edit mpv.conf
nano ~/.config/mpv/mpv.conf
```

Add the following lines:
```
# YouTube specific settings
ytdl-raw-options=cookies-from-browser=chrome,geo-bypass=yes
```

Replace `chrome` with your browser of choice (`firefox`, `safari`, etc.).

Or you can export the cookies into text file and use it:
```
# Use exported cookies
ytdl-raw-options=cookies=/path/to/your/youtube_cookies.txt
```

## Usage

### Play YouTube from a playlist:

```bash
mpv --playlist=/path/to/youtube/playlist.lst --ytdl-format="bestvideo[height<=?1080][vcodec!=vp9]+bestaudio/best" --no-video --shuffle
```

### Play directly from a YouTube URL:

```bash
mpv https://www.youtube.com/watch?v=SlPhMPnQ58k --ytdl-format="bestvideo[height<=?1080][vcodec!=vp9]+bestaudio/best" --no-video
```

### Keyboard Controls

While playing, you can use these keyboard shortcuts:
- `Space` or `p`: Play/Pause
- `q`: Quit/Stop
- `>`: Next track in playlist
- `<`: Previous track in playlist
- `/` and `*`: Decrease/Increase volume
- `m`: Mute
- Left/Right arrow: Seek backward/forward 5 seconds
- Up/Down arrow: Seek forward/backward 1 minute

## Troubleshooting

### Linux Issues

- If notifications don't appear, check that `notify-send` is working properly
- Ensure you have the correct permissions for the cache directory

### macOS Issues

- If notifications don't appear, check that Terminal has notification permissions in System Settings
- Install terminal-notifier with `brew install terminal-notifier`
- For YouTube sign-in issues, use cookies from your browser with the configuration above

## License

[mpv-notify](https://github.com/rohieb/mpv-notify) was written by Roland Hieber <rohieb at rohieb.name>.
This project is available under the terms of the [MIT license](http://choosealicense.com/licenses/mit/).
