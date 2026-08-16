# FIXME
#
# later: local install lua version could be used
#

if [ -f ~/.curlrc ];
then
    source ~/.curlrc
fi

if [ "$USER" != "root" ];
then
    echo "user is not root - executing as root"
    sudo bash $0 $proxy
    exit
fi

if [ ! -z "$2" ];
then
    proxy="$2"
fi
if [ ! -z "$proxy" ];
then
    export http_proxy="$proxy"
    export https_proxy="$proxy"
    export HTTP_PROXY="$proxy"
    export HTTPS_PROXY="$proxy"
fi


LUA=$(lua -v 2>&1)


# check for LuaFileSystem

# in case lua is a custom installation,
# not that one from the current linux distribution
LUA_VER=$(echo $LUA | awk '{print $2}')
LUA_VER2=$(echo $LUA_VER | awk -F '.' '{print $1 "." $2}')
LUA_DIR=$(readlink -m $(which lua)/../..)

apt install -y lua5.1 liblua5.1-0-dev lua5.4 liblua5.4-dev lua5.5 liblua5.5-dev luarocks sudo apt libyaml-dev libgraphviz-dev libleveldb-dev libsqlite3-dev

# LUA_INSTALL="luarocks --local --lua-version $LUA_VER2 --lua-dir $LUA_DIR install luafilesystem path"
echo $LUA_INSTALL
#$($LUA_INSTALL)

install_lua_all() {
    local versions=("5.1" "5.4")

    # Convert all arguments into an array so we can iterate safely
    local pkgs=("$@")

    for ver in "${versions[@]}"; do
        echo "====================================="
        echo "=== Installing rocks for Lua $ver ==="
        echo "====================================="

        local i=0
        while [ $i -lt ${#pkgs[@]} ]; do
            local pkg="${pkgs[$i]}"
            local next="${pkgs[$((i+1))]}"

            # Detect if the next argument is a flag (starts with --)
            local extra=""
            if [[ "$next" == --* ]]; then
                extra="$next"
                i=$((i+1))  # Skip the flag in the next loop
            fi

            echo "=== Installing $pkg $extra for Lua $ver ..."
            echo "luarocks --lua-version='$ver' install $pkg $extra"
            if ! luarocks --lua-version="$ver" install $pkg $extra; then
                echo "ERROR: Failed to install '$pkg' for Lua $ver" >&2
                exit 1
            fi

            echo "Successfully installed $pkg for Lua $ver"
            i=$((i+1))
        done
    done
}

install_lua() {
    local version="$1"
    shift

    for pkg in "$@"; do
        echo "Installing $pkg for Lua $version ..."
        if ! luarocks --lua-version=$version install "$pkg"; then
            echo "ERROR: Failed to install '$pkg' for Lua $version" >&2
            exit 1
        fi
    done
}

install_lua_all \
    argparse \
    dkjson \
    lsqlite3 \
    luasql-sqlite3 \
    xxhash --from=http://mah0x211.github.io/rocks/ \
    luafilesystem \
    luasystem \
    luv \
    path \
    penlight \
    toml \
    lyaml \
    lua-cjson \
    etlua \
    lua-resty-xxhash \
    luaposix \

