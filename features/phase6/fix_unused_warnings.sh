#!/bin/bash

# Fix unused variable warnings systematically

# Get all unique file paths with unused variable warnings
FILES=$(cargo clippy --manifest-path ../../quadradius/Cargo.toml --all-targets --all-features 2>&1 | grep "unused variable" -A 1 | grep "src/" | awk -F':' '{print $1}' | sort | uniq)

echo "Files with unused variable warnings:"
echo "$FILES"
echo ""

# For each file, get the warnings and apply fixes
for file in $FILES; do
    echo "Processing: $file"
    
    # Run clippy fix on specific file
    cargo clippy --manifest-path ../../quadradius/Cargo.toml --fix --allow-dirty --allow-staged -- --bins
done

echo "Done!"