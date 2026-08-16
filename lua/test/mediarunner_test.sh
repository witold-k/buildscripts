SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $SCRIPT_DIR/..
if [ -f bin/mediarunner ]; then
    bin/mediarunner bash .. ../..
else
    mediarunner bash .. ../..
fi
