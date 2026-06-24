NASM ?= nasm
QEMU ?= qemu-system-i386

BUILD_DIR := build
IMAGE := $(BUILD_DIR)/terminal-os.img
BOOT_BIN := $(BUILD_DIR)/boot.bin
KERNEL_BIN := $(BUILD_DIR)/kernel.bin
KERNEL_SECTORS := 32
FLOPPY_SECTORS := 2880

.PHONY: all run run-serial smoke clean

all: $(IMAGE)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BOOT_BIN): boot/boot.asm | $(BUILD_DIR)
	$(NASM) -f bin -DKERNEL_SECTORS=$(KERNEL_SECTORS) -o $@ $<

$(KERNEL_BIN): kernel/kernel.asm | $(BUILD_DIR)
	$(NASM) -f bin -o $@ $<
	@size=$$(wc -c < $@ | tr -d ' '); \
	max=$$(( $(KERNEL_SECTORS) * 512 )); \
	if [ "$$size" -gt "$$max" ]; then \
		echo "kernel is $$size bytes, but bootloader reads only $$max bytes"; \
		exit 1; \
	fi

$(IMAGE): $(BOOT_BIN) $(KERNEL_BIN)
	dd if=/dev/zero of=$@ bs=512 count=$(FLOPPY_SECTORS) status=none
	dd if=$(BOOT_BIN) of=$@ bs=512 count=1 conv=notrunc status=none
	dd if=$(KERNEL_BIN) of=$@ bs=512 seek=1 conv=notrunc status=none
	@echo "built $@"

run: all
	$(QEMU) -drive file=$(IMAGE),format=raw,if=floppy

run-serial: all
	$(QEMU) -drive file=$(IMAGE),format=raw,if=floppy -display none -serial stdio -monitor none

smoke: all
	tools/smoke-test.sh $(IMAGE)

clean:
	rm -rf $(BUILD_DIR)
