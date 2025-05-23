-- notify.lua -- Desktop notifications for mpv.
-- Just put this file into your ~/.config/mpv/scripts folder and mpv will find it.
--
-- Copyright (c) 2014 Roland Hieber
-- Modified for macOS compatibility
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-------------------------------------------------------------------------------
-- helper functions
-------------------------------------------------------------------------------

function print_debug(s)
    print("DEBUG: " .. s) -- comment out for no debug info
    return true
end

-- url-escape a string, per RFC 2396, Section 2
function string.urlescape(str)
    local s, c = string.gsub(str, "([^A-Za-z0-9_.!~*'()/-])",
        function(c)
            return ("%%%02x"):format(c:byte())
        end)
    return s
end

-- escape string for html
function string.htmlescape(str)
    local str = string.gsub(str, "<", "&lt;")
    str = string.gsub(str, ">", "&gt;")
    str = string.gsub(str, "&", "&amp;")
    str = string.gsub(str, "\"", "&quot;")
    str = string.gsub(str, "'", "&apos;")
    return str
end

-- escape string for shell inclusion
function string.shellescape(str)
    return "'"..string.gsub(str, "'", "'\"'\"'").."'"
end

-- converts string to a valid filename on most (modern) filesystems
function string.safe_filename(str)
    str = string.lower(str)
    str = string.gsub(str, "([^A-Za-z0-9_ .-])",'')
    str = str:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
    str = string.gsub(str, "%s+", "_")
    local s, _ = string.gsub(str, "([^A-Za-z0-9_.-])",
        function(c)
            return ("%02x"):format(c:byte())
        end)
    s = s:sub(1, -2)
    return s
end

-------------------------------------------------------------------------------
-- here we go.
-------------------------------------------------------------------------------

-- macOS-specific changes: Using curl instead of ssl.https
local timeout = 3
local uagen = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.64 Safari/537.36"

-- Custom HTTP request function using curl
function https_request(url)
    local command = string.format('curl -s -A "%s" -L "%s"', uagen, url)
    print_debug("Executing: " .. command)
    local handle = io.popen(command)
    local result = handle:read("*a")
    local success, exit_type, exit_code = handle:close()
    
    if success or (exit_code and exit_code == 0) then
        return result, 200, {}
    else
        return nil, exit_code or 0, {}
    end
end

-- macOS cache dir is different from Linux
local HOME = os.getenv("HOME")
local CACHE_DIR = HOME .. "/Library/Caches/mpv/coverart"
print_debug("making " .. CACHE_DIR)
os.execute("mkdir -p -- " .. string.shellescape(CACHE_DIR))

-- Make sure terminal-notifier is installed
os.execute("which terminal-notifier > /dev/null || (echo 'Please install terminal-notifier: brew install terminal-notifier' && exit 1)")

-- Alternative tmpname function that doesn't use posix module
function tmpname()
    local timestamp = os.time()
    local random = math.random(1000, 9999)
    local filename = CACHE_DIR .. "/rescale_" .. timestamp .. "_" .. random .. ".tmp"
    return filename
end

-- Initialize random seed
math.randomseed(os.time())

-- Generate md5 string for filename (macOS uses md5 not md5sum)
function md5_name(str)
    local cmd = ("echo %s | md5"):format(string.shellescape(str))
    local fn = io.popen(cmd)
    local rs = fn:read("*a")
    fn:close()
    rs = string.gsub(rs, "%W", "")
    return rs
end

-- Recursive fetch image url
function get_image_url(url, yt_url)
    -- force?
    if force == nil then
        -- exec url
        local d, c, h = https_request(url)

        -- only process if number
        if type(c) == "number" then
            -- return result on 200
            if c == 200 then
                return d
            end
        
            -- keep going on 300++
            print_debug("Http code: " .. c)
            -- With curl -L, redirects are automatically followed
        end
    end
    return download_youtube_thumbnail(yt_url)
end

function download_youtube_thumbnail(yt_url)
    print("Fetch thumbnail from youtube.")
    print_debug(("Try get from youtube - %s"):format(yt_url))
    local thumb = get_youtube_thumbnail(yt_url)
    if thumb ~= nil then
        print_debug(("[IMAGE_URL] - %s"):format(thumb))
        local d, c, h = https_request(thumb)
        print_debug(("[IMAGE_URL] code - %s"):format(c))
        if c == 200 then
            return d
        end
    end
    print_debug("Cover album not found")
    return nil
end

-- Get thumbnail from youtube url
function get_youtube_thumbnail(yt_url)
    local ytcommand = ("yt-dlp --get-thumbnail --skip-download %s"):format(yt_url)
    local handle = io.popen(ytcommand)
    local thumb = handle:read("*a")
    handle:close()

    if not thumb then
        print_debug("[thumbnail] not found!")
        return nil
    end
    thumb = string.gsub(thumb, '%s+', '')
    print_debug("get_youtube_thumbnail: " .. thumb)
    return thumb
end

-- scale an image file
-- @return boolean of success
function scale_image(src, dst)
    local convert_cmd = ("convert -scale x64 %s %s"):format(
        string.shellescape(src), string.shellescape(dst))
    print_debug("executing " .. convert_cmd)
    if os.execute(convert_cmd) then
        return true
    end
    return false
end

-- fetch cover art from MusicBrainz/Cover Art Archive
-- @return file name of downloaded cover art, or nil in case of error
-- @param mbid optional MusicBrainz release ID
function fetch_musicbrainz_cover_art(title, yt_url)
    print_debug("fetch_musicbrainz_cover_art parameters:")
    print_debug("title: " .. title)

    if not title or title == "" then
        print("not enough metadata, not fetching cover art.")
        return nil
    end

    local output_filename = md5_name(string.safe_filename(title))
    local mbid = ""
    print_debug("Safe filename: " .. output_filename)
    output_filename = (CACHE_DIR .. "/%s.png"):format(output_filename)

    -- Check if file exists in cache
    f, err = io.open(output_filename, "r")
    if f then
        print_debug("file is already in cache: " .. output_filename)
        f:close()
        return output_filename  -- exists and is readable
    elseif err and string.find(err, "[Pp]ermission denied") then
        print(("cannot read from cached file %s: %s"):format(output_filename, err))
        return nil
    end
    print_debug("fetching album art to " .. output_filename)

    local valid_mbid = function(s)
        return s and string.len(s) > 0 and not string.find(s, "[^0-9a-fA-F-]")
    end

    -- fetch release MBID from MusicBrainz, needed for Cover Art Archive
    if title then
        local query = ("%s"):format(title)
        local url = "https://musicbrainz.org/ws/2/release?limit=1&query=" .. string.urlescape(query)
        local d, c, h = https_request(url)

        -- poor man's XML parsing:
        mbid = string.match(d or "", "<%s*release%s+[^>]*id%s*=%s*['\"]%s*([0-9a-fA-F-]+)%s*['\"]")
        if not mbid or not valid_mbid(mbid) then
            print("MusicBrainz returned no match.")
            d = download_youtube_thumbnail(yt_url)
            mbid = 'failed'
            if d == nil then
                return nil
            end
        end
    end

    -- fetch image from Cover Art Archive
    local d = nil
    if valid_mbid(mbid) then
        print_debug("got MusicBrainz ID " .. mbid)
        local url = ("https://coverartarchive.org/release/%s/front-250"):format(mbid)
        print_debug("fetching album cover from " .. url)
        d = get_image_url(url, yt_url)

        if not d or string.len(d) < 1 then
            print(("Cover Art Archive returned no content for MBID %s"):format(mbid))
            d = nil
        end
    end

    if not d or string.len(d) < 1 then
        d = download_youtube_thumbnail(yt_url)
        if d == nil then
            return nil
        end
    end

    local tmp_filename = tmpname()
    local f = io.open(tmp_filename, "w+b")  -- Open in binary mode for image data
    f:write(d)
    f:flush()
    f:close()
    
    -- remove if not found
    if string.find(d, "Not Found") then
        if not os.remove(tmp_filename) then
            print("could not remove " .. tmp_filename .. ", please remove it manually")
        end
        return nil
    else
        -- make it a nice size
        if scale_image(tmp_filename, output_filename) then
            if not os.remove(tmp_filename) then
                print("could not remove " .. tmp_filename .. ", please remove it manually")
            end
            return output_filename
        end
        print(("could not scale %s to %s"):format(tmp_filename, output_filename))
    end
    return nil
end

function notify_current_track()
    -- Pause MPV
    mp.set_property_native("pause", true)

    -- Check if MPV Icon exists
    icon_filename = (CACHE_DIR .. "/%s.png"):format('mpv-icon')
    f, err = io.open(icon_filename, "r")
    if f then
        print_debug("file is already in cache: " .. icon_filename)
        f:close()
    elseif err and string.find(err, "[Pp]ermission denied") then
        print(("cannot read from cached file %s: %s"):format(icon_filename, err))
    else
        -- Download MPV Icon
        local d, c, h = https_request("https://cdn.icon-icons.com/icons2/1381/PNG/512/mpv_93749.png")
        if c ~= 200 then
            print(("Default cover not found!"))
        end
        if not d or string.len(d) < 1 then
            print(("Cover Art Archive returned no content"))
            print_debug("HTTP response: " .. d)
        else
            local tmp_mpvicon = tmpname()
            local f = io.open(tmp_mpvicon, "w+b")  -- Open in binary mode for image data
            f:write(d)
            f:flush()
            f:close()

            -- make it a nice size
            if scale_image(tmp_mpvicon, icon_filename) then
                if not os.remove(tmp_mpvicon) then
                    print("could not remove " .. tmp_mpvicon .. ", please remove it manually")
                end
            end
        end
    end

    -- Get youtube title
    local yt_url = mp.get_property_native("path")
    local ytcommand = ("yt-dlp --skip-download --get-title %s"):format(yt_url)
    local handle = io.popen(ytcommand)
    local title = handle:read("*a")
    handle:close()

    if not title then
        print("Could not get title, skipping notification")
        mp.set_property_native("pause", false)
        return
    end

    -- UC Words title
    title = string.lower(title)
    title = title:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
    local showTitle = string.gsub(title, "\n", "")
    title = string.gsub(title, '%s+', '')
    print_debug("notify_current_track: relevant metadata:")
    print_debug("Track title: " .. showTitle)
    
    local body = ""
    local params = ""
    local scaled_image = ""

    -- then load cover art from the internet
    if (not scaled_image or scaled_image == "" and title ~= "") then
        scaled_image = fetch_musicbrainz_cover_art(title, yt_url)
        cover_image = scaled_image
    end

    title = string.gsub(showTitle, '[ \t]+%f[\r\n%z]', '')
    if title == "" then
        body = string.shellescape(mp.get_property_native("filename"))
    else
        body = string.shellescape(("%s"):format(title))
    end

    -- Use terminal-notifier for macOS notifications
    local command
    if scaled_image and string.len(scaled_image) > 1 then
        command = ("terminal-notifier -title 'MPV' -message %s' is now playing in MPV' -contentImage %s"):format(
            body, string.shellescape(scaled_image))
    else
        -- Fallback to default icon if available
        if icon_filename and io.open(icon_filename, "r") then
            command = ("terminal-notifier -title 'MPV' -message %s' is now playing in MPV' -contentImage %s"):format(
                body, string.shellescape(icon_filename))
        else
            command = ("terminal-notifier -title 'MPV' -message %s' is now playing in MPV'"):format(body)
        end
    end
    
    print_debug("command: " .. command)
    os.execute(command)
    print("\n")

    -- Play MPV
    os.execute("sleep 1")
    mp.set_property_native("pause", false)
end

mp.register_event("file-loaded", notify_current_track)