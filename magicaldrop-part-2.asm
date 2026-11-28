################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Magical Drop.
#
# Student 1: Annie Rong, 1010879694
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

# follows memory.asm example
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
playing_field: .space 392 # stores the random colours for each cell, 14 rows * 7 cols * 4 bytes
player_col: .word 3 # start in middle
collected_bubble_colour: .word 0 # colour of collected bubble
collected_bubble_count: .word 0 # # of bubbles collected
keystroke_count: .word 0 # # keystrokes since last new row

time_prev_row_pushed: .word 0 # capture time when prev row pushed
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

    # start counting time
    li $v0, 30
    syscall
    la $t9, time_prev_row_pushed
    sw $a0, 0($t9)

game_loop:
    # start of game loop: check time
    li $v0, 30
    syscall
    
    lw $t1, time_prev_row_pushed
    sub $t2, $a0, $t1 # get difference between current time - saved time
    
    addi $t3, $zero, 5000 # 5 seconds
    blt $t2, $t3, skip_push_new_row # don't need to push new row
    
    # proceed to push a new row if > 5 seconds
    la $t9, time_prev_row_pushed # get address
    sw $a0, 0($t9) # update saved time 
    jal push_new_row
    
    skip_push_new_row: 
        #nothing 
    
    # 1a. Check if key has been pressed, followed keyboard.asm
    lw $t0, ADDR_KBRD # $t0 = base address for keyboard
    lw $t8, 0($t0) # load first word from keyboard, which tells us if key pressed or not
    beq $t8, 1, keyboard_input  # if first word 1, key is pressed
    j end_keyboard_input # skip the below key responses

    # 1b. Check which key has been pressed, keyboard.asm
keyboard_input:
    lw $a0, 4($t0) # load second word from keyboard, which stores the actual key
    beq $a0, 0x61, respond_to_A # check if key a was pressed
    beq $a0, 0x64, respond_to_D # check if key d was pressed
    beq $a0, 0x73, respond_to_S # check if key s was pressed
    beq $a0, 0x71, respond_to_Q # check if the key q was pressed
    beq $a0, 0x77, respond_to_W # check if the key w was pressed
    j end_keyboard_input # skip past below if checks

respond_to_A:
    jal player_move_left
    j increment_num_keystrokes

respond_to_D:
    jal player_move_right
    j increment_num_keystrokes

respond_to_S:
    jal player_collect
    j increment_num_keystrokes

# followed keyboard.asm file
respond_to_Q:
    li $v0, 10
    syscall

respond_to_W:
    # we only delete if a player throws balls
    lw $t1, collected_bubble_count
    bne $t1, $zero, player_can_throw 
    j increment_num_keystrokes

player_can_throw: 
    jal player_throw
    jal delete_matches # only check for matches and delete after player throws
    j increment_num_keystrokes
    
# followed keyboard.asm file, and brunch_jump for divider and remainder logic
increment_num_keystrokes:
    lw $t1, keystroke_count # load actual 4 byte data value 
    addi $t1, $t1, 1 # increment the value
    la $t2, keystroke_count # load address of keystroke_count
    sw $t1, 0($t2) # store word (4 bytes) into that address of keystroke_count (saving in mem)
    
    # divide by 10 and check if it's divisible w/o remainders
    addi $t9, $zero, 10 # store 10
    div $t1, $t9
    mfhi $t8 # remainder
    # check if the remainder is zero or not
    bne $t8, $zero, end_keyboard_input 
    # jal push_new_row # not needed

end_keyboard_input:
# nothing

    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	jal draw_playing_field
    jal draw_player
    jal check_game_over 
	
	# 4. Sleep
    li $v0, 32
    li $a0, 16 # 1 second = 1000 ms, 60 frames per second = 16ms/frame (mentioned in slides)
    syscall

    # 5. Go back to Step 1
    j game_loop

# function to store random colours for first 3 rows initially of playing field
gen_random_colours:
    la $t0, playing_field # address of 1st byte
    # initialize loop vars
    add $t1, $zero, $zero # iterator of loop
    addi $t2, $zero, 21 # initialize field with 3 rows (3 * 7)
    
gen_random_colours_loop:
    beq $t1, $t2, end_random_colours_loop
    # generate random num, stored in $a0 from 0 to 3, follow syscall.asm
    li $v0, 42
    li $a0, 0
    li $a1, 4
    syscall
    
    # find address of random colour
    la $t3, colour_red	# get address of first colour and store in $t3
    sll $a0, $a0, 2 # $a0 gives num from 0-3, but we need a byte offset, so sll = multiply by 2^2 = 4 bytes
    add $t3, $t3, $a0 # add this offset to find address of random colour
    lw $t4, 0($t3)
    sw $t4, 0($t0) # store colour to current cell of playing_field
    
    # increment
    addi $t0, $t0, 4 # add 4 bytes to get to next cell, since $t0 stores address
    addi $t1, $t1, 1
    j gen_random_colours_loop

end_random_colours_loop:
    # populate rest of cells black
    lw $t3, colour_black
    addi $t2, $zero, 98 # where to end: 14 rows * 7 cols/row = 98 iterations

    black_loop:
        beq $t1, $t2, end_black_loop
        sw $t3, 0($t0) # make cell black
        addi $t0, $t0, 4 # next cell
        addi $t1, $t1, 1
        
        j black_loop
    end_black_loop:
        jr $ra

# control movements
player_move_left:
    lw $t1, player_col
    la $t9, player_col
    
    beq $t1, $zero, teleport_to_right # check before moving: already at the leftmost col, -1 wrap around to right
    addi $t1, $t1, -1 # move 1 col to left
    
    sw $t1, 0($t9) # save updated col
    jr $ra

teleport_to_right: # EASY FEAT
    addi $t2, $zero, 6 # new col to 6
    sw $t2, 0($t9)
    jr $ra

player_move_right:
    lw $t1, player_col
    la $t9, player_col
    
    addi $t2, $zero, 6 # we need to store 6 bc beq compares registers
    beq $t1, $t2, teleport_to_left # check before +1, if already at rightmost col, wrap around to left
    
    addi $t1, $t1, 1 # move 1 col to right
    sw $t1, 0($t9) # save updated col
    jr $ra

teleport_to_left:
    sw $zero, 0($t9) # new col at 0
    jr $ra

player_collect:
    la $t0, playing_field # address
    addi $t0, $t0, 364 # skip 13 rows before the last (14th) = 13 rows * 7 cols * 4 bytes
    lw $t1, player_col # load player col
    sll $t1, $t1, 2 # turn player col to bytes so that we can get address; multiplies by 2^2 = 4 bytes
    add $t0, $t0, $t1 # get the exact address of player (+ col on 13th row)
    
    addi $t2, $zero, 13 # index of row; start at bottom
    addi $t3, $zero, -1 # stop when row index is past index 0 (top)
    lw $t7, colour_black # load the value of a black colour

# 1. find bottom bubble in player's col
find_first_ball_loop:
    beq $t2, $t3, end_player_collect_loop # when we reached the top
    lw $t4, 0($t0) # load value at address, which stores the colour
    bne $t4, $t7, found_first_ball # if colour is not black, we found a ball
    
    # update indexes
    addi $t0, $t0, -28 # move to row above, bytes
    addi $t2, $t2, -1 # decrement to row above, index
    
    j find_first_ball_loop # loop again
    
# 2. can it be collected?
found_first_ball:
    lw $t5, collected_bubble_count # load # of balls collected
    
    # 2 possibilities:
    beq $t5, $zero, set_collected_colour # currently have no balls collected
    j check_same_colour_as_collected # else: we do have balls
 
# possibility 1: this ball becomes the colour we are collecting
set_collected_colour:
    la $t9, collected_bubble_colour # load address of collected_bubble_colour
    sw $t4, 0($t9) # saves colour to collected_bubble_colour
    
    add $t6, $zero, $t4 # $t6 stores the colour we're collecting
    
    j collect_balls_loop # now collect balls

# possibility 2: we already collected balls
check_same_colour_as_collected: 
    lw $t6, collected_bubble_colour # $t6 loads the colour we collected
    bne $t4, $t6, end_player_collect_loop # if colour is not same, we don't collect
    
    j collect_balls_loop # else, collect balls
    
# 3. if yes, collect
collect_balls_loop:
    beq $t2, $t3, end_player_collect_loop
    
    lw $t8, 0($t0) # $t8 stores colour at this cell
    bne $t8, $t6, end_player_collect_loop # the colour at cell != colour we're collecting
    
    # collect, make this cell black
    sw $t7, 0($t0)
    
    # update values
    addi $t5, $t5, 1 # collected a ball, $t5 stores count of balls collected
    la $t9, collected_bubble_count # get address of bubble count
    sw $t5, 0($t9) # update count
    
    addi $t0, $t0, -28 # move to row above
    addi $t2, $t2, -1 # move index to row above
    
    j collect_balls_loop 

end_player_collect_loop:
    jr $ra

# follows branch_jump2.asm example closely 
draw_border: 
    lw $t0, ADDR_DSPL # $t0 stores the base address for display
    # start drawing at x = 8 units = 32 bytes, y = 0; based off my sketch
    addi $t0, $t0, 32 # start of display address + 32 bytes
    lw $t1, colour_grey
    
    # set height and width of our playing field (including border). will be used in loop
    addi $a0, $zero, 30 # height = 30 units
    addi $a1, $zero, 16 # width = 16 units
    
    add $t2, $zero, $zero # row index

# nester for loop: row, 0 - 29, col: 8 - 24
draw_border_loop:
    beq $t2, $a0, end_border_loop # iterate thru rows
    add $t3, $zero, $zero # col index

# iterate thru cols
draw_border_line_loop:
    beq $t3, $a1, end_border_line_loop # cols are all iterated thru
    sw $t1, 0($t0) # draw pixel at memory location
    # increment 
    addi $t0, $t0, 4 # move to next unit, which is 4 bytes away
    addi $t3, $t3, 1 # update col counter
    
    j draw_border_line_loop # go back and iterate

end_border_line_loop:
    # calculated by sketch
    addi $t0, $t0, 64 # set $t0 to first unit of next row of playing field, see sketch
    addi $t2, $t2, 1 # update row counter as well
    
    j draw_border_loop

end_border_loop:
    jr $ra

# follows branch_jump2.asm example closely
draw_playing_field:
    lw $t0, ADDR_DSPL
    addi $t0, $t0, 164 # start drawing balls here; view sketch for why 164
    la $t1, playing_field # address of current cell
    
    addi $a0, $zero, 14 # height = 14 rows of cells
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
    addi $t0, $t0, 8 # move to next cell, 2 units away = 8 bytes (since 1 unit = 4 bytes)
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
    addi $t0, $t0, 4004 # row 31, 32 units per row, 1 unit = 4 bytes + col 9 = (31 * 32 * 4) + (9 * 4) 
    lw $t3, colour_black
    
    add $t4, $zero, $zero # col index
    addi $t5, $zero, 14 # the width is 14 units
    
# loop through player row and make all black
refresh_player_position_loop:
    beq $t4, $t5, end_player_position_loop 
    sw $t3, 0($t0) # black
    
    # increment values
    addi $t4, $t4, 1 # move to next col
    addi $t0, $t0, 4 # move to next unit in memory
    
j refresh_player_position_loop
    
end_player_position_loop:
    # draw the new position
    lw $t0, ADDR_DSPL
    addi $t0, $t0, 4004 # get to the start of player position
    
    lw $t1, player_col # col player currently in
    sll $t1, $t1, 3 # multiplies by 2^3 = 8 bytes, because 1 unit = 4 bytes, and each cell is 2 units = 8 bytes
    add $t0, $t0, $t1 # move that many byts to right
    
    lw $t2, colour_player
    sw $t2, 0($t0) # left unit of player
    sw $t2, 4($t0) # right unit of player
    
    jr $ra
    
push_new_row:
    # start from row 12 and copy each row to row below it
    la $t0, playing_field
    
    addi $t0, $t0, 336 # start at row 12
    
    addi $t2, $zero, 12 # row index
    addi $t3, $zero, -1 # stop when row index passes row 0
    
copy_row_loop:
    beq $t2, $t3, end_copy_row_loop 
    add $t4, $zero, $zero # col index
    addi $t5, $zero, 7 # 7 cols per row
    
copy_col_loop:
    beq $t4, $t5, end_copy_col_loop 
    lw $t6, 0($t0) # load the colour of the cell
    sw $t6, 28($t0) # copy the colour to col a row below (1 row = 28 bytes)

    # update indices
    addi $t0, $t0, 4 # next unit in row
    addi $t4, $t4, 1
    
    j copy_col_loop
    
end_copy_col_loop:
    addi $t0, $t0, -56 # go up to previous row, -28 for undo this row, to begin, and -28 for go row up
    addi $t2, $t2, -1 # row index - 1
    
    j copy_row_loop

end_copy_row_loop: 
    # populate row 0 with random colours
    la $t0, playing_field # go back to first address of playing field
    # initialize loop vars
    add $t1, $zero, $zero # iterator of loop, col
    addi $t2, $zero, 7 # go up to 7 cols
    
# populate the first row with random generated colours
fill_first_row_loop:
    beq $t1, $t2, end_fill_first_row_loop
    # generate random num, stored in $a0 from 0 to 3, same as my gen_random_colours
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
    j fill_first_row_loop

end_fill_first_row_loop:
    jr $ra

# throw collected bubbles at column player currently in, below rows with bubbles
player_throw:
    # start at top of player's col
    la $t0, playing_field # address of playing field (row 0)
    lw $t1, player_col # load player col
    sll $t1, $t1, 2 # turn player col to bytes; multiplies by 2^2 = 4 bytes
    add $t0, $t0, $t1 # get the exact position of player in row 0
    
    # indices
    addi $t2, $zero, 0 # index of row; start at top
    addi $t3, $zero, 14 # stop when row index reaches bottom
    
    # important variables to track:
    lw $t5, collected_bubble_count # collected balls count
    lw $t6, collected_bubble_colour # collected balls colour
    lw $t7, colour_black # load the value of a black colour
    
# 1. find first empty row in player's col, loop down from i = 0 to 13, stop at 14
find_first_empty_row_loop:
    beq $t2, $t3, end_find_first_empty_row_loop # when we passed the bottom
    lw $t4, 0($t0) # load value at address, which stores the colour
    beq $t4, $t7, throw_bubble_loop # if colour is black, we found the first empty slot

    # update indexes
    addi $t0, $t0, 28 # move to row below, bytes
    addi $t2, $t2, 1 # increment to row below, index
    
    j find_first_empty_row_loop # loop again

# 2. now, we place balls down
throw_bubble_loop:
    # 2 conditions to stop loop:
    beq $t5, $zero, end_throw_bubble_loop # no more balls to throw
    beq $t2, $t3, end_throw_bubble_loop # we reached end
    
    sw $t6, 0($t0) # copy the collected ball colour to this byte position
    
    # update variables
    addi $t5, $t5, -1 # decrease collected balls
    addi $t0, $t0, 28 # go to row below
    addi $t2, $t2, 1 # go to index row below
    
    j throw_bubble_loop

end_throw_bubble_loop: 
    # update the memory
    la $t9, collected_bubble_count
    sw $t5, 0($t9) # update
    
end_find_first_empty_row_loop: 
    jr $ra

delete_matches: 
    # same logic as collect balls
    la $t0, playing_field # address
    addi $t0, $t0, 364 # this is the byte at the 1st cell of 13th row (last)
    lw $t1, player_col # load player col
    sll $t1, $t1, 2 # turn player col to bytes; multiplies by 2^2 = 4 bytes
    add $t0, $t0, $t1 # get the exact position of player (+ col on 13th row)
    
    addi $t2, $zero, 13 # index of row; start at bottom
    addi $t3, $zero, -1 # stop when row index is past index 0 (top)
    lw $t7, colour_black # load the value of a black colour

# 1. find bottom bubble in player's col to start deleting
find_bottom_ball_can_delete_loop:
    beq $t2, $t3, end_delete_matches # when we reached the top
    lw $t4, 0($t0) # load value at address, which stores the colour
    bne $t4, $t7, found_bottom_ball_can_delete # if colour is not black, we found a ball
    
    # update indexes
    addi $t0, $t0, -28 # move to row above, bytes
    addi $t2, $t2, -1 # decrement to row above, index
    
    j find_bottom_ball_can_delete_loop # loop again

found_bottom_ball_can_delete: 
    # initial loop vars
    add $t6, $zero, $t4 # $t6 stores the colour on the last row, the one we need to match against
    
    add $t5, $zero, $zero # # of same-coloured balls in that col
    # add $t8, $zero, $t0 # address of bottom ball; to use when we delete 
    
count_num_matching_balls:
    # we loop up
    beq $t2, $t3, end_count_num_matches_loop # when we reached the top, we stop
    lw $t9, 0($t0) # load value at address, which stores the colour
    
    bne $t9, $t6, end_count_num_matches_loop # we also stop if colour doesn't match
    
    # update variables
    addi $t5, $t5, 1 # increment the num of same coloured balls
    addi $t0, $t0, -28 # move to row above, bytes
    addi $t2, $t2, -1 # decrement to row above, index
    
    j count_num_matching_balls
    
end_count_num_matches_loop: 
    # check if we had 3 or more matches 
    # if we only had 1 or 2, we do nothing
    beq $t5, 1, end_delete_matches
    beq $t5, 2, end_delete_matches
    
    # else: delete
    # initialize variables for looping
    add $t1, $zero, $zero # counter to keep track of num matches
    addi $t0, $t0, 28 # set address of playing_field to go down 1 row to address of ball of the top match

delete_matches_loop:
    beq $t1, $t5, end_delete_matches
    
    # set cell to black
    sw $t7, 0($t0) 
    
    # update vars
    addi $t1, $t1, 1 # update counter
    addi $t0, $t0, 28 # move row down

    j delete_matches_loop

end_delete_matches: 
    jr $ra

check_game_over:
    # if any unit in row 13 has a bubble (the value is not black), game becomes over
    la $t0, playing_field
    addi $t0, $t0, 364 # start of row 13 = 13 * 7 * 4 bytes
    lw $t7, colour_black
    
    add $t1, $zero, $zero # index of cols
    addi $t2, $zero, 7 # 7 cols

# loop through cols
loop_through_last_row:
    beq $t1, $t2, end_last_row_loop # we looped through entire row, stop
    lw $t3, 0($t0)
    bne $t3, $t7, end_game # we have a colour in last row != black
    
    # update indices
    addi $t1, $t1, 1 # move to next index
    addi $t0, $t0, 4 # move to next byte
    
    j loop_through_last_row
    
end_last_row_loop:
    jr $ra
    
end_game:
    # something i noticed: increment_num_keystrokes would jump to check_game_over 
    # then check_game_over ends the game
    # but this is before anything is drawn, so user doesn't see the final state 
    # but now i fixed it, so final state is shown, because called after drawing
    li $v0, 10
    syscall
    