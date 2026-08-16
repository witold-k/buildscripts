SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd $SCRIPT_DIR

sudo cp bitbake /etc/apparmor.d/bitbake
sudo systemctl daemon-reload
sudo systemctl reload apparmor.service

