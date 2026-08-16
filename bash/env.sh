if [ -z $1 ];
then
    dir=/opt/rootfs
else
    dir=$1
fi
mkdir -p $dir

dir=$dir/crosstool-ng-buildsystem:1
if [ ! -d $dir ];
then
    mkdir $dir
    tar -xf /data/podman_tmp/crosstool-ng-buildsystem:1.tar -C $dir
fi

if [ ! -d $dir/home/$USER ];
then
    sudo mkdir -p $dir/home
    sudo mkdir $dir/home/$USER
    sudo chown $USER:$USER $dir/home/$USER
fi

if [ ! -d ${dir}/opt ];
then
    sudo mkdir -p $dir/opt
fi

#if [ -d ${dir}/etc ];
#then
#    sudo mount -o ro --bind /etc  ${dir}/etc
#fi

if [ ! -d ${dir}/dev ];
then
    sudo mkdir $dir/dev
fi

if [ ! -d ${dir}/dev/shm ];
then
    sudo mkdir $dir/dev/shm
fi

if [ ! -d ${dir}/proc ];
then
    sudo mkdir $dir/proc
fi

sudo mknod -m 666 ${dir}/dev/null c 1 3
#sudo mount -o ro --bind /dev  ${dir}/dev
sudo mount --bind /dev/shm    ${dir}/dev/shm
sudo mount --bind /dev/null   ${dir}/dev/null
sudo mount --bind /opt        ${dir}/opt

USERID=$(id -u)

if [ ! -d ${dir}/home/${USER}_loc ];
then
    sudo mkdir -p ${dir}/home/${USER}_loc
    sudo chown $USERID:$USERID ${dir}/home/${USER}_loc
fi

if ! grep -q $USER ${dir}/etc/passwd;
then
    sudo chroot --userspec=$USER:$USER ${dir} userdel $USERID
    echo "$USER:x:$USERID:$USERID:$USER:/home/${USER}_loc:/bin/bash" | sudo tee -a ${dir}/etc/passwd > /dev/null
fi

if ! grep -q $USER ${dir}/etc/shadow;
then
    echo "$USER:!:20195:0:99999:7:::" | sudo tee -a ${dir}/etc/shadow > /dev/null
fi

if ! grep -q $USER ${dir}/etc/group;
then
    echo "$USER:x:$USERID:" | sudo tee -a ${dir}/etc/group > /dev/null
fi

if [ ! -d ${dir}/home/$USER/.ssh ];
then
    sudo mount --bind /home/$USER ${dir}/home/$USER
fi

sudo env HOME=/home/${USER}_loc chroot --userspec=$USER:$USER ${dir}

