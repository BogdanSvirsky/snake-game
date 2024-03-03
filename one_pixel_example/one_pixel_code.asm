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

main>
    ldi r3, 1
    ldi r1, 0x8000
    beg1:
        shl r3
        cmp r3, r1
        blo beg1
    inc r2
    ldi r1, 1
    beg2:
        shr r3
        cmp r3, r1
        bne beg2
    ldi r0,16
    ldi r3,1
    cmp r2,r0
    ldi r1, 0x8000
    inc r2
    blo beg1
    halt
end.