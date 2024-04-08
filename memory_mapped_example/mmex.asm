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

# snake's coordinates - 0x00YX
snake_coords:
    ds 512
start_snake_coords: # pointer to first coords
    dc snake_coords
end_snake_coords: # place for new coords
    dc snake_coords

check_coords_pointers> # store pointer in r2
    ldi r3, snake_coords
    sub r2, r3
    ldi r4, 510
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
    st r2, r0
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
    ld r2, r0
    jsr turn_off_pixel
    jsr push_coords_to_display

    ldi r2, start_snake_coords
    ld r2, r2
    jsr check_coords_pointers
    ldi r3, start_snake_coords
    st r3, r2
    pop r0
    rts

main>
    ldi r0, 0x8800
    ld r0, r0
    jsr push_coords
    inc r0
    jsr push_coords
    inc r0
    jsr push_coords
    inc r0
    jsr push_coords
    inc r0
    jsr push_coords
    move_x:
        inc r0
        ldi r1, 0xff
        and r1, r0
        jsr push_coords
        jsr pop_coords
    move_y:
        ldi r1, 0x10
        add r1, r0
        ldi r1, 0xff
        and r1, r0
        jsr push_coords
        jsr pop_coords
        ldi r1, 0xf0
        and r0, r1
        tst r1
        bne move_x
end.