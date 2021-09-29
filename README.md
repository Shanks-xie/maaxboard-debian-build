# Debian build script


## board config

## Prepare Environment
``` bash
$ sudo apt-get install gawk wget git unzip kpartx lvm2 dosfstools gpart binutils net-tools -y
$ sudo apt-get install build-essential binfmt-support qemu qemu-user-static debootstrap -y
```

## Run
sudo ./debian_build.sh -b [all/rootfs/uboot/linux] -f [board.ini]

```bash
sudo ./debian_build.sh -b all -f board/maaxboard/maaxboard-lite.ini 
```

## Fetures
- [x] <b>Maaxboard lite</b>   
- [ ] <b>Maaxboard</b>  &nbsp;&nbsp; *Not test*
- [ ] <b>Maaxboard Mini lite</b>  &nbsp;&nbsp; *unfinished*
- [ ] <b>Maaxboard Mini</b>  &nbsp;&nbsp; *unfinished*

## Some issues
1. chroot: failed to run command '/debootstrap/debootstrap': Exec format error
```bash
# update-binfmts --enable
```
