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
# r2 is X
# r3 is Y
# r6 is state
main>

    ldi r3, 0
    ldi r1, 15
    beg1:
        inc r3
        cmp r3, r1
        blo beg1
    inc r2
    inc r2
    ldi r1, 0
    beg2:
        dec r3
        cmp r3, r1
        bne beg2
    ldi r3,0
    cmp r2,r0
    ldi r1, 15
    inc r2
    inc r2
    blo beg1
    halt
end.