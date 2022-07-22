# mpv-youtube-notify
⚠ Note: This script is originaly from [mpv-notify](https://github.com/rohieb/mpv-notify), I just modify it a little :)

----

Description
--------
Add desktop notifications to the [mpv](http://mpv.io) media player when streaming from youtube, which show
cover album and title when the playlist changes.

Features
--------
* shows youtube video title
* tries to find load cover art from coverartarchive.org and caches it locally.

Requirements
------------

* [mpv](http://mpv.io) (>= 0.3.6)
* [Lua](http://lua.org) (>= 5.2)
* [lua-socket](http://w3.impa.br/~diego/software/luasocket/)
* [lua-sec](https://github.com/brunoos/luasec/)
* [lua-posix](https://github.com/luaposix/luaposix)
* `notify-send` from [libnotify](https://github.com/GNOME/libnotify)
* `convert` from [ImageMagick](http://www.imagemagick.org)

On recent Debians, do a `sudo apt install lua-socket lua-sec lua-posix libnotify-bin imagemagick`

How to use
----------
Copy this lua script to ```~/.config/mpv/scripts/``` so MPV will automatic load it or use direct load.

Play youtube from list with additional option:

    mpv --script=/path/to/youtube-notify.lua --playlist=/path/to/youtube/playlist.lst --term-playing-msg='Title: ${media-title}' --ytdl-format="bestvideo[height<=?1080][vcodec!=vp9]+bestaudio/best" --no-video --shuffle --slang=id,en

Play youtube directly:

    mpv --script=/path/to/youtube-notify.lua https://www.youtube.com/watch?v=SlPhMPnQ58k --no-video

License
-------

[mpv-notify](https://github.com/rohieb/mpv-notify) was written by Roland Hieber <rohieb at rohieb.name>, you can use it
under the terms of the [MIT license](http://choosealicense.com/licenses/mit/).
