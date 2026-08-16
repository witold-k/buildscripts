RUN_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PY_SCRIPTS_DIR=$RUN_SCRIPT_DIR/../python/bin
PROJECT_DIR=$1
cd $PROJECT_DIR

env_vars=$(python3 $PY_SCRIPTS_DIR/get_config_environment.py $PROJECT_DIR/config/environment.json)
eval $env_vars

map() {
    path=$1
    if [ -d /opt/$path ]; then
        MOUNT_OPT="$MOUNT_OPT -v /opt/$path:/opt/$path"
    fi
    if [ -d /usr/local/$path ]; then
        MOUNT_OPT="$MOUNT_OPT -v /usr/local/$path:/usr/local/$path"
    fi
}

map_find() {
    path="$1"

    # Search in /opt
    for dir in $(find /opt -maxdepth 1 -type d -name "$path" 2>/dev/null); do
        MOUNT_OPT="$MOUNT_OPT -v $dir:$dir"
    done

    # Search in /usr/local
    for dir in $(find /usr/local -maxdepth 1 -type d -name "$path" 2>/dev/null); do
        MOUNT_OPT="$MOUNT_OPT -v $dir:$dir"
    done
}

HOME_USER=$HOME
if [ -d /data ];
then
    DATA_USER=/data
    DATA_MOUNT="-v ${DATA_USER}:/data"
fi

if [ -z "${RUNDOCKER_OPT_COMPILER_ONLY}" ];
then
    MOUNT_OPT="-v /opt:/opt $DATA_MOUNT"
else
    mkdir -p /opt/compiler
    mkdir -p /opt/rust
    map rust
    map compiler
    map buildsystems
    map_find "cuda-*"
    map_find "gcc-12*"
    MOUNT_OPT="$MOUNT_OPT $DATA_MOUNT"
fi

echo "MOUNT_OPT: $MOUNT_OPT"

if grep -q CONFIG_IDMAPPED_MOUNTS /boot/config-$(uname -r);
then
    KEEP_USERNS="--userns=keep-id"
else
    KEEP_USERNS="--userns=keep-id"
#    KEEP_USERNS="--userns=host"
fi
#USER_LOGIN="--user $USER:$USER -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro" # does not work
#DEBUG_SWITCH="--log-level=debug"

if [ "$FOUND_GITLAB" == "True" ];
then

# ============================================================================
# run in gitlab
# ============================================================================

podman run --init --rm $KEEP_USERNS \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $HOME_USER:/home/$USER \
    $MOUNT_OPT \
    -e SHELL=bash \
    -e SYSTEM_UID=$UID \
    -e SYSTEM_NAME=$USER \
    -e SYSTEM_HOME=/home/$USER \
    -e LOGIN_DIR=$PROJECT_ROOT \
    $DOCKER_IMAGE \
    "cd $PROJECT_DIR && $PROJECT_DIR/scripts/${2}.sh $3 $4 $5 $6 $7"

exit
fi

# ============================================================================
# run local - special tasks
# ============================================================================

if [ "shell" == "$2" ];
then

CMD="podman run --init --rm $KEEP_USERNS -it \
    -e SHELL=bash \
    -e SYSTEM_HOME=$HOME \
    -e SYSTEM_NAME=$USER \
    -e SYSTEM_UID=$UID \
    -v $HOME_USER:$HOME \
    $MOUNT_OPT \
    -w $PROJECT_DIR \
    $DOCKER_IMAGE \
    \"cd $PROJECT_DIR && bash\""
echo $CMD
eval $CMD

exit

fi

# ============================================================================
# run local - scripts
# ============================================================================

if [ -f /.dockerenv ] || [ "$OSTYPE" = "msys" ] || [ "$OSTYPE" = "cygwin" ] || [ ! -z "$IGNORE_DOCKER" ];
then
cd $PROJECT_DIR
scripts/${2}.sh $3 $4 $5 $6 $7

else

if [ -z $HOME_USER ];
then
    echo "HOME_USER not set"
    exit
fi
if [ -z $DOCKER_IMAGE ];
then
    echo "DOCKER_IMAGE not set"
    exit
fi

CMD="podman run --init --rm $KEEP_USERNS -it \
    -e SHELL=bash \
    -e SYSTEM_HOME=$HOME \
    -e SYSTEM_NAME=$USER \
    -e SYSTEM_UID=$UID \
    -v $HOME_USER:$HOME \
    $MOUNT_OPT \
    -w $PROJECT_DIR \
    $DOCKER_IMAGE \
    \"cd $PROJECT_DIR && scripts/${2}.sh $3 $4 $5 $6\""

echo $CMD
time eval $CMD

fi

