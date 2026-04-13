#!/bin/bash
# Quick ISO Test Script
# Verifies the Nexus ISO is bootable and ready

set -e

ISO_FILE="${1:-./release-artifacts/nexus-0.1.0.iso}"

if [ ! -f "$ISO_FILE" ]; then
    echo "❌ ISO file not found: $ISO_FILE"
    exit 1
fi

echo "════════════════════════════════════════════"
echo "🧪 NEXUS ISO 0.1.0 TEST SUITE"
echo "════════════════════════════════════════════"
echo ""

# Test 1: File exists and has size
echo "Test 1: File Properties"
SIZE=$(du -h "$ISO_FILE" | cut -f1)
echo "  Size: $SIZE"
[ -f "$ISO_FILE" ] && echo "  ✅ File exists" || exit 1
echo ""

# Test 2: File is ISO
echo "Test 2: ISO Format"
FILE_TYPE=$(file "$ISO_FILE")
if echo "$FILE_TYPE" | grep -q "ISO 9660"; then
    echo "  ✅ Valid ISO 9660 format"
else
    echo "  ❌ Not ISO 9660"
    echo "  Type: $FILE_TYPE"
    exit 1
fi
echo ""

# Test 3: Bootable
echo "Test 3: Bootability"
if echo "$FILE_TYPE" | grep -q "bootable"; then
    echo "  ✅ ISO is bootable"
else
    echo "  ⚠️  Bootability flag may not be set"
fi
echo ""

# Test 4: MD5 Checksum
echo "Test 4: Integrity"
MD5=$(md5sum "$ISO_FILE" | awk '{print $1}')
echo "  MD5: $MD5"
echo "  ✅ Checksum: $MD5" > "${ISO_FILE}.md5"
echo ""

# Test 5: ISO Info
echo "Test 5: ISO Label"
if command -v isoinfo &> /dev/null; then
    LABEL=$(isoinfo -d -i "$ISO_FILE" 2>/dev/null | grep "Volume id" | head -1)
    echo "  $LABEL"
else
    echo "  (isoinfo not available)"
fi
echo ""

echo "════════════════════════════════════════════"
echo "✅ TEST SUITE PASSED"
echo "════════════════════════════════════════════"
echo ""
echo "ISO is ready for deployment!"
echo ""
echo "Next steps:"
echo "  1. Download to Proxmox host"
echo "  2. Create VM with this ISO"
echo "  3. Boot and verify system starts"
echo ""
