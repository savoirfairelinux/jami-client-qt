#!/bin/sh

set -eu

# Rust is required to build the yffi (Y-CRDT) contrib package used by the
# collaborative editing feature.
RUST_VERSION=1.96.0

# Keep the compiler tree read-only for build users. Cargo's writable registry
# cache and lock file live outside the toolchain and PATH, in a shared directory
# protected by the sticky bit.
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | CARGO_HOME=/usr/local/cargo sh -s -- \
        -y --profile minimal --default-toolchain "$RUST_VERSION"
chmod -R a+rX /usr/local/rustup /usr/local/cargo
install -d -m 1777 /var/cache/cargo

# Some builds run through sudo, whose secure_path can override PATH. Keep the
# compiler reachable through /usr/local/bin in that case.
ln -s /usr/local/cargo/bin/cargo /usr/local/cargo/bin/rustc /usr/local/bin/