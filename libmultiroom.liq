set("log.stdout", true)
set("harbor.bind_addrs", ["0.0.0.0"])
set("harbor.verbose", true)

icecast_host = getenv("ICECAST_HOST")
icecast_port = getenv("ICECAST_PORT")
input_port = getenv("INPUT_PORT")
icecast_password = getenv("ICECAST_SOURCE_PASSWORD")
storage_root = getenv("STORAGE_ROOT")

quiet = blank()

def store_meta(room, m) =
    artist = m["artist"]
    title = m["title"]
    system("echo New Metadata - " ^ quote (room) ^ " " ^ quote (artist ^ " - " ^ title))
    #) ^ " > /dev/null 2>&1 &")
end

def decl_room(room, password) =
    live = input.harbor(
        room ^ "-input",
        id="live-input-" ^ room,
        port=input_port,
        password=password,
    )
    #live = map_metadata([("artist", "LIVE"), ("title", "LIVE")], live)
    output.file(
        %mp3.vbr(quality=0, id3v2=true),
        fallible=true,
        reopen_on_metadata=true,
        reopen_delay=10.0,
        storage_root ^ "/" ^ room ^ "-%Y-%m-%d-%H-%M-%S.mp3",
        live,
    )
    radio = fallback(id="radio-" ^ room, track_sensitive=false, [live, quiet])
    radio = audio_to_stereo(radio)
    radio = on_metadata(store_meta, radio)
    NAME = "Radio " ^ room
    GENRE = "Misc"
    URL = ""
    output.icecast(
        %mp3.abr(bitrate=128, min_bitrate=64, max_bitrate=192),
        name=NAME,
        description=NAME,
        host=icecast_host,
        port=icecast_port,
        password=icecast_password,
        mount=room ^ ".mp3",
        radio
    )
    output.icecast(
        %vorbis.abr(bitrate=96),
        name=NAME,
        description=NAME,
        genre=GENRE,
        url=URL,
        host=icecast_host,
        port=icecast_port,
        password=icecast_password,
        mount=room ^ ".ogg",
        radio
    )
end