	.eqv	SYS_PRNSTR, 4
	.eqv	SYS_RDINT, 5
	.eqv	SYS_EXIT0, 10
	.eqv	SYS_SLEEP, 32
	
	.eqv	DIS_START, 0x10010000

	.data
aprompt:	.asciz	"Enter a: "
bprompt:	.asciz	"Enter b: "

twopi:		.float	6.2832	# 2pi

delta:		.float	1.5708	# pi / 2

screensize:	.word	512
color:		.word	0x00FFFFFF
	
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
	
	li	t4, 4		# t4 is taylor step counter
	
	li	t6, 1		# t6 is current step denominator without factorial (1, 3, 5, ...)
	li	t5, 1		# t5 is current step denominator factorial (1!, 3!, 5!, ...)
	
factorial:
	addi	t6, t6, 1	# increment denominator base
	mul	t5, t5, t6	# multiply by new number
	
# Repeat
	addi	t6, t6, 1
	mul	t5, t5, t6
	
	fcvt.s.wu	ft11, t5	# ft11 is t5 as float

taylorstep:	
	fmul.s	ft9, ft9, ft10		# ft9 = x^3 in second step
	fdiv.s	ft8, ft9, ft11		# ft8 = (x^3)/(3!) in second step
	
	andi	a0, t4, 1		# a0 is 0 if step is divisible by 2
	bnez	a0, tayloradd
	
	fsub.s	%fdst, %fdst, ft8	# fdst = x - (x^3)/(3!)
	b	taylorfin

tayloradd:
	fadd.s	%fdst, %fdst, ft8	# fdst = x + (x^3)/(3!)
	
taylorfin:
	addi	t4, t4, -1
	bgtz	t4, factorial
.end_macro

.macro	xcoord(%dst, %delta, %hsize, %a, %t)
	fmadd.s		ft7, %a, %t, %delta		# ft7 = at - delta
	sin		%dst, ft7			# dst = sin(at - delta)
	fmadd.s		%dst, %dst, %hsize, %hsize	# dst = halfsize * sin(at - delta) + halfsize
.end_macro

.macro	ycoord(%dst, %delta, %hsize, %b, %t)	
	fmul.s		ft7, %b, %t			# ft7 = bt
	sin		%dst, ft7			# dst = sin(bt)
	fmadd.s		%dst, %dst, %hsize, %hsize	# dst = halfsize * sin(bt) + halfsize
.end_macro

main:
	flw	ft0, twopi, a0		# ft0 is 2pi
	flw	ft1, delta, a0		# ft1 is delta
	
	lw	t0, screensize		# t0 is screen size
	li	t1, DIS_START		# t1 is display start
	lw	t2, color		# t2 is color

	srai		t6, t0, 1
	fcvt.s.wu	ft2, t6		# ft2 is half of screen size as float
	
	lw	a1, screensize	# a1 is counter = screensize
	slli	a1, a1, 1	# a1 = 2 * screensize
	
# Get a from user
	la	a0, aprompt
	li	a7, SYS_PRNSTR
	ecall
	
	li	a7, SYS_RDINT
	ecall
	
	mv	a2, a0		# Remember a to compare later
	
	fcvt.s.wu	ft3, a0		# ft3 is a

# Get b from user
	la	a0, bprompt
	li	a7, SYS_PRNSTR
	ecall
	
	li	a7, SYS_RDINT
	ecall
	
	fcvt.s.wu	ft4, a0		# ft4 is b

# Initialize point counter
	bgtu	a2, a0, mulb
	mul	a1, a1, a2	# a1 = 2 * a * screensize
	b	endcomp
	
mulb:
	mul	a1, a1, a0	# a1 = 2 * b * screensize
	
endcomp:
	fcvt.s.wu	ft6, a1		# ft5 is point amount, total as float
	
drawpixel:
# Convert current point to <-pi, pi>
	fcvt.s.wu	ft5, a1		# ft5 is current point
	fdiv.s		ft5, ft5, ft6	# ft5 is in <0, 1>
	fmul.s		ft5, ft5, ft0	# ft5 is in <0, 2pi>

# Calculate coordinates
	xcoord		fa0, ft1, ft2, ft3, ft5
	fcvt.wu.s	t3, fa0		# t3 is x pixel
	
	ycoord		fa0, ft1, ft2, ft4, ft5
	fcvt.wu.s	t4, fa0		# t4 is y pixel
	
# Calculate pixel address
	mul	t5, t4, t0	# t3 = y * screensize
	add	t5, t5, t3	# t3 = (y * screensize) + x
	slli	t5, t5, 2	# t3 = 4((y * screensize) + x)
	add	t5, t5, t1	# a0 = displaystart + 4((y * screensize) + x)
	
	sw	t2, (t5)
	
# Sleep
	li	a0, 1
	li	a7, SYS_SLEEP
	ecall
	
# Loop
	addi		a1, a1, -1
	bgtz		a1, drawpixel
	
fin:
	li	a7, SYS_EXIT0
	ecall
