class Sdcard:

    def __init__(self):
        self.data = None

    def scan(self):
        import subprocess
        import json

        cmd = "lsblk --json -o TYPE,NAME,PATH,MODEL,TRAN,UUID,MOUNTPOINT,SIZE,PARTTYPENAME,LABEL"
        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if p.stdout is not None:
            data = p.stdout.read()
            _ = p.wait()
            p.stdout.close()

            js = json.loads(data)
            self.data = js
        else:
            self.data = None

    @staticmethod
    def do_match(name):
        if name is None or name == "None":
            return False

        name_ok = ("ata" not in name) \
            and ("nvme" not in name) \
            and ("scsi" not in name) \
            and ("wwn" not in name) \
            or ("mmc" in name) \
            or ("usb" in name)
        if not name_ok:
            return False

        return True

    def select_all(self):
        if self.data is None:
            return None
        list = []
        bds = self.data['blockdevices']
        for bd in bds:
            name = str(bd['tran'])
            # childs = bd.get('children', None)
            size   = bd.get('size', None)
            if Sdcard.do_match(name) and (size is not None) and (size != "0B"):
                list.append(bd)

        if len(list) == 0:
            return None

        return list

    def get_selection_list(self):
        list = Sdcard.select_all(self)
        if list is None:
            return
        selects = []
        for bd in list:
            name = bd['name'] or ''
            tran = bd['tran'] or ''
            parttypename = bd['parttypename'] or ''
            model = bd['model'] or ''
            selects.append(name + ': ' + tran + ', ' + parttypename + ' (' + model + ')')
        return selects

    def is_unique(self):
        list = Sdcard.select_all(self)
        if list is None:
            return True
        else:
            return len(list) == 1

    def select_unique(self):
        import getpass
        list = Sdcard.select_all(self)
        if list is None:
            return None

        if len(list) > 1:
            print("ERROR: select_unique is not unique: " + str(list))
            return None

        if len(list) == 0:
            return None

        user = getpass.getuser()
        if user is None:
            user = 'unknown_user'

        partitions = []
        bd = list[0]
        childs = bd.get('children', None)
        if childs is None:
            mp = '/media/' + user + '/'
            if bd['label'] is not None:
                partitions.append(bd['path'])
                partitions.append(mp + bd['label'])
            elif bd['uuid'] is not None:
                partitions.append(bd['path'])
                partitions.append(mp + bd['uuid'])
            else:
                pass
        else:
            for child in childs:
                mp = '/media/' + getpass.getuser() + '/'
                if child['label'] is not None:
                    partitions.append(child['path'])
                    partitions.append(mp + child['label'])
                elif child['uuid'] is not None:
                    partitions.append(child['path'])
                    partitions.append(mp + child['uuid'])
                else:
                    pass

        return partitions

    def select_chosen(self, index):
        import getpass
        list = Sdcard.select_all(self)
        if list is None:
            return

        if len(list) == 0:
            return None

        user = getpass.getuser()
        if user is None:
            user = 'unknown_user'

        partitions = []
        bd = list[index]
        childs = bd['children']
        for child in childs:
            mp = '/media/' + user + '/'
            partitions.append(child['path'])
            partitions.append(mp + child['uuid'])

        return partitions

    def select_device(self, index):
        list = Sdcard.select_all(self)
        if list is None:
            return

        if len(list) == 0:
            return None

        return str(list[index]['path'])
