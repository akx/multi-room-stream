set("log.stdout", true)
set("harbor.bind_addrs", ["0.0.0.0"])
set("harbor.verbose", true)

icecast_host = getenv("ICECAST_HOST")
icecast_port = int_of_string(getenv("ICECAST_PORT"))
input_port = int_of_string(getenv("INPUT_PORT"))
icecast_password = getenv("ICECAST_SOURCE_PASSWORD")
storage_root = getenv("STORAGE_ROOT")

def quiet_title(m) = 
    [("title","Nothing")]
end

quiet = map_metadata(quiet_title, blank())

def store_meta(room, m) =
    system("echo " ^ string.quote(room) ^ " " ^ string.quote (json_of(m, compact=true)))
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
    radio = on_metadata(store_meta(room), radio)
    NAME = "Radio " ^ room
    # output.icecast(
    #     %mp3.abr(bitrate=128, min_bitrate=64, max_bitrate=192),
    #     name=NAME,
    #     description=NAME,
    #     host=icecast_host,
    #     port=icecast_port,
    #     password=icecast_password,
    #     mount=room ^ ".mp3",
    #     radio
    # )
    output.icecast(
        %vorbis.abr(bitrate=128),
        name=NAME,
        host=icecast_host,
        port=icecast_port,
        password=icecast_password,
        mount=room ^ ".ogg",
        radio
    )
end