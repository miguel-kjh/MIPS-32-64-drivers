	.data
#Interfaz del juego
frase0: .asciiz "###########JUEGO DE MECANOGRAFIA###########\nRescribe la siguente frase lo mas rapido que puedas:\n"
frasePedir: .asciiz "Escribe la frase con la que quieres jugar: "
frase2:	.asciiz "\nEmpieza:  "
malfrase: .asciiz "La frase que has escrito no es la corecta\n"
correctafrase: .asciiz "La frase que has escrito es la corecta;\n Su tiempo es de: "
puntos: .asciiz ":"
blanco: .asciiz "\n"
.align 2
frasefinal: .asciiz "Quiere volver a jugar(y-->Yes | n-->No)?"
finProgrma: .asciiz "FIN DE PROGRAMA"
countFrase: .word 0

#Espacio para las frases
.align 2
char: .space 200
.align 2
frase1: .space 200


	.text
main:	
	#Imprimimos un blanco
	li $v0 , 4  
	la $a0 , blanco
	syscall
	#ponemos a cero los contadores de tiempo
	add $s2, $0, $0	 # horas
	add $s3, $0, $0, # minutos
	add $s4, $0, $0, # segundos
	#Imprimimos las frases
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	li $v0, 4
	la $a0, frase0
	syscall
	jal Delay
	li $v0, 4
	la $a0, frasePedir
	syscall
	li $t1, 0xA #Enter
	nop
	xor $s0,$s0,$s0	#contador de letras
	la $s1, frase1
pedir: 
	jal ReadChatacter
	beq $a0, $t1, finPedir	#Si se a pulsado enter salta al final de bucle
	jal PrintCharacter
	#Aprovechamos las rutinas de consulta de estado
	sb $a0, 0($s1)
	addi $s1, $s1,1
	addi $s0, $s0,1
	j pedir
finPedir: 
	sb $0, 0($s1)	#Guradamos caracter nulo
	sw $s0, countFrase
	jal Delay
	li $v0, 4
	la $a0, frase2
	syscall
	#Iniciamos interrupción del timer
	#Habilitamos la intr de reloj
	mfc0 $t0, $12
	ori $t0, $t0, 0x8001
	mtc0 $t0, $12
	#Iniciar contador
	addi $t2, $0, 100	#Una por segundo
	mtc0 $t2, $11
	mtc0 $0, $9
	#Bucle del juego
	add $t2, $0, $0 #Inciar $t2 como pivote de los caracteres
	la $s0, char 
juego: 
	jal ReadChatacter
	jal PrintCharacter
	sb $a0, 0($s0)
	addi $s0, $s0, 1
	addi $t2, $t2, 1
	bne $a0, $t1, juego	#Comprobamos que el jugador a pulsado enter
	#fin del bucle
finIntr:
	#fin de la interrupción
	mfc0 $t0, $12
	xori $t0, $t0, 0x8001
	mtc0 $t0, $12
	#continuamos
	addi $t2, $t2, -1	#se le resta menos uno para quitar el enter
	lw $t3, countFrase
	bne $t3, $t2, mal 	#Si no tienen la misma cantidad de caracteres no serán iguales
	la $s0, char
	la $s1, frase1
	#Comprobamos si la frase escrita es igual a la del ejemplo
comp: 
	lb $t4, 0($s0)
	lb $t5, 0($s1)
	addi $s0, $s0, 1
	addi $s1, $s1, 1
	beqz $t5, correcta
	bne $t4, $t5, mal	#si no, no será la frase correcta
	j comp
correcta:
	li $v0, 4
	la $a0, correctafrase
	syscall
	#Imprimimos el cronómetro
	li $v0 , 1 
	add $a0, $s2, $0
	syscall
	li $v0 , 4  
	la $a0 , puntos
	syscall
	li $v0 , 1 
	add $a0, $s3, $0
	syscall
	li $v0 , 4  
	la $a0 , puntos
	syscall
	li $v0 , 1 
	add $a0, $s4, $0
	syscall
	li $v0 , 4  
	la $a0 , blanco
	syscall 
	j fin
mal: 
	li $v0, 4
	la $a0, malfrase
	syscall
fin:
	#Habilitar para que el usuario puedo decir si quere continuar o no
	li $v0, 4
	la $a0, frasefinal
	syscall
res: 
	jal ReadChatacter
	li $s8, 121 # 121-->y(yes)
	beq $a0, $s8, main
	li $s8, 110 # 110-->n(no)
	beq $a0, $s8, acabar
	j res
acabar:
	li $v0, 4
	la $a0, finProgrma
	syscall
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $31

#Haciendo uso de consultas de estado para la pantalla y el teclado
PrintCharacter: 
	lui $a1, 0xFFFF
	lb $0, 0xC($a1)
	sb $a0, 0xC($a1)
ctr: 
	lw $t0, 0x8($a1)
	andi $t0, $t0, 1
	beqz $t0, ctr
	jr $31

ReadChatacter: 
bucle: 
	lui $a1, 0xFFFF
	lw $t0, 0($a1)
	andi $t0, $t0, 1
	beqz $t0, bucle
	lb $a0, 4($a1)
	jr $31

Delay:
	li $a0, 420000	#420000 iter -->0.5s(aprox)
ret: 
	addi $a0, $a0, -1
	bnez $a0, ret 
	jr $31

.end


