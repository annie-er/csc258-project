################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Magical Drop.
#
# Student 1: Annie Rong, 1010879694
# Student 2: Name, Student Number (if applicable)
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

colour_red: .word 0xff0000 # each .word stores 4 bytes
colour_green: .word 0x00ff00
colour_blue: .word 0x0000ff
colour_yellow: .word 0xffff00
colour_grey: .word 0x808080
colour_player: .word 0xffc0cb
##############################################################################
# Mutable Data
##############################################################################
playing_field: .space 392
player_col: .word 3 # start in middle
##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    # Initialize the game
    jal setup # pick random colours for balls
    jal draw_playing_field

game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep
    li $v0, 32
    li $a0, 5000
    syscall

    # 5. Go back to Step 1
    j game_loop

setup:
    la $t0, playing_field # address of 1st byte
    # initialize loop vars
    add $t1, $zero, $zero # iterator of loop
    addi $t2, $zero, 21 # initialize field with 3 rows (3 * 7)
    
setup_colours_loop:
    beq $t1, $t2, end_setup_loop
    # generate random num, stored in $a0 from 0 to 3
    li $v0, 42
    li $a0, 0
    li $a1, 4
    syscall
    
    # find address of random colour
    la $t3, colour_red	# get address of first colour and store in $t3
    sll $a0, $a0, 2 # shift $a0, the random num left by 2 bits = multiply by 4
    add $t3, $t3, $a0 # add this offset to find address of random colour
    lw $t4, 0($t3)
    sw $t4, 0($t0) # write colour to current cell
    
    # increment
    addi $t0, $t0, 4 # add 4 bytes to get to next cell, since $t0 stores address
    addi $t1, $t1, 1
    j setup_colours_loop

end_setup_loop:
    jr $ra

draw_playing_field:
    jr $ra