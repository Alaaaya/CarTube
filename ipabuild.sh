#!/bin/bash

set -e

# إعداد المتغيرات الأساسية
cd "$(dirname "$0")"
WORKING_LOCATION="$(pwd)"
APPLICATION_NAME=CarTube
CONFIGURATION=Debug

echo "Starting build process for $APPLICATION_NAME on iOS 16.5 with TrollStore support."

# إنشاء مجلد البناء إذا لم يكن موجودًا
if [ ! -d "build" ]; then
    mkdir build
fi
cd build

# إزالة أي ملف IPA قديم
if [ -e "$APPLICATION_NAME.ipa" ]; then
    rm $APPLICATION_NAME.ipa
fi

# بناء التطبيق بصيغة .app
xcodebuild -project "$WORKING_LOCATION/$APPLICATION_NAME.xcodeproj" \
    -scheme $APPLICATION_NAME \
    -configuration $CONFIGURATION \
    -derivedDataPath "$WORKING_LOCATION/build/DerivedData" \
    -destination 'generic/platform=iOS' \
    ONLY_ACTIVE_ARCH="NO" \
    CODE_SIGNING_ALLOWED="NO" \
    IPHONEOS_DEPLOYMENT_TARGET="16.5"

# تحديد مسارات التطبيق
DD_APP_PATH="$WORKING_LOCATION/build/DerivedData/Build/Products/$CONFIGURATION-iphoneos/$APPLICATION_NAME.app"
TARGET_APP="$WORKING_LOCATION/build/$APPLICATION_NAME.app"
cp -r "$DD_APP_PATH" "$TARGET_APP"

# إزالة التوقيع
codesign --remove "$TARGET_APP"
if [ -e "$TARGET_APP/_CodeSignature" ]; then
    rm -rf "$TARGET_APP/_CodeSignature"
fi
if [ -e "$TARGET_APP/embedded.mobileprovision" ]; then
    rm -rf "$TARGET_APP/embedded.mobileprovision"
fi

# إضافة الصلاحيات (Entitlements)
echo "Adding entitlements for TrollStore support."
ENTITLEMENTS_FILE="$WORKING_LOCATION/$APPLICATION_NAME/$APPLICATION_NAME.entitlements"
if [ ! -e "$ENTITLEMENTS_FILE" ]; then
    echo "Error: Entitlements file not found at $ENTITLEMENTS_FILE"
    exit 1
fi
ldid -S"$ENTITLEMENTS_FILE" "$TARGET_APP/$APPLICATION_NAME"

# إنشاء ملف IPA
echo "Packaging the app into an IPA file."
rm -rf Payload
mkdir Payload
cp -r $APPLICATION_NAME.app Payload/$APPLICATION_NAME.app
zip -vr $APPLICATION_NAME.ipa Payload
rm -rf $APPLICATION_NAME.app
rm -rf Payload

echo "Build process completed. $APPLICATION_NAME.ipa is ready for TrollStore installation."
