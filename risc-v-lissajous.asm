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

twopi:		.float	6.2832	# 2pi
delta:		.float	1.5708	# pi / 2

step:		.float	1.0
	
	.text
.macro	sin(%fdst, %fsrc)
# Normalize fsrc to <-pi, pi>
	fmv.s		ft9, %fsrc	# ft9 = x
	fdiv.s		ft8, ft9, ft0	# ft8 = x / 2pi
	fcvt.w.s	t6, ft8
	fcvt.s.w	ft8, t6		# ft8 = round(x / 2pi)
	fmul.s		ft8, ft8, ft0	# ft8 = 2pi * round(x / 2pi)
	fsub.s		ft9, ft9, ft8	# ft9 = x - 2pi * round(x / 2pi), so x is normalized to <-pi, pi>

# First step of taylor series x
	fmv.s	%fdst, ft9	# fdst = x

# Preparations for further steps
	fmul.s	ft10, ft9, ft9	# ft10 = x^2
	
	li	t3, 4		# t3 is taylor step counter
	
	li	t6, 1		# t6 is current step denominator without factorial (1, 3, 5, ...)
	li	t5, 1		# t5 is current step denominator factorial (1!, 3!, 5!, ...)

resetfactorial:
	li	t4, 2		# t4 is factorial counter, each step needs + 2
	
factorial:
	addi	t6, t6, 1	# increment denominator base
	mul	t5, t5, t6	# multiply by new number
	addi	t4, t4, -1	# each step repeated twice, so decrement
	bgtz	t4, factorial
	
	fcvt.s.wu	ft11, t5	# ft11 is t5 as float

taylorstep:	
	fmul.s	ft9, ft9, ft10		# ft9 = x^3 in second step
	fdiv.s	ft8, ft9, ft11		# ft8 = (x^3)/(3!) in second step
	
	andi	t4, t3, 1		# t4 is 0 if step is divisible by 2
	bnez	t4, tayloradd
	
	fsub.s	%fdst, %fdst, ft8	# fdst = x - (x^3)/(3!)
	b	taylorfin

tayloradd:
	fadd.s	%fdst, %fdst, ft8	# fdst = x + (x^3)/(3!)
	
taylorfin:
	addi	t3, t3, -1
	bgtz	t3, resetfactorial
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
	flw	ft0, twopi, a0	# ft0 is 2pi
	flw	ft1, delta, a0	# ft1 is delta
	
	li		t6, 128	# t6 is half of screen size
	fcvt.s.wu	ft2, t6	# ft2 is half of screen size as float
	
	fmv.s	ft5, ft0	# ft5 = 2pi, is counter to 0
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
	fge.s		t6, ft5, ft7	# t6 is 1 if counter >= 0
	bnez		t6, printcoords
	
fin:
	li	a7, SYS_EXIT0
	ecall
