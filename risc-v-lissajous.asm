	.eqv	SYS_PRNFLT, 2
	.eqv	SYS_PRNSTR, 4
	.eqv	SYS_RDINT, 5
	.eqv	SYS_EXIT0, 10
	.eqv	SYS_PRNCHR, 11
	.eqv	SYS_SLEEP, 32
	.eqv	SYS_PRNINTU, 36

	.data
aprompt:	.asciz	"Enter a: "
bprompt:	.asciz	"Enter b: "

pi:		.float	3.1416
delta:		.float	1.5708		# pi / 2

step:		.float	1.0
	
	.text
	
.macro	sin(%fdst, %fsrc)
# First step of taylor series x
	fmv.s		%fdst, %fsrc	# fdst = x
	
# Second step of taylor series (x^3)/(3!)
	fmul.s		ft10, %fsrc, %fsrc	# ft10 = x^2
	
	fmul.s		ft9, ft10, %fsrc	# ft9 = x^3
	li		a0, 6			# a0 = 3! = 6
	fcvt.s.wu	ft11, a0		# ft11 is a0 as float
	fdiv.s		ft8, ft9, ft11		# ft8 = (x^3)/(3!)
	
	fsub.s		%fdst, %fdst, ft8	# fdst = x - (x^3)/(3!)
	
# Third step of taylor series (x^5)/(5!)
	fmul.s		ft9, ft9, ft10		# ft9 = x^5
	li		a0, 120			# a0 = 5! = 120
	fcvt.s.wu	ft11, a0		# ft11 is a0 as float
	fdiv.s		ft8, ft9, ft11		# ft9 = (x^5)/(5!)
	
	fadd.s		%fdst, %fdst, ft8	# fdst = x - (x^3)/(3!) + (x^5)/(5!)
.end_macro

.macro	xcoord(%dst, %delta, %hsize, %a, %t)
	fmul.s		ft7, %a, %t		# ft7 = at
	fadd.s		ft7, ft7, %delta	# ft7 = at - delta
	sin		%dst, ft7		# dst = sin(at - delta)
	fmul.s		%dst, %dst, %hsize	# dst = halfsize * sin(at - delta)
	fadd.s		%dst, %dst, %hsize	# dst = halfsize * sin(at - delta) + halfsize
.end_macro

.macro	ycoord(%dst, %delta, %hsize, %b, %t)	
	fmul.s		ft7, %b, %t		# ft7 = bt
	sin		%dst, ft7		# dst = sin(bt)
	fmul.s		%dst, %dst, %hsize	# dst = halfsize * sin(bt)
	fadd.s		%dst, %dst, %hsize	# dst = halfsize * sin(bt) + halfsize
.end_macro

main:
	flw	ft0, pi, a0	# ft0 is pi
	flw	ft1, delta, a0	# ft1 is delta
	
	li	t6, 128		# t6 is half of screen size
	fcvt.s.wu	ft2, t6	# ft2 is half of screen size as float
	
	fmv.s	ft5, ft0
	fadd.s	ft5, ft5, ft5	# ft5 = 2pi, is counter to 0
	
	flw	ft6, step, a0	# ft6 is counter step
	
# Get a from user
	la	a0, aprompt
	li	a7, SYS_PRNSTR
	ecall
	
	li	a7, SYS_RDINT
	ecall
	
	fcvt.s.wu	ft3, a0		# ft3 is a

# Get b from user
	la	a0, bprompt
	li	a7, SYS_PRNSTR
	ecall
	
	li	a7, SYS_RDINT
	ecall
	
	fcvt.s.wu	ft4, a0		# ft4 is b
	
printcoords:
	xcoord	fa0, ft1, ft2, ft3, ft5
	li	a7, SYS_PRNFLT
	ecall
	
	li	a0, ' '
	li	a7, SYS_PRNCHR
	ecall
	
	ycoord	fa0, ft1, ft2, ft4, ft5
	li	a7, SYS_PRNFLT
	ecall
	
	li	a0, '\n'
	li	a7, SYS_PRNCHR
	ecall
	
	li	a0, 100
	li	a7, SYS_SLEEP
	ecall
	
	fsub.s		ft5, ft5, ft6
	li		a0, 0
	fcvt.s.wu	ft7, a0
	fge.s		t6, ft5, ft7		# t6 is 1 if counter >= 0
	bnez		t6, printcoords
	
fin:
	li	a7, SYS_EXIT0
	ecall
