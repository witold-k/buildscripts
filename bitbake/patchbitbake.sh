SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PY_SCRIPTS_DIR=$SCRIPT_DIR/../python/bin
ENV_FILE=$1

env_vars=$(python3 $PY_SCRIPTS_DIR/get_config_environment.py $ENV_FILE)
eval $env_vars

echo "patchbitbake.sh: path in ${BITBAKE_ROOT}"

cd ${BITBAKE_ROOT}
if ! grep -q 'BBCLASSEXTENDCURR' lib/bb/parse/ast.py;
then
    git apply ${SCRIPT_DIR}/bitbake.diff
fi

PYD=$SCRIPT_DIR/../python/lib
echo "DIR=$PYD"
cd $PYD
PYS=$(find . -iname "*.c" -o -iname "*.py")
for item in $PYS
do
    if ! cmp -s $item $BITBAKE_ROOT/lib/$item;
    then
        echo "cp $(pwd)/$item $BITBAKE_ROOT/lib/$item"
        mkdir -p $(dirname $BITBAKE_ROOT/lib/$item)
        cp $item $BITBAKE_ROOT/lib/$item || exit
        DO_COMPILE=1
    fi
done

PYD=$SCRIPT_DIR/../bitbake
echo "DIR=$PYD"
cd $PYD
PYS=$(ls *.py)
for item in $PYS
do
    if ! cmp -s $item $BITBAKE_ROOT/lib/$item;
    then
        echo "cp $(pwd)/$item $BITBAKE_ROOT/lib/$item"
        cp $item $BITBAKE_ROOT/lib/$item || exit
        DO_COMPILE=1
    fi
done

