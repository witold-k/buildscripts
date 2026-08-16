#!/usr/bin/python3

import os
import sys

from pathlib import Path
path = Path(str(Path(__file__).resolve()) + '/../../lib').resolve()
sys.path.append(str(path))

import sdcard
import args

sd = sdcard.Sdcard()
sd.scan()

ag = args.Args(sys.argv)
do_select_unique = ag.remove_all('--unique') != 0
image            = ag.remove_start(1)
if not os.path.exists(image):
    raise Exception('file not found: ' + image)


if do_select_unique or sd.is_unique():
    sel = sd.select_device(0)
else:
    choose_list = sd.get_selection_list()
    print("choose one of:")
    count = 0
    for entry in choose_list:
        count = count + 1
        print(str(count) + ": " + entry)
    selected = int(input("Enter a number: "))
    sel = sd.select_device(selected - 1)

print(image + ' => ' + sel)

os.system('sudo sfdisk --list ' + sel)
os.system('sudo sfdisk --delete ' + sel)
os.system('sudo dcfldd bs=4M if=' + image + ' of=' + sel + ' status=progress')
os.system('sudo e2fsck -f ' + sel + '2')
os.system('sudo parted ' + sel + ' resizepart 2 100%')
os.system('sudo resize2fs ' + sel + '2')
os.system('sudo sync')
