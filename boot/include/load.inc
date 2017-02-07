base_of_loader          equ     0x9000                  ;loader.bin 的段地址
offset_of_loader        equ     0x0100                  ;loader.bin 的偏移地址
base_of_loader_phy_addr equ     base_of_loader * 0x10   ;loader.bin 的物理地址
base_of_kernel          equ     0x8000                  ;kernel.bin 的段地址
offset_of_kernel        equ     0x00                    ;kernel.bin 的偏移地址
