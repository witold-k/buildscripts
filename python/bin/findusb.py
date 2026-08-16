#!/usr/bin/python3

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
    if choose_list is not None:
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
        print(sel[i])
