SCRIPT_DIR="$( cd "$( dirname $(readlink -f "${BASH_SOURCE[0]}") )" &> /dev/null && pwd )"
cd $SCRIPT_DIR/..

rs="~/.config/remotesettigs"
if [ -d "$rs" ];
then
    cd $rs
    set +m
    git pull > /dev/null
    set -m
fi
