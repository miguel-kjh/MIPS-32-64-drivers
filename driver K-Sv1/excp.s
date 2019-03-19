# SPIM S20 MIPS simulator.
# The default exception handler for spim.
#
# Copyright (c) 1990-2010, James R. Larus.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# Neither the name of the James R. Larus nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# Define the exception handling code.  This must go first!

	.kdata
__m1_:	.asciiz "  Exception "
__m2_:	.asciiz " occurred and ignored\n"
__e0_:	.asciiz "  [Interrupt] "
__e1_:	.asciiz	"  [TLB]"
__e2_:	.asciiz	"  [TLB]"
__e3_:	.asciiz	"  [TLB]"
__e4_:	.asciiz	"  [Address error in inst/data fetch] "
__e5_:	.asciiz	"  [Address error in store] "
__e6_:	.asciiz	"  [Bad instruction address] "
__e7_:	.asciiz	"  [Bad data address] "
__e8_:	.asciiz	"  [Error in syscall] "
__e9_:	.asciiz	"  [Breakpoint] "
__e10_:	.asciiz	"  [Reserved instruction] "
__e11_:	.asciiz	""
__e12_:	.asciiz	"  [Arithmetic overflow] "
__e13_:	.asciiz	"  [Trap] "
__e14_:	.asciiz	""
__e15_:	.asciiz	"  [Floating point] "
__e16_:	.asciiz	""
__e17_:	.asciiz	""
__e18_:	.asciiz	"  [Coproc 2]"
__e19_:	.asciiz	""
__e20_:	.asciiz	""
__e21_:	.asciiz	""
__e22_:	.asciiz	"  [MDMX]"
__e23_:	.asciiz	"  [Watch]"
__e24_:	.asciiz	"  [Machine check]"
__e25_:	.asciiz	""
__e26_:	.asciiz	""
__e27_:	.asciiz	""
__e28_:	.asciiz	""
__e29_:	.asciiz	""
__e30_:	.asciiz	"  [Cache]"
__e31_:	.asciiz	""
__excp:	.word __e0_, __e1_, __e2_, __e3_, __e4_, __e5_, __e6_, __e7_, __e8_, __e9_
	.word __e10_, __e11_, __e12_, __e13_, __e14_, __e15_, __e16_, __e17_, __e18_,
	.word __e19_, __e20_, __e21_, __e22_, __e23_, __e24_, __e25_, __e26_, __e27_,
	.word __e28_, __e29_, __e30_, __e31_
s1:	.word 0
s2:	.word 0



# This is the exception handler code that the processor runs when
# an exception occurs. It only prints some information about the
# exception, but can server as a model of how to write a handler.
#
# Because we are running in the kernel, we can use $k0/$k1 without
# saving their old values.

# This is the exception vector address for MIPS-1 (R2000):
#	.ktext 0x80000080
# This is the exception vector address for MIPS32:
	.ktext 0x80000180
# Select the appropriate one for the mode in which SPIM is compiled.
	.set noat
	move $k1 $at		# Save $at
	.set at
	sw $v0 s1		# Not re-entrant and we can't trust $sp
	sw $a0 s2		# But we need to use these registers

	mfc0 $k0 $13		# Cause register
	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f
	beqz $a0, CaseIntr

	# Print information about exception.
	#
	li $v0 4		# syscall 4 (print_str)
	la $a0 __m1_
	syscall

	li $v0 1		# syscall 1 (print_int)
	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f
	syscall

	li $v0 4		# syscall 4 (print_str)
	andi $a0 $k0 0x3c
	lw $a0 __excp($a0)
	nop
	syscall

	bne $k0 0x18 ok_pc	# Bad PC exception requires special checks
	nop

	mfc0 $a0 $14		# EPC
	andi $a0 $a0 0x3	# Is EPC word-aligned?
	beq $a0 0 ok_pc
	nop

	li $v0 10		# Exit on really bad PC
	syscall

ok_pc:
	li $v0 4		# syscall 4 (print_str)
	la $a0 __m2_
	syscall

	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f
	bne $a0 0 ret		# 0 means exception was an interrupt
	nop

# Interrupt-specific code goes here!
CaseIntr: 
	andi $a0, $k0, 0x0800 #¿Es el teclado?
	bne $a0, $0, tecInt
	andi $a0, $k0, 0x8000 #¿Es de timer?
	bne $a0, $0, timeInt
	# Interrupcion no reconocida 
	j retorno

tecInt: 
	addi $sp, $sp, -4	# guardamos el contenido del $ra para no afectar al main
	sw $31, 0($sp)
	jal KbdIntr		# rutina de servicio del teclado
	lw $31, 0($sp)
	addi $sp, $sp, 4	#Devolvemos el $ra
	j retorno

timeInt: 
	addi $sp, $sp, -4	# guardamos el contenido del $ra para no afectar al main
	sw $31, 0($sp)
	jal TimerIntr		# rutina de servicio del timer
	lw $31, 0($sp)
	addi $sp, $sp, 4	#Devolvemos el $ra
	j retorno
	
# Don't skip instruction at EPC since it has not executed.


ret:
# Return from (non-interrupt) exception. Skip offending instruction
# at EPC to avoid infinite loop.
#
	mfc0 $k0 $14		# Bump EPC register
	addiu $k0 $k0 4		# Skip faulting instruction
				# (Need to handle delayed branch case here)
	mtc0 $k0 $14

retorno: 
# Restore registers and reset procesor state
#
	lw $v0 s1		# Restore other registers
	lw $a0 s2

	.set noat
	move $at $k1		# Restore $at
	.set at

	mtc0 $0 $13		# Clear Cause register

	mfc0 $k0 $12		# Set Status register
	ori  $k0 0x1		# Interrupts enabled
	mtc0 $k0 $12

# Return from exception on MIPS32:
	eret

# Return sequence for MIPS-I (R2000):
#	rfe			# Return from exception handler
				# Should be in jr's delay slot
#	jr $k0
#	 nop

#Rutinas del Servicio de Interrupciones

#Del teclado
KbdIntr: 
	addi $sp, $sp, -32
	sw $a0, 0($sp)
	sw $s4, 4($sp)
	sw $s3, 8($sp)
	sw $s5, 12($sp)
	sw $s8, 16($sp)
	sw $t5, 20($sp)
	sw $t6, 24($sp)
	sw $t7, 28($sp)
	# guardamos en pila 
	lui $s3, 0xffff
	lb $s4, 4($s3)	# registramos la tecla pulsada
	addi $s5, $0, 0x12 	# 0x12 == CTRL+R
	beq $s5, $s4, pedirHora	#¿Se ha pulsado el comando?
	sw $s4, char	# guardamos en char la tecla pulsada
	lw $s4, n       # cargamos el contador de teclas
	addi $s3, $s4, 1 # n = n+1
	sw $s3, n       # guardamos el contador de teclas
	# Imprimimos 
	li $v0 , 4  
	la $a0 , teclado1
	syscall
	li $v0 , 1 
	add $a0, $s4, $0
	syscall
	li $v0 , 4  
	la $a0 , teclado2
	syscall
	li $v0 , 4  
	la $a0 , char
	syscall
	li $v0, 4
	la $a0, teclado3
	syscall
desapilar:
	mfc0 $s5, $9 
	mfc0 $s3, $11
	bgt $s3, $s5, continua # reinicaimos la cuenta si count supera a compare 
	mtc0 $0, $9
continua:
	lw $a0, 0($sp)
	lw $s4, 4($sp)
	lw $s3, 8($sp)
	lw $s5, 12($sp)
	lw $s8, 16($sp)
	lw $t5, 20($sp)
	lw $t6, 24($sp)
	lw $t7, 28($sp)
	addi $sp, $sp, 32
	# recuperamos los registros
	jr $31
pedirHora: 
	#registro pivote t9
	addi $t9, $0, 1
	#pedimos hora
	#Si algunos datos no son correctos se vuelve a pedir el dato correspondiente cada vez
	li $v0 , 4  
	la $a0 , interfaz
	syscall
	li $s8, 24
salto0:
	li $v0 , 4  
	la $a0 , hora
	syscall
	li $v0, 5
	syscall
	add $t5, $v0, 0
	bge $t5, $s8, salto0
	bltz $t5, salto0
	sw $t5, h
	li $s8, 60
salto1:
	li $v0 , 4  
	la $a0 , min
	syscall
	li $v0, 5
	syscall
	add $t6, $v0, 0
	bge $t6, $s8, salto1
	bltz $t6, salto1
	sw $t6, m
salto2:
	li $v0 , 4  
	la $a0 , segun
	syscall
	li $v0, 5
	syscall
	add $t7, $v0, 0
	bge $t7, $s8, salto2
	bltz $t7, salto2
	sw $t7, s
	j desapilar	


#Del timer
TimerIntr:
	addi $sp, $sp, -16
	sw $a0, 0($sp)
	sw $t5, 4($sp)
	sw $t6, 8($sp)
	sw $t7, 12($sp)
	beqz $t9, reinciar	#Si no se ha pedido la hora no se aumenta los registros
	lw $t5, h
	lw $t6, m
	lw $t7, s
	addi $t9, $t9, 1
	#Aumento de la hora
	addi $t7, $t7, 1
	addi $s8, $0, 60
	blt $t7, $s8, paso	# si los segundos llegan a 60, aumenta un minuto
	add $t7,$0,$0
	addi $t6,$t6,1
	blt $t6, $s8, paso  # si los minutos llegan a 60, aumenta una hora
	addi $s8, $0, 24
	add $t6, $0, $0
	addi $t5,$t5,1
	blt $t5, $s8, paso	#si las horas llegan a 24, vuelve a las 0:0:0
	add $t5, $0,$0 
paso: 
	sw $t5, h
	sw $t6, m
	sw $t7, s
	#Imprimir la hora
	li $a0, 6
	bne $a0, $t9, reinciar
	li $v0 , 4  
	la $a0 , local
	syscall
	li $v0 , 1 
	add $a0, $t5, $0
	syscall
	li $v0 , 4  
	la $a0 , puntos
	syscall
	li $v0 , 1 
	add $a0, $t6, $0
	syscall
	li $v0 , 4  
	la $a0 , puntos
	syscall
	li $v0 , 1 
	add $a0, $t7, $0
	syscall
	li $v0 , 4  
	la $a0 , blanco
	syscall 
	addi $t9, $0, 1
reinciar: 
	mtc0 $0, $9 # reiniciamos el count
	lw $a0, 0($sp)
	lw $t5, 4($sp)
	lw $t6, 8($sp)
	lw $t7, 12($sp)
	addi $sp, $sp, 16
	jr $31



# Standard startup code.  Invoke the routine "main" with arguments:
#	main(argc, argv, envp)
#
	.text
	.globl __start
__start:
	lw $a0 0($sp)		# argc
	addiu $a1 $sp 4		# argv
	addiu $a2 $a1 4		# envp
	sll $v0 $a0 2
	addu $a2 $a2 $v0
	jal main
	nop

	li $v0 10
	syscall			# syscall 10 (exit)

	.globl __eoth
__eoth:

