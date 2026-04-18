#!/bin/bash

# This script erases the cached GitHub credentials from the macOS keychain.
# After running this, the next `git push` will prompt you to log in to GitHub again.

echo "host=github.com" | git credential-osxkeychain erase
echo "protocol=https" | git credential-osxkeychain erase

echo "✅ Git credentials cleared! You can now run:"
echo "git push -u origin feature/security-hardening"
