	.data
prueba: .asciiz "Esto es una prueba"
char:   .asciiz "p"
	

	.text
main: 
	#Habilitar pantalla
	mfc0 $s0, $12
	ori $s0, $s0, 0x0401
	mtc0 $s0, $12
	#habilitamos la pantalla 
	lui $t0, 0xFFFF
	li $t1, 1
	lw $t1, 8($t0)
	####
	addi $t1, $0, 2
	lw $t1, 8($t0)
	la $t1, char
	lb $t2, 0($t1)
fin:jal PrintCharacter
	jal Delay 
	j fin

#Haciendo uso de consultas de estado para la pantalla
PrintCharacter: 
	lui $a1, 0xFFFF
	lb $0, 0xC($a1)
	sb $t2, 0xC($a1)
ctr: 
	lw $t0, 0x8($a1)
	andi $t0, $t0, 1
	beqz $t0, ctr
	jr $31

Delay:
	li $a0, 105000	
ret: 
	addi $a0, $a0, -1
	bnez $a0, ret 
	jr $31
