;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                               fat12hdr.inc
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                                                       Forrest Yu, 2005
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;FAT12 磁盘的头
;-------------------------------------------------------------------------
BS_OEMName          db      'Kern-Tox'      ;OEM String, 必须 8 个字节

BPB_BytsPerSec      dw      512             ;每扇区字节数
BPB_SecPerClus      db      1               ;每簇扇区数
BPB_RsvdSecCnt      dw      1               ;Boot 记录所占扇区数
BPB_NumFATs         db      2               ;FAT 表总数
BPB_RootEntCnt      dw      224             ;根目录文件数最大值
BPB_TotSec16        dw      2880            ;逻辑扇区总数
BPB_Media           db      0xf0            ;媒体描述符
BPB_FATSz16         dw      9               ;每 FAT 扇区数
BPB_SecPerTrk       dw      18              ;每磁道扇区数
BPB_NumHeads        dw      2               ;磁头数(面数)
BPB_HiddSec         dd      0               ;隐藏扇区数
BPB_TotSec32        dd      0               ;如果 wTotalSectorCount 是 0,
                                            ;则由这个值记录扇区数
BS_DrvNum           db      0               ;中断 13 的驱动器号
BS_Reserved1        db      0               ;未使用
BS_BootSig          db      0x29            ;扩展引导标记(0x29)
BS_VolID            dd      0               ;卷序列号
BS_VolLab           db      'Kernel-Tox '   ;卷标, 必须 11 个字节
BS_FileSysType      db      'FAT12   '      ;文件系统类型, 必须 8 个字节
;-------------------------------------------------------------------------

;-------------------------------------------------------------------------
;给予 FAT12 头的一些常量定义, 如果头信息改变, 下面的常量可能也要做相应改变
;-------------------------------------------------------------------------
FATSz               equ     9               ;BPP_FATSz16
RootDirSectors      equ     14              ;根目录占用扇区数
SectorNoOfRootDir   equ     19              ;根目录的第一个扇区号
SectorNoOfFAT1      equ     1               ;FAT1 的第一个扇区号
DeltaSectorNo       equ     17              ;常量, 用于计算文件开始扇区号
