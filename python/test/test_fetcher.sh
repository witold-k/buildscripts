SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd $SCRIPT_DIR
mkdir -p testfetch

cd ../python/
echo "## FETCH"
python3 fetchercmd.py fetch  $SCRIPT_DIR/testfetch
echo "## SAVE"
python3 fetchercmd.py save   $SCRIPT_DIR/testfetch
echo "## UPDATE"
python3 fetchercmd.py update $SCRIPT_DIR/testfetch

