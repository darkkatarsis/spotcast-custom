#!/bin/bash

# Spotcast Custom - Version bumper script
# Usage: ./bump_version.sh [patch|minor|major]

VERSION_TYPE=${1:-patch}

echo "🔧 Bumping $VERSION_TYPE version..."

# Get current version from config.yaml
CURRENT_VERSION=$(grep 'version:' config.yaml | sed 's/version: "//g' | sed 's/"//g')
echo "📋 Current version: $CURRENT_VERSION"

# Split version into parts
IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR=${VERSION_PARTS[0]}
MINOR=${VERSION_PARTS[1]}
PATCH=${VERSION_PARTS[2]}

# Bump version based on type
case $VERSION_TYPE in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        echo "❌ Invalid version type. Use: patch, minor, or major"
        exit 1
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
echo "🚀 New version: $NEW_VERSION"

# Update config.yaml
sed -i.bak "s/version: \".*\"/version: \"$NEW_VERSION\"/" config.yaml

# Update Dockerfile
sed -i.bak "s/io.hass.version=\".*\"/io.hass.version=\"$NEW_VERSION\"/" Dockerfile

# Clean up backup files
rm -f config.yaml.bak Dockerfile.bak

echo "✅ Version bumped to $NEW_VERSION"
echo "📝 Files updated: config.yaml, Dockerfile"
echo ""
echo "🔄 Next steps:"
echo "   git add ."
echo "   git commit -m \"Bump version to $NEW_VERSION\""
echo "   git push origin main"