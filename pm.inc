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
DA_32	EQU	4000h		;32位段

;存储段描述符类型
DA_DR	EQU	90h		;存在的只读数据段类型值
DA_DRW	EQU	92h		;存在的可读写数据段属性值
DA_DRWA	EQU	93h		;存在的已访问可读写数据段类型值
DA_C	EQU	98h		;存在的只执行代码段属性值
DA_CR	EQU	9Ah		;存在的可执行可读代码段属性值
DA_CCO	EQU	9Ch		;存在的只执行一致代码段属性值
DA_CCOR	EQU	9EH		;存在的可执行可读一致代码段属性值

;描述符
;usage: Descriptor Base, Limit, Attr
;	Base:	dd
;	Limit:	dd (low 20 bits available)
;	Attr:	dw (lower 4 bits of higher byte are always 0)
%macro Descriptor 3
	dw	%2 & 0FFFFh				;段界限1
	dw	%1 & 0FFFFh				;段基址1
	db	(%1 >> 16) & 0FFh			;段基址2
	dw	((%2 >> 8) & 0F00H) | (%3 & 0F0FFh)	;属性1 + 段界限2 + 属性2
	db	(%1 >> 24) & 0FFH			;段基址3
%endmacro						;共8字节
