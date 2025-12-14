#!/bin/bash

# Script to run code quality checks for Phase 2

echo "🔍 Running Code Quality Checks for Phase 2..."
echo "============================================"

# Navigate to the project directory
cd ../../quadradius

# Step 1: Check if code compiles
echo ""
echo "1️⃣ Running cargo check..."
echo "------------------------"
cargo check 2>&1 | tee ../features/phase2/check_output.txt

# Step 2: Run clippy for linting
echo ""
echo "2️⃣ Running cargo clippy..."
echo "-------------------------"
cargo clippy -- -W clippy::all 2>&1 | tee ../features/phase2/clippy_output.txt

# Step 3: Check formatting
echo ""
echo "3️⃣ Running cargo fmt check..."
echo "-----------------------------"
cargo fmt -- --check 2>&1 | tee ../features/phase2/fmt_output.txt

# Step 4: Run tests
echo ""
echo "4️⃣ Running cargo test..."
echo "-----------------------"
cargo test phase2 2>&1 | tee ../features/phase2/test_output.txt

echo ""
echo "✅ Code quality checks complete!"
echo "Check the output files for details."