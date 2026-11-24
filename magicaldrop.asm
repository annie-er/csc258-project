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
colour_black: .word 0x000000
colour_player: .word 0xffc0cb
##############################################################################
# Mutable Data
##############################################################################
playing_field: .space 392 # stores the random colours for each cell, 14 * 7 * 4 bytes
player_col: .word 3 # start in middle
##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    # Initialize the game
    jal gen_random_colours # pick random colours for balls
    jal draw_border
    jal draw_playing_field
    jal draw_player

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

# function to store random colours for first 3 rows initially
gen_random_colours:
    la $t0, playing_field # address of 1st byte
    # initialize loop vars
    add $t1, $zero, $zero # iterator of loop
    addi $t2, $zero, 21 # initialize field with 3 rows (3 * 7)
    
gen_random_colours_loop:
    beq $t1, $t2, end_random_colours_loop
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
    sw $t4, 0($t0) # store colour to current cell of playing_field
    
    # increment
    addi $t0, $t0, 4 # add 4 bytes to get to next cell, since $t0 stores address
    addi $t1, $t1, 1
    j gen_random_colours_loop

end_random_colours_loop:
    lw $t3, colour_black
    addi $t2, $zero, 98 # 14 rows * 7 cols/row = 98 iterations, end

    black_loop:
        beq $t1, $t2, end_black_loop
        sw $t3, 0($t0) # make cell black
        addi $t0, $t0, 4 # next cell
        addi $t1, $t1, 1
        
        j black_loop
    end_black_loop:
        jr $ra

# follows branch_jump2 closely 
draw_border: 
    lw $t0, ADDR_DSPL # $t0 stores the base address for display
    # start drawing at x = 8 units = 32 bytes, y = 0; based off my sketch
    addi $t0, $t0, 32
    lw $t1, colour_grey
    
    # set height and width of our playing field (including border). will be used in loop
    addi $a0, $zero, 30 # height = 30 units
    addi $a1, $zero, 16 # width = 16 units
    
    add $t2, $zero, $zero # row index

draw_border_loop:
    beq $t2, $a0, end_border_loop
    add $t3, $zero, $zero # col index
    
draw_border_line_loop:
    beq $t3, $a1, end_border_line_loop 
    sw $t1, 0($t0) # draw pixel at memory location
    # increment 
    addi $t0, $t0, 4 # move to next unit, which is 4 bytes away
    addi $t3, $t3, 1 # update col counter
    
    j draw_border_line_loop # go back and iterate

end_border_line_loop:
    # calculated by sketch
    addi $t0, $t0, 64 # set $t0 to first unit of next row of playing field
    addi $t2, $t2, 1 # update row counter as well
    
    j draw_border_loop

end_border_loop:
    jr $ra

# follows branch_jump2 closely
draw_playing_field:
    lw $t0, ADDR_DSPL
    addi $t0, $t0, 164 # start drawing balls here; view sketch for why 164
    la $t1, playing_field # address of current unit
    
    addi $a0, $zero, 14 # height = 14 rows of units
    addi $a1, $zero, 7 # width = 7 cols per row

    add $t2, $zero, $zero # row index

draw_play_field_loop:
    beq $t2, $a0, end_play_field_loop
    add $t3, $zero, $zero # col index
    
draw_play_line_loop:
    beq $t3, $a1, end_play_line_loop 
    lw $t4, 0($t1) # store colour for this cell
    
    # draw 2 x 2 unit square
    sw $t4, 0($t0) # draw pixel at memory location, first row, left
    sw $t4, 4($t0) # second unit on same row, 1 unit right = 4 bytes
    sw $t4, 128($t0) # second row, left unit, 1 row down = 128 bytes
    sw $t4, 132($t0) # second row, right unit, 1 row down + 1 unit right

    # increment 
    addi $t0, $t0, 8 # move to next cell, 2 units away = 8 bytes
    addi $t1, $t1, 4 # move to next colour for cell 
    addi $t3, $t3, 1 # update col counter
    
    j draw_play_line_loop # go back and iterate

end_play_line_loop:
    # calculated by sketch
    addi $t0, $t0, 200 # set $t0 to first unit of next row of playing field
    addi $t2, $t2, 1 # update row counter as well
    
    j draw_play_field_loop

end_play_field_loop:
    jr $ra
    
draw_player:
    lw $t0, ADDR_DSPL
    addi $t0, $t0, 4004
    
    lw $t1, player_col # col player currently in
    sll $t1, $t1, 3 # multiplies by 2^3 = 8 bytes, for 2 units, for byte rep
    add $t0, $t0, $t1 # move that many bits to right
    
    lw $t2, colour_player
    sw $t2, 0($t0) # left unit of player
    sw $t2, 4($t0) # right unit of player
    
    jr $ra