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
interfaz: .asciiz "\nQue hora es? \n"
hora: .asciiz "Hora: "
min:  .asciiz "Minutos: "
segun: .asciiz "Segundos: "
local: .asciiz "\nHora local "
puntos: .asciiz ":"
blanco: .asciiz "\n"
h:	.word 0
m: 	.word 0
s:  .word 0



	.text 0x400000
	.globl main
main: 
	jal KbdIntrEnable
	jal TimerIntrEnable
	#programa
	add $t9, $0,$0 #pivote de la hora
Frase:la $s0, f0
bucle: jal Delay
	lb $a0, 0($s0)
	jal PrintCharacter
	addi $s0, $s0, 1 
	bnez $a0, bucle
	j Frase
#Fin programa principal

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
	li $a0, 420000	#420000 iter -->0.5s(aprox)
ret: 
	addi $a0, $a0, -1
	bnez $a0, ret 
	jr $31



