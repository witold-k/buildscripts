tmux list-panes -a -F '#{pane_id} #{pane_current_command}' | grep "$1" | awk '{print $1}'
