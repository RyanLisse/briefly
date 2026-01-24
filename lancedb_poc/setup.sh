#!/bin/bash
# Setup script for Briefly LanceDB POC

set -e

echo "=========================================="
echo "Briefly LanceDB POC - Setup"
echo "=========================================="
echo ""

# Check Python version
echo "Checking Python version..."
python3 --version

# Create virtual environment (optional but recommended)
echo ""
echo "Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install dependencies
echo ""
echo "Installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

echo ""
echo "=========================================="
echo "✅ Setup complete!"
echo "=========================================="
echo ""
echo "To run the POC:"
echo "  source venv/bin/activate  # Activate virtual environment"
echo "  python briefly_lancedb_poc.py"
echo ""
