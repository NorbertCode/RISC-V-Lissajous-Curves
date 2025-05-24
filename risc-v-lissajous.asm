	.eqv	SYS_PRNSTR, 4
	.eqv	SYS_RDINT, 5
	.eqv	SYS_EXIT0, 10
	.eqv	SYS_PRNINTU, 36

	.data
aprompt:	.asciz	"Enter a: "
bprompt:	.asciz	"Enter b: "
	
	.text
main:
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
	
fin:
	li	a7, SYS_EXIT0
	ecall
