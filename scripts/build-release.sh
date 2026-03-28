#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION=$(grep 'MARKETING_VERSION' "$PROJECT_DIR/project.yml" | awk '{print $2}' | tr -d '"')
APP_NAME="ProfileNavigator"
SCHEME="ProfileNavigator"
ARCHIVE_PATH="$PROJECT_DIR/build/$APP_NAME.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/export"
DMG_PATH="$PROJECT_DIR/build/$APP_NAME-$VERSION.dmg"
SIGNED=${SIGNED:-false}  # Set SIGNED=true once Developer ID is available

echo "==> Building $APP_NAME v$VERSION"

# Clean
rm -rf "$PROJECT_DIR/build"
mkdir -p "$PROJECT_DIR/build"

# Regenerate xcodeproj so MARKETING_VERSION and other settings are picked up
xcodegen generate --spec "$PROJECT_DIR/project.yml" --quiet

# Archive
xcodebuild archive \
  -project "$PROJECT_DIR/ProfileNavigator.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_STYLE=Automatic \
  | grep -E "^(error:|warning:|Build succeeded|Build FAILED|===)" || true

mkdir -p "$EXPORT_PATH"

if [ "$SIGNED" = "true" ]; then
  # Export with Developer ID signing (requires Apple Developer membership)
  EXPORT_OPTIONS="$PROJECT_DIR/build/ExportOptions.plist"
  cat > "$EXPORT_OPTIONS" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF
  xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    | grep -E "^(error:|warning:|Export succeeded|Export FAILED|===)" || true
else
  # Ad-hoc signed: copy .app from archive and sign with local identity
  echo "==> Ad-hoc signing (no Developer ID required)"
  cp -R "$ARCHIVE_PATH/Products/Applications/$APP_NAME.app" "$EXPORT_PATH/"
  codesign --force --deep --sign - "$EXPORT_PATH/$APP_NAME.app"
fi

APP_PATH="$EXPORT_PATH/$APP_NAME.app"
if [ ! -d "$APP_PATH" ]; then
  echo "error: App not found at $APP_PATH"
  exit 1
fi

# Package as DMG
if ! command -v create-dmg &>/dev/null; then
  echo "error: create-dmg not found. Install with: brew install create-dmg"
  exit 1
fi

create-dmg \
  --volname "$APP_NAME" \
  --volicon "$APP_PATH/Contents/Resources/AppIcon.icns" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "$APP_NAME.app" 175 190 \
  --app-drop-link 425 190 \
  --skip-jenkins \
  "$DMG_PATH" \
  "$APP_PATH"

SHA256=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')
echo ""
echo "==> Done: $DMG_PATH (sha256: $SHA256)"

# Create GitHub release and upload DMG
if ! command -v gh &>/dev/null; then
  echo "error: gh not found. Install with: brew install gh"
  exit 1
fi

echo ""
echo "==> Creating GitHub release v$VERSION"
if gh release view "v$VERSION" --repo Kristoffer88/ProfileNavigator &>/dev/null; then
  echo "error: GitHub release v$VERSION already exists. Bump MARKETING_VERSION in project.yml first."
  exit 1
fi
gh release create "v$VERSION" "$DMG_PATH" \
  --repo Kristoffer88/ProfileNavigator \
  --title "v$VERSION" \
  --notes "Release v$VERSION"

# Update cask in homebrew-tap
echo ""
echo "==> Updating homebrew-tap cask"
TAP_DIR=$(mktemp -d)
trap 'rm -rf "$TAP_DIR"' EXIT
gh repo clone Kristoffer88/homebrew-tap "$TAP_DIR" -- --quiet
CASK_FILE="$TAP_DIR/Casks/profile-navigator.rb"

sed -i '' "s/version \".*\"/version \"$VERSION\"/" "$CASK_FILE"
sed -i '' "s/sha256 \".*\"/sha256 \"$SHA256\"/" "$CASK_FILE"

cd "$TAP_DIR"
git add Casks/profile-navigator.rb
git commit -m "Update profile-navigator to v$VERSION"
git push
cd "$PROJECT_DIR"

echo ""
echo "==> Release complete. Install/upgrade with:"
echo "    brew upgrade --cask profile-navigator"
