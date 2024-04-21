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
start_snake_coords: # pointer to first coords
    dc snake_coords
end_snake_coords: # place for new coords
    dc snake_coords
snake_length:
    dc 0

check_coords_pointers> # store pointer in r2
    ldi r3, snake_coords
    sub r2, r3
    ldi r4, 255
    if
        cmp r3, r4
    is eq
        ldi r2, snake_coords
    else
        inc r2
        inc r2
    fi
    rts

turn_on_pixel>
    ldi r2, 0x100
    or r2, r0
    rts

turn_off_pixel>
    ldi r2, 0xff
    and r2, r0
    rts

push_coords_to_display> # r0 - 0bMYYYYXXXX (M - mode)
    ldi r2, 0x200
    add r2, r0
    sub r0, r2
    move r2, r0
    ldi r1, 0xff
    and r1, r0
    rts

push_coords>
    ldi r2, end_snake_coords
    ld r2, r2
    stb r2, r0
    jsr check_coords_pointers
    ldi r3, end_snake_coords
    st r3, r2
    jsr turn_on_pixel
    jsr push_coords_to_display
    rts

pop_coords>
    push r0
    ldi r2, start_snake_coords
    ld r2, r2
    ldb r2, r0
    jsr turn_off_pixel
    jsr push_coords_to_display

    ldi r2, start_snake_coords
    ld r2, r2
    jsr check_coords_pointers
    ldi r3, start_snake_coords
    st r3, r2
    pop r0
    rts

move_up>
    ldi r1, 0b11110000
    and r0, r1
    ldi r2, 0b11110000
    if
        cmp r2, r1
    is eq
        jsr game_over
    else
        ldi r1, 0x10
        add r1, r0
        jsr push_coords
    fi
    rts

move_bottom>
    ldi r1, 0b11110000
    and r0, r1
    if
        tst r1
    is eq
        jsr game_over
    else
        ldi r1, 0x10
        sub r0, r1
        move r1, r0
        jsr push_coords
    fi
    rts

move_left>
    ldi r1, 0b1111
    and r0, r1
    if
        tst r1
    is eq
        jsr game_over
    else
        ldi r1, 0b1
        sub r0, r1
        move r1, r0
        jsr push_coords
    fi
    rts

move_right>
    ldi r1, 0b1111
    and r0, r1
    ldi r2, 0b1111
    if
        cmp r2, r1
    is eq
        jsr game_over
    else
        ldi r1, 1
        add r1, r0
        jsr push_coords
    fi
    rts

move_snake>
    ldi r1, 0x8800 # addres of keyboard input in memory
    # TODO: add snake's size changed logic
    ld r1, r1
    if
        tst r1
    is z
        rts
    fi
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
    jsr pop_coords
    rts

init_snake>
    ldi r0, 0 # init start coords
    jsr push_coords
    ldi r1, snake_length
    ld r1, r1
    inc r1 # init snake length 1
    ldi r2, snake_length
    st r2, r1
    rts

set_external_devices>
    # TODO: set addresses for external devices
    rts

generate_food>
    # we don't need to turn off the old pixel, because it is now part of the snake
    push r0
    do
        ldi r6, 1
        ldi r6, 0
        ldi r1, 0x8801
        ld r1, r0
        ldi r6, 0b10
        ldi r1, 0x8802
        ld r1, r1
        tst r1
    until z
    jsr turn_on_pixel
    jsr push_coords_to_display
    pop r0
    rts

game_over>
    # TODO: add game over logic
    halt
    rts

main>
    jsr set_external_devices
    jsr init_snake
    # jsr generate_food
    ldi r2, 256
    while
        cmp r2, r1
    stays gt
        jsr move_snake
        ldi r1, snake_length
        ld r1, r1
        ldi r2, 256
    wend
end.