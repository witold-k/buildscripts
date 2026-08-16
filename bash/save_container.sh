if [ -z $1 ];
then
    echo "specify image name"
    exit 1
fi

if [ -z $2 ];
then
    echo "specify destination dir"
    exit 1
fi

image=$(basename $1)
dest=$2

excludes="\
--exclude=/save --exclude=/data --exclude=/opt --exclude=/media --exclude=/home --exclude=/root --exclude=/proc --exclude=/sys --exclude=/dev --exclude=/run \
"

tarcmd="tar czf /save/${image}.tar $excludes /"
echo $tarcmd
podman run -e KEEP_ROOT=1 -v $dest:/save $1 "$tarcmd"

