	.data 0xFFFF0000
tcontrol: .space 4 # dirección --> 0xFFFF0000 
tdata: .space 4 # dirección --> 0xFFFF0004 
pcontrol: .space 4 # dirección --> 0xFFFF0008 
pdata: .space 4 # dirección --> 0xFFFF000C


	.data 0x10000000
f0: .asciiz "En un lugar de la mancha de cuyo nombre...\n"
teclado1: .asciiz " [Pulsada("
teclado2: .asciiz ") = "
teclado3: .asciiz "] "
n: .word 1
char: .space 1
.align 2
interfaz: .asciiz "\n Que hora es? \n"
hora: .asciiz "Hora: "
min:  .asciiz "Minutos: "
segun: .asciiz "Segundos: "
local: .asciiz "\nHora local "
puntos: .asciiz ":"
blanco: .asciiz "\n"
h:	.word 0
m: 	.word 0
s:  .word 0

iter: .word 420000	#Numeró de iteraciones para el Delay
cuenta: .word 0 	#Contador de teclas y direciones
letraSi: .asciiz "\nLos caracteres que has tecleado hasta ahora son: "
letraNo: .asciiz "\nNo has tecleado nada\n"
inicio:  .asciiz "\nActivada cuenta de los caracteres\n"
Noinicio: .asciiz "\nDesactivada cuenta de los caracteres\n"
.align 2
cantidad: .space 200	#espacio reservado para las letras

	.text 0x400000
	.globl main
main: 
	jal KbdIntrEnable
	jal TimerIntrEnable
	#programa
	add $t9, $0,$0 		#pivote de la hora
	xor $s6,$s6,$s6		#registro pivote de las letras
Frase:la $s0, f0
bucle: jal Delay
	lb $a0, 0($s0)
	jal PrintCharacter
	addi $s0, $s0, 1 
	bnez $a0, bucle
	beqz $s6, Frase		#¿Se ha habilitado la impresión?
	#Empezamos
	lw $s5, cuenta
	beqz $s5, ninguna	#¿El usuario ha tecleado algún caracter?
	li $v0 , 4  
	la $a0 , letraSi
	syscall
	la $s3, cantidad
	lw $s4, n
	#bucle para imprimir las letras pulsadas
b0: lb $a0, 0($s3)
	jal PrintCharacter	#Se reutiliza PrintCharacter
	addi $s3, $s3, 1
	addi $s4, $s4, -1
	bnez $s4, b0
	#imprimimos un salto de línea para separar las letras
	li $v0 , 4  
	la $a0 , blanco
	syscall
	j Frase
ninguna: 
	li $v0 , 4  
	la $a0 , letraNo	#Se avisa que no se ha pulsado nada
	syscall
	#fin
	j Frase

PrintCharacter: 
	lb $0, pdata
	sb $a0, pdata
ctr: 
	lw $t0, pcontrol
	andi $t0, $t0, 1
	beqz $t0, ctr
	jr $31

KbdIntrEnable:
	#Activación de interrupción
	lw $t0, tcontrol
	ori $t0, $t0, 2
	sw $t0, tcontrol
	#Habilitas la interrupcción 
	mfc0 $t0, $12
	ori $t0, $t0, 0x801
	mtc0 $t0, $12
	jr $31

TimerIntrEnable:
	#Habilitamos la intr de reloj
	mfc0 $t0, $12
	ori $t0, $t0, 0x8001
	mtc0 $t0, $12
	#Iniciar contador
	addi $t2, $0, 100	#Una por segundo
	mtc0 $t2, $11
	mtc0 $0, $9
	jr $31

Delay:
	lw $a0, iter	#420000 iter -->0.5s(aprox)
ret: 
	addi $a0, $a0, -1
	bnez $a0, ret 
	jr $31

.end



