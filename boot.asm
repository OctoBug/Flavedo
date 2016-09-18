;%define    _BOOT_DEBUG_                ;调试模式, 做 Boot Sector 时用 nasm boot.asm -o boot.com

%ifdef      _BOOT_DEBUG_
    org     0100h
%else
    org     07C00h
%endif

    jmp     short LABEL_START
    nop

    ;FAT12 磁盘头
    BS_OEMName      db      'Flavedo '      ;OEM String, 必须 8 字节
    BPB_BytsPerSec  dw      512             ;每扇区字节数
    BPB_SecPerClus  db      1               ;每簇多少扇区
    BPB_RsvdSecCnt  dw      1               ;Boot 记录占用多少扇区
    BPB_NumFATs     db      2               ;共有多少 FAT 表
    BPB_RootEntCnt  dw      224             ;根目录文件数最大值
    BPB_TotSec16    dw      2880            ;逻辑扇区总数
    BPB_Media       db      0xF0            ;媒体描述符
    BPB_FATSz16     dw      9               ;每 FAT 扇区数
    BPB_SecPerTrk   dw      18              ;每磁道扇区数
    BPB_NumHeads    dw      2               ;磁头数(面数)
    BPB_HiddSec     dd      0               ;隐藏扇区数
    BPB_TotSec32    dd      0               ;wTotalSelectorCount 为 0 时这个值记录扇区数
    BS_DrvNum       db      0               ;中断 13 的驱动器号
    BS_Reserved1    db      0               ;未使用
    BS_BootSig      db      29h             ;扩展引导标记(29h)
    BS_VolID        dd      0               ;卷序列号
    BS_VolLab       db      'OS Flavedo '   ;卷标, 必须 11 字节
    BS_FileSysType  db      'FAT12   '      ;文件系统类型, 必须 8 字节

LABEL_START:
	mov     ax,cs
	mov     ds,ax
	mov     es,ax
	call    DispStr				;调用显示字符串例程
	jmp     $	
DispStr:
	mov     ax,BootMessage
	mov     bp,ax				;ES:BP = 串地址
	mov     cx,25				;CX = 串长度
	mov     ax,01301h			;AH = 13, AL = 01h
	mov     bx,000Ch			;页号为0(BH = 0) 黑底红字(BL = 0ch, 高亮)
	mov     dl,0
	int     10h				;10h 号终端
	ret
BootMessage:		db	"Hello, I'm a Boot sector!"
times	510-($-$$)	db	0		;填充剩下的空间，使生成的二进制代码恰好为512字节
dw	0xaa55					;结束标志
