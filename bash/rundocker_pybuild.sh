RUN_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PY_SCRIPTS_DIR=$RUN_SCRIPT_DIR/../python/bin
PROJECT_DIR=$1
cd $PROJECT_DIR

env_vars=$(python3 $PY_SCRIPTS_DIR/get_config_environment.py $PROJECT_DIR/config/environment.json)
eval $env_vars

# PYTHON is not working properly yet
unset PYTHON_BIN

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

if [ ! -z "$PYTHON_BIN" ];
then
    echo "export PYTHON_BIN=$PYTHON_BIN"
    echo "export PYTHONHOME=$PYTHONHOME"
    echo "export PYTHONPATH=$PYTHONPATH"
    MOUNT_PYTHON="-e PYTHON_BIN=$PYTHON_BIN -e PYTHONHOME=$PYTHONHOME -e PYTHONPATH=$PYTHONPATH"
else
    export PYTHON_BIN=/usr/bin/python3
fi

HOME_USER=$HOME
if [ -d /data ];
then
    DATA_USER=/data
    MOUNT_DATA="-v $DATA_USER:/data"
fi

MOUNT_HOME="--mount type=bind,src=$HOME_USER,target=/home/$USER"

if [ -z "$USER" ];
then
    USER=$(id -un)
fi

if [ -z "${RUNDOCKER_OPT_COMPILER_ONLY}" ];
then
    MOUNT_OPT="-v /opt:/opt $MOUNT_DATA"
else
    mkdir -p /opt/compiler
    mkdir -p /opt/rust
    map rust
    map compiler
    map buildsystems
    map_find "cuda-*"
    map_find "gcc-12*"
    MOUNT_OPT="$MOUNT_OPT $MOUNT_DATA"
fi

echo "MOUNT_OPT: $MOUNT_OPT"

if grep -q CONFIG_IDMAPPED_MOUNTS /boot/config-$(uname -r);
then
    KEEP_USERNS="--userns=keep-id"
else
    KEEP_USERNS="--userns=keep-id"
    #KEEP_USERNS="--userns=host"
    #IDMAP="--uidmap 0:1000:1 --gidmap 0:1000:1"
fi
#USER_LOGIN="--user $USER:$USER -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro" # does not work
#DEBUG_SWITCH="--log-level=debug"

if [ "$FOUND_GITLAB" == "True" ];
then

# ============================================================================
# run in gitlab
# ============================================================================

CMD="podman run --init --rm $KEEP_USERNS \
    $MOUNT_HOME \
    $MOUNT_PYTHON \
    $USER_LOGIN \
    -e SHELL=bash \
    -e SYSTEM_UID=$UID \
    -e SYSTEM_NAME=$USER \
    -e SYSTEM_HOME=/home/$USER \
    -e LOGIN_DIR=$PROJECT_ROOT \
    $DOCKER_IMAGE \
    $PYTHON_BIN \"$PY_SCRIPTS_DIR/build.py $2 $3 $4 $5 $6\""
#echo $CMD
eval $CMD

exit
fi

# ============================================================================
# run local - special tasks
# ============================================================================

if [ "shell" == "$2" ];
then

CMD="podman $DEBUG_SWITCH run --init --rm -it $KEEP_USERNS \
    -e SHELL=bash \
    -e SYSTEM_HOME=$HOME \
    -e SYSTEM_NAME=$USER \
    -e SYSTEM_UID=$UID \
    $IDMAP \
    $USER_LOGIN \
    $MOUNT_HOME \
    $MOUNT_PYTHON \
    $MOUNT_OPT \
    -w $PROJECT_DIR \
    $DOCKER_IMAGE \
    \"cd $PROJECT_DIR && bash\""
echo $CMD
eval $CMD
exit

fi

if [ "dshell" == "$2" ];
then

CMD="time podman --log-level=debug run --init --rm -it $KEEP_USERNS \
    -e SHELL=bash \
    -e SYSTEM_HOME=$HOME \
    -e SYSTEM_NAME=$USER \
    -e SYSTEM_UID=$UID \
    $IDMAP \
    $USER_LOGIN \
    $MOUNT_HOME \
    $MOUNT_PYTHON \
    $MOUNT_OPT \
    -w $PROJECT_DIR \
    $DOCKER_IMAGE \
    \"cd $PROJECT_DIR && bash\""
echo $CMD
eval $CMD
exit

fi

if [ "root" == "$2" ];
then

CMD="podman $DEBUG_SWITCH run --init --rm -it $KEEP_USERNS \
    -e SHELL=bash \
    -e KEEP_ROOT=1 \
    -e SYSTEM_HOME=$HOME \
    -e SYSTEM_NAME=$USER \
    -e SYSTEM_UID=$UID \
    $IDMAP \
    $USER_LOGIN \
    $MOUNT_HOME \
    $MOUNT_PYTHON \
    $MOUNT_OPT \
    -w $PROJECT_DIR \
    $DOCKER_IMAGE \
    \"bash\""
echo $CMD
eval $CMD
exit

fi

# ============================================================================
# run local - scripts
# ============================================================================

if [ -f ~/.ignoredocker ] || [ -f /.dockerenv ] || [ "$OSTYPE" = "msys" ] || [ "$OSTYPE" = "cygwin" ] || [ ! -z "$IGNORE_DOCKER" ];
then
# running already in an podman container
#echo "## RUN PLAIN"
cd $PROJECT_DIR
$PYTHON_BIN $PY_SCRIPTS_DIR/build.py $2 $3 $4 $5 $6

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

CMD="podman run --init --rm -it $KEEP_USERNS \
    -e SHELL=bash \
    -e SYSTEM_HOME=$HOME \
    -e SYSTEM_NAME=$USER \
    -e SYSTEM_UID=$UID \
    $USER_LOGIN \
    $MOUNT_HOME \
    $MOUNT_PYTHON \
    $MOUNT_OPT \
    -w $PROJECT_DIR \
    $DOCKER_IMAGE \
    \"cd $PROJECT_DIR && $PYTHON_BIN $PY_SCRIPTS_DIR/build.py $2 $3 $4 $5 $6\""
eval $CMD

fi

