###########################
# Makefile for Kernel Tox #
###########################

# Programs, flags, etc.
ASM 		= nasm
DASM 		= ndisasm
CC 			= gcc
LD 			= ld
ASMBFLAGS 	= -I boot/include/
ASMKFLAGS 	= -I include/ -f elf
# disable builtin fuctions & stack protector
CFLAGS 		= -I include/ -c -Wall -f no-builtin -f no-stack-protector 		

# This program
TOXSBOOT 	= boot/boot.bin boot/loader.bin kernel/kernel.bin

.PHONY : 	everything image clean buildimg

# Default starting position
everything : $(TOXSBOOT)

image : everything buildimg

clean : 
	rm -f $(TOXSBOOT)

# tox.img needs to be exist.
buildimg :
	dd if=boot/boot.bin of=tox.img bs=512 count=1 conv=notrunc
	sudo mount -o loop tox.img /mnt/floppy/
	sudo cp -vf boot/loader.bin /mnt/floppy/
	sudo cp -vf kernel/kernel.bin /mnt/floppy/
	sudo umount /mnt/floppy/

# OBJS; $@: target; $<: first prerequisite's name
boot/boot.bin : boot/boot.asm boot/include/fat12hdr.inc boot/include/load.inc
	$(ASM) $(ASMBFLAGS) -o $@ $<
boot/loader.bin : boot/loader.asm boot/include/fat12hdr.inc boot/include/load.inc boot/include/pm.inc
	$(ASM) $(ASMBFLAGS) -o $@ $<
kernel/kernel.bin : kernel/kernel.asm
	$(ASM) $(ASMBFLAGS) -o $@ $<
