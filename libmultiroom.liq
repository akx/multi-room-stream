set("log.stdout", true)
set("harbor.bind_addrs", ["0.0.0.0"])
set("harbor.verbose", true)

icecast_host = getenv("ICECAST_HOST")
icecast_port = int_of_string(getenv("ICECAST_PORT"))
input_port = int_of_string(getenv("INPUT_PORT"))
icecast_password = getenv("ICECAST_SOURCE_PASSWORD")
storage_root = getenv("STORAGE_ROOT")
reopen_storage_on_metadata = bool_of_string(getenv("STORAGE_SPLIT_METADATA"))

def quiet_title(m) = 
    [("title","Nothing")]
end

quiet = map_metadata(quiet_title, blank())

def store_meta(room, m) =
    final_meta = list.append([("time", "#{time()}"), ("room", room)], m)
    meta_json = json_of(final_meta, compact=true)
    print("metadata: " ^ meta_json)

end

def decl_room(room, password) =
    live = input.harbor(
        room,
        id="live-input-" ^ room,
        port=input_port,
        password=password,
    )
    if storage_root != "" then
        ignore(output.file(
            %mp3.vbr(quality=0, id3v2=true),
            fallible=true,
            reopen_on_metadata=reopen_storage_on_metadata,
            reopen_delay=10.0,
            storage_root ^ "/" ^ room ^ "-%Y-%m-%d-%H-%M-%S.mp3",
            live,
        ))
    end
    radio = fallback(id="radio-" ^ room, track_sensitive=false, [live, quiet])
    radio = audio_to_stereo(radio)
    radio = on_metadata(store_meta(room), radio)
    cast_name = "Radio " ^ room
    # output.icecast(
    #     %mp3.abr(bitrate=128, min_bitrate=64, max_bitrate=192),
    #     name=cast_name,
    #     host=icecast_host,
    #     port=icecast_port,
    #     password=icecast_password,
    #     mount=room ^ ".mp3",
    #     radio
    # )
    output.icecast(
        %vorbis.abr(bitrate=128),
        name=cast_name,
        host=icecast_host,
        port=icecast_port,
        password=icecast_password,
        mount=room ^ ".ogg",
        radio
    )
end