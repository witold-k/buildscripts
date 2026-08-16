SCRIPT_DIR="$( cd "$( dirname $(readlink -f "${BASH_SOURCE[0]}") )" &> /dev/null && pwd )"

if ! grep -q "$SCRIPT_DIR/paths.sh" ~/.profile; then
    echo ". $SCRIPT_DIR/paths.sh" >> ~/.profile
fi
if ! grep -q "$SCRIPT_DIR/cleanup.sh" ~/.profile; then
    echo ". $SCRIPT_DIR/cleanup.sh" >> ~/.profile
fi
if ! grep -q "$SCRIPT_DIR/sync.sh & disown" ~/.profile; then
    echo ". $SCRIPT_DIR/sync.sh & disown" >> ~/.profile
fi

if ! grep -q "$SCRIPT_DIR/paths.sh" ~/.bashrc; then
    echo ". $SCRIPT_DIR/paths.sh" >> ~/.bashrc
fi
if ! grep -q "$SCRIPT_DIR/cleanup.sh" ~/.bashrc; then
    echo ". $SCRIPT_DIR/cleanup.sh" >> ~/.bashrc
fi
if ! grep -q "$SCRIPT_DIR/sync.sh & disown" ~/.bashrc; then
    echo ". $SCRIPT_DIR/sync.sh & disown" >> ~/.bashrc
fi

if [ ! -f /etc/sudoers.d/$USER-sudo ]; then

sudo tee /etc/sudoers.d/$USER-sudo >/dev/null << EOF
$USER ALL=(ALL) SETENV: /sbin/chroot
$USER ALL=(ALL) NOPASSWD: /sbin/chroot, /sbin/poweroff, /sbin/reboot, /sbin/shutdown, /usr/bin/apt
EOF

fi

