;--------------------------------------------
;描述符类型
;	DA_	:	Descriptor Attribute
;	D	:	数据段
;	C	:	代码段
;	S	:	系统段
;	R	:	只读
;	RW	:	读写
;	A	:	已访问
;--------------------------------------------
DA_32		EQU	4000h		;32位段
DA_LIMIT_4K	EQU	8000h		;段界限粒度为4K字节

DA_DPL0		EQU	00h		;DPL=0
DA_DPL1		EQU	20h		;DPL=1
DA_DPL2		EQU	40h		;DPL=2
DA_DPL3		EQU	60h		;DPL=3
;--------------------------------------------
;存储段描述符类型
;--------------------------------------------
DA_DR	EQU	90h		;存在的只读数据段类型值
DA_DRW	EQU	92h		;存在的可读写数据段属性值
DA_DRWA	EQU	93h		;存在的已访问可读写数据段类型值
DA_C	EQU	98h		;存在的只执行代码段属性值，非一致
DA_CR	EQU	9Ah		;存在的可执行可读代码段属性值
DA_CCO	EQU	9Ch		;存在的只执行一致代码段属性值，一致
DA_CCOR	EQU	9EH		;存在的可执行可读一致代码段属性值，一致
;--------------------------------------------
;系统段描述符类型值说明
;--------------------------------------------
DA_LDT		EQU	82h	;局部描述符表段类型值
DA_TG		EQU	85h	;任务门类型
DA_386TSS	EQU	89h	;可用386任务状态段类型值
DA_386CG	EQU	8Ch	;386调用门类型值
DA_386IG	EQU	8Eh	;386中断门类型值
DA_386TG	EQU	8Fh	;386陷阱门类型值

;--------------------------------------------
;选择子类型值说明
;	SA_: Selecotr Attribute
;--------------------------------------------
SA_RPL0	EQU	0
SA_RPL1	EQU	1
SA_RPL2	EQU	2
SA_RPL3	EQU	3

SA_TIG	EQU	0
SA_TIL	EQU	4

;--------------------------------------------
;分页机制使用的常量说明
;--------------------------------------------
PG_P	EQU	1	;页存在属性位
PG_RWR	EQU	0	;R/W 属性位值，读/执行
PG_RWW	EQU	2	;R/W 属性位值，读/写/执行
PG_USS	EQU	0	;U/S 属性位值，系统级
PG_USU	EQU	4	;U/S 属性位值，用户级
;--------------------------------------------

;--------------------------------------------
;描述符
;usage: Descriptor Base, Limit, Attr
;	Base:	dd
;	Limit:	dd (low 20 bits available)
;	Attr:	dw (lower 4 bits of higher byte are always 0)
%macro Descriptor 3
	dw	(%2) & 0FFFFh				;段界限1
	dw	(%1) & 0FFFFh				;段基址1
	db	((%1) >> 16) & 0FFh			;段基址2
	dw	(((%2) >> 8) & 0F00H) | ((%3) & 0F0FFh)	;属性1 + 段界限2 + 属性2
	db	((%1) >> 24) & 0FFH			;段基址3
%endmacro						;共8字节

;--------------------------------------------
;门描述符
;usage: Gate Selector, Offset, DCount, Attr
;	Selector:	dw
;	Offset:		dd
;	DCount:		db
;	Attr:		db
%macro Gate 4
	dw	((%2) & 0FFFFh)				;偏移1
	dw	(%1)					;选择子
	dw	((%3) & 1Fh) | (((%4) << 8) & 0FF00h)	;属性
	dw	(((%2) >> 16) & 0FFFFh)			;偏移2
%endmacro
