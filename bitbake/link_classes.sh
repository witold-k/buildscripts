SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CURRENT_DIR=$(pwd)

CLS=$(cd $SCRIPT_DIR/classes/ && ls *.bbclass)
for item in $CLS
do
    echo "$SCRIPT_DIR/classes/$item $item"
    ln -sfnr $SCRIPT_DIR/classes/$item $item
done

CLS=$(cd $SCRIPT_DIR/classes/ && ls *.py)
for item in $CLS
do
    echo "$SCRIPT_DIR/classes/$item $item"
    ln -sfnr $SCRIPT_DIR/classes/$item $item
done


