	.eqv	SYS_PRNFLT, 2
	.eqv	SYS_PRNSTR, 4
	.eqv	SYS_RDINT, 5
	.eqv	SYS_EXIT0, 10
	.eqv	SYS_PRNINTU, 36

	.data
aprompt:	.asciz	"Enter a: "
bprompt:	.asciz	"Enter b: "

delta:		.float	1.5708		# pi / 2
	
x:		.float	0.0
y:		.float	0.0
	
	.text
	
.macro	sine(%fdst, %fsrc)
# First step of taylor series x
	fmv.s		%fdst, %fsrc	# fdst = x,  will be result
	
# Second step of taylor series (x^3)/(3!)
	fmul.s		ft11, %fsrc, %fsrc	# ft11 = x^2
	fmul.s		ft11, ft11, %fsrc	# ft11 = x^3
	li		a0, 6			# a0 = 3! = 6
	fcvt.s.wu	ft10, a0		# ft10 is a0 as float
	fdiv.s		ft11, ft11, ft10	# ft11 = (x^3)/(3!)
	
	fsub.s		%fdst, %fdst, ft11	# fdst = x - (x^3)/(3!)
.end_macro

main:
	li	t5, 128		# t5 is half of screen width
	li	t6, 128		# t6 is half of screen height
	
# Get a from user
	la	a0, aprompt
	li	a7, SYS_PRNSTR
	ecall
	
	li	a7, SYS_RDINT
	ecall
	
	mv	t0, a0		# t0 is a

# Get b from user
	la	a0, bprompt
	li	a7, SYS_PRNSTR
	ecall
	
	li	a7, SYS_RDINT
	ecall
	
	mv	t1, a0		# t1 is b

	la	a0, delta
	flw	ft0, (a0)
	sine	fa0, ft0
	
fin:
# Temporarily print sine output
	li	a7, SYS_PRNFLT
	ecall

# Exit
	li	a7, SYS_EXIT0
	ecall
