#!/bin/bash
set -e

#AKB Version
version=1.03

#Variables
zImage_path=out/target/product/$TARGET_PRODUCT/obj/KERNEL_OBJ/arch/arm/boot/zImage
Config_path=mediatek/config/mt6582/autoconfig/kconfig/platform

#Calculate what version you are building. If this is your first build, it will show nothing in last version.
if [ "$(ls -A `pwd`/.numero)" ]; then
last_kversion=`cat .numero`
current_kversion=$(echo "scale=1; $last_kversion+0.1" | bc)
sed -i "s/_1.$last_version/_1.$current_kversion/" `pwd`/$Config_path
else
last_kversion=nothing
current_kversion=1.0
sed -i "s/_1.0.0/_1.$current_kversion/" `pwd`/$Config_path
fi

while :
do

	clear
	
	# If error exists, display it
	if [ "$ERR_MSG" != "" ]; then
		echo "$ERR_MSG"
		echo ""
	fi
  echo
  echo "Last version: $last_kversion"
  echo "Current version: $current_kversion"
  echo
  echo "========================================================"
  echo "             Automatic Kernel Builder - AKB             "
  echo "            made by Suribi - Copyright© 2014            "
  echo "             Thanks to Dr-Shadow and dsixda             "
  echo "========================================================"
  echo
  echo "Version: $version"
  echo
  echo "Select the product you want to build for:"
  echo
  echo "  1 - Bq Aquaris E5 HD"
  echo "  2 - Bq Aquaris E5 FHD"
  echo
  echo "  x - Exit"
  echo
  echo -n "Enter Option: "
  read opt

	case $opt in
		1) TARGET_PRODUCT=vegetahd; break;;
		2) TARGET_PRODUCT=krillin; break;;
		x) clear; echo; echo "Goodbye."; echo; exit 1;;
		*) ERR_MSG="Invalid option!"; clear;;
	esac
done

echo
echo "You are actualy building for $TARGET_PRODUCT"
echo

DATE_START=$(date +"%s")
BUILDVERSION=ThunderKernel-V$current_kversion-`date +%Y%m%d-%H%M`-$TARGET_PRODUCT

#Build phase
./makeMtk -o=TARGET_BUILD_VARIANT=user -t  $TARGET_PRODUCT n k

if [ "$(ls -A `pwd`/$zImage_path)" ]; then
echo "Build Successful"
else
while [ ! -d "`pwd`/$zImage_path" ]; do
	clear
	echo "========================================================"
	echo "       Oh no, there where some code errors :(           "
	echo "   Now you must find and solve them, then press b       "
	echo "========================================================"
	echo
	echo " b - Build again"
	echo " x - exit"
	echo
	echo -n "Enter option: "
	read option
	
	case $option in
		b) ./makeMtk -o=TARGET_BUILD_VARIANT=user -t  $TARGET_PRODUCT n k; break;;
		x) clear; echo; echo "Goodbye."; echo; exit 1;;
		*) ERR_MSG="Invalid option!"; clear;;
	esac
done
fi

#Create vars for OUT, SCRIPTS and RAMDISK directories
OUT_DIRECTORY=~/out/$TARGET_PRODUCT
RAMDISK_DIRECTORY=ramdisk/$TARGET_PRODUCT
SCRIPTS_DIRECTORY=scripts/$TARGET_PRODUCT
CERTIFICATES_DIRECTORY=~/.certificates
BOOT_PATH=repack/BOOT-EXTRACTED

#Create and clean out directory for your device & create BOOT_EXTRACTED folder
mkdir -p $BOOT_PATH
mkdir -p $OUT_DIRECTORY
if [ "$(ls -A $OUT_DIRECTORY)" ]; then
rm $OUT_DIRECTORY/* -R
fi

echo
echo "Copying zImage to repack boot.img..."
cp out/target/product/$TARGET_PRODUCT/obj/KERNEL_OBJ/arch/arm/boot/zImage $BOOT_PATH/zImage

#Repack part
if [ -d "$RAMDISK_DIRECTORY" ]; then
echo "Repacking boot.img with new zImage"
cp -r $RAMDISK_DIRECTORY $BOOT_PATH/boot.img-ramdisk
cd repack
scripts/build_boot_img
cd ..
cp repack/WORKING/boot.img $OUT_DIRECTORY/boot.img
rm -r $BOOT_PATH

#Flashable zip build
if [ -d "$SCRIPTS_DIRECTORY" ]; then
echo "Repacking boot.img with new zImage"
cp $SCRIPTS_DIRECTORY/* $OUT_DIRECTORY -R
FLASHABLE_ZIP="$OUT_DIRECTORY/$BUILDVERSION"
FLASHABLE_ZIP_2="$BUILDVERSION"
echo "Creating flashable at '$FLASHABLE_ZIP'.zip"
pushd $OUT_DIRECTORY
zip -r -0 "$FLASHABLE_ZIP_2".zip .
popd
if [ ! -d "$CERTIFICATES_DIRECTORY" ]; then

while :
do
clean
echo "=========================================================================="
echo " Warning ! We can't sign flashable.zip, you need to run ./certificates.sh"
echo "          Now we will run it automatically if you press r:"
echo "=========================================================================="
echo
echo " r: run ./certificates.sh (RECOMMENDED)"
echo " x: exit, I will run it later."
echo
echo -n "Enter Option: "
  read opt

	case $opt in
		r) clear; ./kernel/certificates.sh; break;;
		x) clear; echo; echo "Goodbye."; echo; exit 1;;
		*) ERR_MSG="Invalid option!"; clear;;
	esac
done

clear
echo
echo "Now you have .certificates folder and we can continue"
echo
java -jar $SCRIPTS_DIRECTORY/../signapk.jar $CERTIFICATES_DIRECTORY/certificate.pem $CERTIFICATES_DIRECTORY/key.pk8 "$FLASHABLE_ZIP".zip "$FLASHABLE_ZIP"-signed.zip
rm -r "$FLASHABLE_ZIP".zip $OUT_DIRECTORY/META-INF $OUT_DIRECTORY/boot.img
mv "$FLASHABLE_ZIP"-signed.zip "$FLASHABLE_ZIP".zip

else
java -jar $SCRIPTS_DIRECTORY/../signapk.jar $CERTIFICATES_DIRECTORY/certificate.pem $CERTIFICATES_DIRECTORY/key.pk8 "$FLASHABLE_ZIP".zip "$FLASHABLE_ZIP"-signed.zip
rm -r "$FLASHABLE_ZIP".zip $OUT_DIRECTORY/META-INF $OUT_DIRECTORY/boot.img
mv "$FLASHABLE_ZIP"-signed.zip "$FLASHABLE_ZIP".zip
fi
fi
fi

DATE_END=$(date +"%s")
echo
echo
DIFF=$(($DATE_END - $DATE_START))
echo "Last version: $last_kversion"
echo "Current version: $current_kversion"

#Now it's time to export current version
echo "$current_kversion" > .numero

echo
echo
echo "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
