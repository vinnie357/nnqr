#!/bin/bash

# Simple script to check Phase 2 files compile

echo "🔍 Checking Phase 2 files..."
echo "=========================="

cd ../../quadradius

# List the Phase 2 files we added
PHASE2_FILES=(
    "src/systems/effect_processing.rs"
    "src/systems/combat_effects.rs"
    "src/systems/area_targeting.rs"
    "src/tests/phase2_effect_system_tests.rs"
    "src/tests/phase2_integration_tests.rs"
)

echo "Phase 2 files to check:"
for file in "${PHASE2_FILES[@]}"; do
    echo "  - $file"
done

echo ""
echo "Running rustc check on individual files..."
echo "-----------------------------------------"

for file in "${PHASE2_FILES[@]}"; do
    echo ""
    echo "Checking: $file"
    rustc --edition 2021 --crate-type lib --emit=metadata --out-dir /tmp \
        -L target/debug/deps \
        --extern bevy=target/debug/deps/libbevy.rlib \
        --extern rand=target/debug/deps/librand.rlib \
        --extern serde=target/debug/deps/libserde.rlib \
        "$file" 2>&1 | head -20
done

echo ""
echo "✅ Individual file checks complete!"