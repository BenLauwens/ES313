#!/bin/bash
echo "Starting Jupyter Lab and running updates..."
cd "${0%/*}"
/Applications/Julia-1.2.app/Contents/Resources/julia/bin/julia configES313.jl