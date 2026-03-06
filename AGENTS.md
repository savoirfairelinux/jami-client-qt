# Jami Qt client

Jami is an open-source peer-to-peer communication tool that allows users to make voice and video calls, send messages, and share files. It is designed to be secure, private, and fully distributed. It is written in C++20.

The Jami Qt client is a cross-platform UI for Jami that runs on Linux, macOS, and Windows.

# Building

From `build/`:
```bash
cmake .. -GNinja
ninja
```

# Running

From `build/`:
```bash
./jami -d
```

# Commit message format

{scope}: {subject}

# Daemon dependencies

libjami-core (the daemon) uses the "contrib" system to manage its dependencies, which are built in `daemon/contrib/build-{arch}` and installed in `daemon/contrib/{arch}`.
Contribs are built by CMake when configuring the project, but they can also be built manually by running `make .{contrib-name}` from the contrib build directory.
Key dependencies include:
- `opendht`: The kademlia DHT implementation.
- `dhtnet`: Used to establish TLS peer-to-peer connections using the opendht and ICE.
- `pjproject`: Jami and dhtnet use a fork of pjproject implementing TCP-ICE (rfc6544) to establish peer-to-peer TCP connections, and for SIP support used for calls and conferences in Jami.
- `ffmpeg`: Used for media processing, including encoding and decoding of audio and video streams.
