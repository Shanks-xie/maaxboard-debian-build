#!/bin/bash

# ARM_GCC_VERSION=9.2
# if [ "${ARM_GCC_VERSION}" == "7.3" ] ; then
# TOOLCHAIN_PATH=$HOME/toolchain/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin
# export PATH=$TOOLCHAIN_PATH:$PATH
# export ARCH=arm64
# export CROSS_COMPILE=aarch64-linux-gnu-
# else
# ## gcc 9.2 default
# TOOLCHAIN_PATH=$HOME/toolchain/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu/bin
# export PATH=$TOOLCHAIN_PATH:$PATH
# export ARCH=arm64
# export CROSS_COMPILE=aarch64-none-linux-gnu- 
# fi

# check required applications are installed
command -v dtc >/dev/null 2>&1 || { echo "ERROR: Cannot find dtc, run 'sudo apt install device-tree-compiler' please"; exit; }
command -v ${CROSS_COMPILE}gcc >/dev/null 2>&1 || { cat <<  EEOF
ERROR: ${CROSS_COMPILE}gcc not found,

please install the toolchain first
and export the enviroment like "export PATH=\$PATH:your_toolchain_path" 

EEOF
exit;}

#------------------------------------------------------------------------------
help() {
bn=`basename $0`
cat << EOF

usage :  $bn <option>

options:
  -h        display this help and exit
  -mx8m     build u-boot.imx for the EM-MC-SBC-IMX8M baord
  -mini     build u-boot.imx for the MaaXBoard mini baord
  -nano     build u-boot.imx for the MaaXBoard nano baord
  -clean    clean the build files for all projects

Example:
    ./$bn -mx8m
    ./$bn -mini
    ./$bn -nano

EOF
}

SOC_TYPE="mx8m"
WORKPWD=$(pwd)

mk_clean()
{
    cd $WORKPWD
    make clean -C  imx-atf/
    make clean -C imx-mkimage/
    (cd imx-mkimage/ && git clean -f -d)
    make distclean -C uboot-imx/
    rm u-boot*.imx
}

[ $# -eq 0 ] && help && exit
while [ $# -gt 0 ]; do
    case $1 in
        -h) help; exit ;;
        -mx8m) echo ${SOC_TYPE};;
        -mini) SOC_TYPE="mx8m_mini"; echo ${SOC_TYPE};;
        -nano) SOC_TYPE="mx8m_nano"; echo ${SOC_TYPE};;
        -cl*)  mk_clean ; exit ;;
        *)  echo "-- invalid option -- "; help; exit;;
    esac
    shift
done

mk_uboot()
{
    cd uboot-imx/
    if [ "${SOC_TYPE}" == "mx8m_mini" ] ; then
        make maaxboard_mini_defconfig
    elif [ "${SOC_TYPE}" == "mx8m_nano" ] ; then
        make maaxboard_nano_defconfig
    else
        make maaxboard_defconfig
    fi
    make -j4

    cd $WORKPWD
}

IMX_FW_NAME="firmware-imx-8.8"
mk_firmware()
{
    cd $WORKPWD
    [ -e ${IMX_FW_NAME}/firmware/sdma/sdma-imx7d.bin ] && return
    echo unpack ${IMX_FW_NAME}.bin
    ./${IMX_FW_NAME}.bin
}

mk_atf()
{
    cd imx-atf/
    case ${SOC_TYPE} in
        mx8m)      echo "build atf for imx8mq"; make PLAT=imx8mq bl31;;
        mx8m_mini) echo "build atf for imx8mm"; make PLAT=imx8mm bl31;;
        mx8m_nano) echo "build atf for imx8mn"; make PLAT=imx8mn bl31;;
    esac
    cd $WORKPWD
}

mk_imxboot()
{
    cp ${IMX_FW_NAME}/firmware/ddr/synopsys/ddr4*.bin imx-mkimage/iMX8M
    cp uboot-imx/tools/mkimage imx-mkimage/iMX8M/mkimage_uboot
    cp uboot-imx/u-boot-nodtb.bin imx-mkimage/iMX8M/
    cp uboot-imx/spl/u-boot-spl.bin imx-mkimage/iMX8M/

    if [ "${SOC_TYPE}" == "mx8m_mini" ] ; then
        cp imx-atf/build/imx8mm/release/bl31.bin imx-mkimage/iMX8M/bl31.bin
        cp uboot-imx/arch/arm/dts/maaxboard-mini.dtb imx-mkimage/iMX8M/imx8mm-ddr4-evk.dtb
        cd imx-mkimage/
        make SOC=iMX8MM flash_ddr4_evk
    elif [ "${SOC_TYPE}" == "mx8m_nano" ] ; then
        cp imx-atf/build/imx8mn/release/bl31.bin imx-mkimage/iMX8M/bl31.bin
        cp uboot-imx/arch/arm/dts/maaxboard-nano-mipi.dtb imx-mkimage/iMX8M/imx8mn-ddr4-evk.dtb
        cd imx-mkimage/
        make SOC=iMX8MN flash_ddr4_evk
    else
        cp ${IMX_FW_NAME}/firmware/hdmi/cadence/signed_hdmi_imx8m.bin imx-mkimage/iMX8M
        cp imx-atf/build/imx8mq/release/bl31.bin imx-mkimage/iMX8M/bl31.bin
        cp uboot-imx/arch/arm/dts/maaxboard.dtb imx-mkimage/iMX8M/imx8mq-ddr4-val.dtb
        cd imx-mkimage/
        make SOC=iMX8M flash_ddr4_val
    fi

    cd $WORKPWD
}


## main loop ###
cd $WORKPWD
mk_uboot
mk_firmware
mk_atf
mk_imxboot

# cp -f imx-mkimage/iMX8M/flash.bin  ./u-boot-${SOC_TYPE}.imx
cp -f imx-mkimage/iMX8M/flash.bin u-boot.imx
echo ""
echo "---Finished--- the boot image is u-boot-${SOC_TYPE}.imx"

exit
