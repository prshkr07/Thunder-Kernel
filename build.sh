#!/bin/bash
set -e

version=1.00

clear

while :
do

	clear
	
	# If error exists, display it
	if [ "$ERR_MSG" != "" ]; then
		echo "$ERR_MSG"
		echo ""
	fi

  echo "======================================"
  echo "    Automatic Kernel Builder - AKB    "
  echo "            made by Suribi            "
  echo "    Thanks to Dr-Shadow and dsixda    "
  echo "======================================"
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

#Build phase
./makeMtk -o=TARGET_BUILD_VARIANT=user -t  $TARGET_PRODUCT n k
echo "Build Successful"

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
FLASHABLE_ZIP="$OUT_DIRECTORY/$TARGET_PRODUCT-3.4.67-ThunderKernel"
FLASHABLE_ZIP_2="$TARGET_PRODUCT-3.4.67-ThunderKernel"
echo "Creating flashable at '$FLASHABLE_ZIP'.zip"
pushd $OUT_DIRECTORY
zip -r -0 "$FLASHABLE_ZIP_2".zip .
popd
if [ ! -d "$CERTIFICATES_DIRECTORY" ]; then
echo "Warning ! We can't sign flashable.zip, you need to run ./certificates.sh"
else
java -jar $SCRIPTS_DIRECTORY/../signapk.jar $CERTIFICATES_DIRECTORY/certificate.pem $CERTIFICATES_DIRECTORY/key.pk8 "$FLASHABLE_ZIP".zip "$FLASHABLE_ZIP"-signed.zip
rm -r "$FLASHABLE_ZIP".zip $OUT_DIRECTORY/META-INF $OUT_DIRECTORY/boot.img
mv "$FLASHABLE_ZIP"-signed.zip "$FLASHABLE_ZIP".zip
fi
fi
fi
