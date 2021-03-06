;-------------------------------------------------------------------------
;描述符类型值说明
;   DA_     : Descriptor Attribute
;   D       : 数据段
;   C       : 代码段
;   S       : 系统段
;   R       : 只读
;   RW      : 读写
;   A       : 已访问
;-------------------------------------------------------------------------
DA_32       EQU 0x4000      ;32 位段
DA_LIMIT_4K EQU 0x8000      ;段界限粒度为 4K 字节
DA_DPL0     EQU 0x00        ;DPL = 0
DA_DPL1     EQU 0x20        ;DPL = 1
DA_DPL2     EQU 0x40        ;DPL = 2
DA_DPL3     EQU 0x60        ;DPL = 3
;-------------------------------------------------------------------------
;存储段描述符类型值说明
;-------------------------------------------------------------------------
DA_DR       EQU 0x90        ;存在的只读数据段类型值
DA_DRW      EQU 0x92        ;存在的可读写数据段属性值
DA_DRWA     EQU 0x93        ;存在的已访问可读写数据段类型值
DA_C        EQU 0x98        ;存在的只执行代码段属性值
DA_CR       EQU 0x9a        ;存在的可执行可读代码段属性值
DA_CCO      EQU 0x9c        ;存在的只执行一致代码段属性值
DA_CCOR     EQU 0x9e        ;存在的可执行可读一致代码段属性值
;-------------------------------------------------------------------------
;系统段描述符类型值说明
;-------------------------------------------------------------------------
DA_LDT      EQU 0x82        ;局部描述符表段类型值
DA_TaskGate EQU 0x85        ;任务门类型值
DA_386TSS   EQU 0x89        ;可用 386 任务状态段类型值
DA_386CGate EQU 0x8c        ;386 调用门类型值
DA_386IGate EQU 0x8e        ;386 中断门类型值
DA_386TGate EQU 0x8f        ;386 陷阱门类型值
;-------------------------------------------------------------------------
;选择子类型值说明
;   SA_     : Selector Attribute
;-------------------------------------------------------------------------
SA_RPL0     EQU 0
SA_RPL1     EQU 1
SA_RPL2     EQU 2
SA_RPL3     EQU 3
SA_TIG      EQU 0
SA_TIL      EQU 4
;-------------------------------------------------------------------------
;分页机制使用的常量说明
;-------------------------------------------------------------------------
PG_P        EQU 1           ;页存在属性位
PG_RWR      EQU 0           ;R/W 属性位值, 读/执行
PG_RWW      EQU 2           ;R/W 属性位值, 读/写/执行
PG_USS      EQU 0           ;U/S 属性位值, 系统级
PG_USU      EQU 4           ;U/S 属性位值, 用户级
;-------------------------------------------------------------------------
;宏
;描述符 (共 8 字节)
;Usage: Descriptor Base, Limit, Attr
;       Base:   dd
;       Limit:  dd (low 20 bits available)
;       Attr:   dw (lower 4 bits of higher byte are always 0)
;-------------------------------------------------------------------------
%macro Descriptor 3
    dw (%2)&0xffff                          ;段界限 1 (2 字节)
    dw (%1)&0xffff                          ;段界限 1 (2 字节)
    db ((%1)>>16)&0xff                      ;段基址 2 (1 字节)
    dw (((%2)>>8)&0x0f00)|((%3)&0xf0ff)     ;属性 1 + 段界限 2 + 属性 2 (2 字节)
    db ((%1)>>24)&0xff                      ;段基址 3 (1 字节)
%endmacro
;-------------------------------------------------------------------------
;门 (共 8 字节)
;Usage: Gate Selector, Offset, DCount, Attr
;       Selector:   dw
;       Offset:     dd
;       DCount:     db
;       Attr:       db
;-------------------------------------------------------------------------
%macro Gate 4
    dw ((%2)&0xffff)                        ;偏移 1 (2 字节)
    dw (%1)                                 ;选择子 (2 字节)
    dw ((%3)&0x1f)|(((%4)<<8)&0xff00)       ;属性 (2 字节)
    dw (((%2)>>16)&0xffff)                  ;偏移 2 (2 字节)
%endmacro
