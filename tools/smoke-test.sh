#!/bin/sh
set -eu

image="${1:-build/terminal-os.img}"
log="${SMOKE_LOG:-build/smoke.log}"

mkdir -p "$(dirname "$log")"
rm -f "$log"

(
    sleep 1
    printf 'help\r'
    printf 'about\r'
    printf 'mem\r'
    sleep 2
) | qemu-system-i386 \
    -drive "file=$image,format=raw,if=floppy" \
    -display none \
    -serial stdio \
    -monitor none \
    > "$log" 2>&1 &

qemu_pid=$!
sleep 5
kill "$qemu_pid" 2>/dev/null || true
wait "$qemu_pid" 2>/dev/null || true

if grep -q "Terminal OS" "$log" \
    && grep -q "commands:" "$log" \
    && grep -q "one boot sector" "$log" \
    && grep -q "conventional memory:" "$log"; then
    echo "smoke test passed"
    echo "log: $log"
else
    echo "smoke test failed"
    echo "log: $log"
    sed -n '1,160p' "$log"
    exit 1
fi
