#!/bin/bash

# Spotcast Custom - Quick release script
# Usage: ./release.sh "commit message" [patch|minor|major]

if [ $# -eq 0 ]; then
    echo "❌ Usage: ./release.sh \"commit message\" [patch|minor|major]"
    echo "   Example: ./release.sh \"Fix authentication bug\" patch"
    exit 1
fi

COMMIT_MSG="$1"
VERSION_TYPE=${2:-patch}

echo "🚀 Quick Release for Spotcast Custom"
echo "=================================="

# Bump version
echo "🔧 Bumping $VERSION_TYPE version..."
./bump_version.sh $VERSION_TYPE

if [ $? -ne 0 ]; then
    echo "❌ Version bump failed!"
    exit 1
fi

# Get new version for commit message
NEW_VERSION=$(grep 'version:' config.yaml | sed 's/version: "//g' | sed 's/"//g')

# Git operations
echo "📝 Committing changes..."
git add .
git commit -m "v$NEW_VERSION: $COMMIT_MSG"

echo "⬆️  Pushing to GitHub..."
git push origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Successfully released version $NEW_VERSION!"
    echo "🔗 Check: https://github.com/darkkatarsis/spotcast-custom"
    echo "🏠 Install in Home Assistant: Settings → Add-ons → Add-on Store"
else
    echo "❌ Push failed!"
    exit 1
fi