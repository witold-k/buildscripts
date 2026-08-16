add_to_path_if_exists() {
    local dirs=("$@")   # all arguments become an array

    for d in "${dirs[@]}"; do
        if [ -d "$d" ]; then
            if [[ ":$PATH:" != *":$d:"* ]]; then
                PATH="$d:$PATH"
            fi
        fi
    done
}

julia_inc=$(find ~/.julia -name julia.h)
if [ -f "$julia_inc" ]; then
    export JLRS_JULIA_DIR="$(dirname $(dirname $(dirname $julia_inc)))"
fi

my_dirs=(
    "$HOME/bin"
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    "$HOME/streams"
    "$HOME/svn/buildscripts/lua/bin"
    "$HOME/svn/buildscripts/python/bin"
    "$HOME/svn/buildscripts/bash"
    "$HOME/svn/buildscripts/bash/vcs"
    "/opt/anaconda3/bin"
    "/opt/rust/bin"
    "/opt/javac/bin"
    "/opt/julia/bin"
    "/opt/python/bin"
    "/opt/cide/native/wrapper/bin"
)

add_to_path_if_exists "${my_dirs[@]}"

cuda="/usr/local/cuda-13.1"
if [ -d "$cuda" ];
then
    export CUDA_HOME="$cuda"
    export PATH=$PATH:$CUDA_HOME/bin
fi

if [ -f $HOME/.local/bin/env ];
then
    source $HOME/.local/bin/env
fi

if [ -f "/etc/ssl/certs/ca-certificates.crt" ];
then
    export CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
    export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
fi

alias java21="export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64"
alias java25="export JAVA_HOME=/usr/lib/jvm/java-25-openjdk-amd64"

unset LD_LIBRARY_PATH
