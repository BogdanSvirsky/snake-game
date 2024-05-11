asect 0
main: ext               # Declare labels
default_handler: ext    # as external

# Interrupt vector table (IVT)
# Place a vector to program start and
# map all internal exceptions to default_handler
dc main, 0              # Startup/Reset vector
dc default_handler, 0   # Unaligned SP
dc default_handler, 0   # Unaligned PC
dc default_handler, 0   # Invalid instruction
dc default_handler, 0   # Double fault
align 0x80              # Reserve space for the rest 
                        # of IVT

# Exception handlers section
rsect exc_handlers

# This handler halts processor
default_handler>
    halt

# Main program section
rsect main
# r0 - display managment (by decoder)
# r6 - external devices managment
# snake's coordinates - 0x00YX
snake_coords:
    ds 256
start_snake_coords: # address of first coords
    dc snake_coords
end_snake_coords: # address of place for new coords
    dc snake_coords
snake_length:
    dc 0
snake_direction: # current direction of snake movement
    dc 0

external_devices_data: # allocating bytes for memory mapped I/O
    ds 16

update_coords_pointers> # updating start or end address of coords in circular buffer, need to store address in r2 (result also here)
    ldi r3, snake_coords
    sub r2, r3
    ldi r5, 255 # size of display - 1
    if
        cmp r3, r5
    is eq
        ldi r2, snake_coords # addres moves to beginning
    else
        inc r2 # address goes on
    fi
    rts

turn_on_pixel> # change pixel mode in r0
    ldi r2, 0x100 
    or r2, r0 # up bit 8 to 1 <=> set pixel's mode to on
    rts

turn_off_pixel> # change pixel mode in r0
    ldi r2, 0xff
    and r2, r0  # down bit 8 to 0 <=> set pixel's mode to off
    rts

push_coords_to_display> # transfer pixel in r0 to display, r0 - 0bMYYYYXXXX (M - mode)
    ldi r2, 0x200
    or r2, r0  
    sub r0, r2 # signal to display controller to transmit the pixel 
    move r2, r0
    ldi r1, 0xff 
    and r1, r0 # put r0 to the standart state (0x00YX)
    rts

push_coords> # push new pixel to snake
    ldi r2, end_snake_coords
    ld r2, r2
    stb r2, r0 # push new pixel in snake
    jsr update_coords_pointers
    ldi r3, end_snake_coords
    st r3, r2 # update address end_snake_coords in cyclic buffer
    jsr turn_on_pixel
    jsr push_coords_to_display # turn on new pixel on display 
    rts

pop_coords> # pop last pixel from snake
    push r0 # save value from r0, because it's current head coords
    ldi r2, start_snake_coords
    ld r2, r2
    ldb r2, r0 # get last pixel from snake
    jsr turn_off_pixel
    jsr push_coords_to_display

    ldi r2, start_snake_coords
    ld r2, r2
    jsr update_coords_pointers
    ldi r3, start_snake_coords
    st r3, r2 # update address start_snake_coords in cyclic buffer
    pop r0 # return r0 its correct value
    rts

move_up> # move the snake's head up
    ldi r1, 0b11110000
    and r0, r1
    ldi r2, 0b11110000 # when head stands next to board, Y coord is equal to 0b1111
    if
        cmp r2, r1
    is eq
        jsr game_over # when we can't move and the user loses 
    else
        ldi r1, 0x10 
        add r1, r0 # otherwise we increment Y coordinate 
    fi
    rts

move_bottom> # move the snake's head down, structure is equal to subroutine above
    ldi r1, 0b11110000
    and r0, r1
    if
        tst r1
    is eq
        jsr game_over # if Y coord = 0 we can't move down
    else
        ldi r1, 0x10
        sub r0, r1
        move r1, r0
    fi
    rts

move_left> # move the snake's head to the left, structure is equal to subroutine above
    ldi r1, 0b1111
    and r0, r1
    if
        tst r1
    is eq
        jsr game_over # if X coord = 0 we can't move left
    else
        ldi r1, 0b1
        sub r0, r1
        move r1, r0
    fi
    rts

move_right> # move the snake's head to the right, structure is equal to subroutine above
    ldi r1, 0b1111
    and r0, r1
    ldi r2, 0b1111
    if
        cmp r2, r1
    is eq
        jsr game_over # if X coord = 0b1111 we can't move left
    else
        ldi r1, 1
        add r1, r0
    fi
    rts

move_snake>
    ldi r1, external_devices_data # addres of keyboard input in memory
    ldb r1, r1
    if
        tst r1
    is z
        if 
            tst r4
        is z
            rts
        else
            move r4, r1
        fi
    fi

    move r1, r4

    ldi r2, 0b1
    if
        cmp r1, r2
    is eq
        jsr move_up
    else
        ldi r2, 0b10
        if
            cmp r1, r2
        is eq
            jsr move_right
        else
            ldi r2, 0b100
            if
                cmp r1, r2
            is eq
                jsr move_bottom
            else
                jsr move_left
            fi
        fi
    fi
    
    ldi r1, external_devices_data + 1
    ldb r1, r1
    if
        cmp r1, r0
    is eq
        jsr push_coords
        jsr eat_food
    else
        jsr check_pixel
        if
            tst r1
        is z
            jsr push_coords
            jsr pop_coords
        else
            jsr game_over
        fi
    fi
    rts

init_snake>
    ldi r0, 0               # init start coords
    jsr push_coords
    ldi r1, 1               # init snake length 1
    ldi r2, snake_length
    st r2, r1
    clr r4                  # snake hasn't direction at the beginning
    rts

set_external_devices>
    ldi r5, external_devices_data
    ldi r6, 0
    ldi r6, 0b1000
    ldi r6, 0
    rts

check_pixel>                            # store res to r1
    ldi r6, 0b10
    ldi r1, external_devices_data + 2
    ldb r1, r1
    ldi r6, 0
    tst r1
    rts

generate_food>                                  # we don't need to turn off the old pixel, because it is now part of the snake
    push r0
    do
        ldi r6, 1
        ldi r6, 0
        ldi r1, external_devices_data + 1
        ldb r1, r0
        jsr check_pixel
    until z
    jsr turn_on_pixel
    jsr push_coords_to_display
    pop r0
    rts

game_over>
    ldi r5, 0b100
    or r5, r6
    halt
    rts

win>
    halt
    rts

eat_food>
    ldi r1, snake_length
    ld r1, r1
    inc r1
    ldi r2, snake_length
    st r2, r1
    ldi r6, 0b10000
    clr r6
    ldi r1, external_devices_data + 3
    ldb r1, r1
    tst r1
    bnz win
    jsr generate_food
    rts

main>
    jsr set_external_devices
    jsr init_snake
    jsr generate_food
    while
        ldi r1, snake_length
        ld r1, r1
        ldi r2, 256
        cmp r2, r1
    stays gt
        jsr move_snake
    wend
end.