#!/data/user/0/com.termux/files/usr/bin/bash
# PeakCut Android APK Build Script
# Uses Android SDK tools inside Ubuntu proot-distro container

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================================="
echo "  Building PeakCut Android App (APK)                     "
echo "=========================================================="

# Run build pipeline inside Ubuntu container with Android SDK
proot-distro login ubuntu --bind "$REPO_ROOT":/root/PeakCut -- bash -c '
set -e
BUILD_DIR="/root/PeakCut/android_app"
ANDROID_JAR="/root/android-sdk/platforms/android-36/android.jar"
BUILD_TOOLS="/root/android-sdk/build-tools/36.0.0"
AAPT2="$BUILD_TOOLS/aapt2"
D8="$BUILD_TOOLS/d8"
APKSIGNER="$BUILD_TOOLS/apksigner"
ZIPALIGN="/usr/bin/zipalign"

cd "$BUILD_DIR"
rm -rf build
mkdir -p build/gen build/obj build/dex build/res_compiled

echo "[1/6] Compiling Android resources with AAPT2..."
$AAPT2 compile --dir res -o build/res_compiled/res.zip

echo "[2/6] Linking resources and generating R.java..."
$AAPT2 link -I "$ANDROID_JAR" \
    --manifest AndroidManifest.xml \
    -o build/unaligned.apk \
    --java build/gen \
    --auto-add-overlay \
    build/res_compiled/res.zip

echo "[3/6] Compiling Java source files with javac..."
javac -encoding UTF-8 -cp "$ANDROID_JAR" -d build/obj \
    build/gen/com/peakcut/app/R.java \
    src/com/peakcut/app/*.java

echo "[4/6] Converting bytecode to Dalvik Executable (classes.dex) with D8..."
$D8 --output build/dex/ --lib "$ANDROID_JAR" $(find build/obj -name "*.class")

cd build/dex
zip -uj ../unaligned.apk classes.dex
cd "$BUILD_DIR"

echo "[5/6] Aligning APK package with zipalign..."
$ZIPALIGN -f -p 4 build/unaligned.apk build/aligned.apk

KEYSTORE="/root/debug.keystore"
if [ ! -f "$KEYSTORE" ]; then
    echo "[INFO] Generating debug signing keystore..."
    keytool -genkeypair -v -keystore "$KEYSTORE" -alias androiddebugkey \
        -keyalg RSA -keysize 2048 -validity 10000 \
        -storepass android -keypass android \
        -dname "CN=Android Debug,O=Android,C=US"
fi

echo "[6/6] Signing APK with apksigner..."
$APKSIGNER sign --ks "$KEYSTORE" --ks-pass pass:android --key-pass pass:android \
    --out build/PeakCut.apk build/aligned.apk

$APKSIGNER verify build/PeakCut.apk
cp -f build/PeakCut.apk /root/PeakCut/data/PeakCut.apk
echo "[SUCCESS] PeakCut.apk built and verified successfully!"
'

# Copy final APK to user download folder
TARGET_APK="/sdcard/Download/PeakCut.apk"
if [ -d "/sdcard/Download" ]; then
    cp -f "$REPO_ROOT/data/PeakCut.apk" "$TARGET_APK"
    echo "=========================================================="
    echo "  APK SUCCESSFULLY PLACED IN DOWNLOAD FOLDER!            "
    echo "  Location: $TARGET_APK"
    echo "  Size: $(du -h "$TARGET_APK" | cut -f1)"
    echo "=========================================================="
else
    echo "[WARNING] /sdcard/Download not accessible. Saved to $REPO_ROOT/data/PeakCut.apk"
fi
