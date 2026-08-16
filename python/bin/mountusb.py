#!/usr/bin/python3

import os
import sys

from pathlib import Path
path = Path(str(Path(__file__).resolve()) + '/../../lib').resolve()
sys.path.append(str(path))

import sdcard

sd = sdcard.Sdcard()
sd.scan()

sel = None
do_select_unique = len(sys.argv) > 1 and sys.argv[1] == '--unique'

if do_select_unique or sd.is_unique():
    sel = sd.select_unique()
else:
    choose_list = sd.get_selection_list()
    print("choose one of:")
    count = 0
    for entry in choose_list:
        count = count + 1
        print(str(count) + ": " + entry)
    selected = int(input("Enter a number: "))
    sel = sd.select_chosen(selected - 1)

if sel is not None:
    len = len(sel)
    for i in range(0, len, 2):
        dir = sel[i + 1]
        cmd = "udisksctl mount -b " + sel[i]
# for avoid password requests:
# https://wiki.archlinux.org/title/Polkit
# /etc/polkit-1/rules.d/49-nopasswd_global.rules
#
# /* Allow members of the wheel group to execute any actions
#  * without password authentication, similar to "sudo NOPASSWD:"
#  */
# polkit.addRule(function(action, subject) {
#     if (subject.isInGroup("wheel")) {
#         return polkit.Result.YES;
#     }
# });
        os.system(cmd)
#    for i in range(0, len, 2):
#        dir = sel[i + 1]
#        print(sel[i] + ': ' + dir)


# /etc/polkit-1/rules.d/10-allow-usb-mounts.rules
# polkit.addRule(function(action, subject) {
#   if (action.id == "org.freedesktop.udisks2.filesystem-mount-other-seat" && subject.isInGroup("groupforthosewhocanmountusbdisks")) {
#     var bus = action.lookup("drive.removable.bus");
#     if (bus == "usb" || bus == "firewire") {
#       polkit.log("polkit rule for mounting USB drives with udisks2")
#       polkit.log("Device: " + action.lookup("device"))
#       polkit.log("Drive: " + action.lookup("drive"))
#       polkit.log("Bus: " + bus)
#       polkit.log("Serial: " + action.lookup("drive.serial"))
#       polkit.log("Vendor: " + action.lookup("drive.vendor"))
#       polkit.log("Model: " + action.lookup("drive.model"))
#       return polkit.Result.YES;
#     }
#   }
# });
