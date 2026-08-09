.section .text.boot
.global _start
.global irq_enable
.global irq_disable
.global minux_user_svc_probe
.global minux_user_syscall
_start:
    ldr sp, =__stack_top
    mrs r0, cpsr
    bic r1, r0, #0x1f
    orr r1, r1, #0x12
    msr cpsr_c, r1
    ldr sp, =__irq_stack_top
    msr cpsr_c, r0
    ldr sp, =__stack_top
    bl install_vectors
    bl main
1:
    b 1b

install_vectors:
    ldr r0, =vectors_start
    mov r1, #0
    ldr r2, =vectors_end
2:
    cmp r0, r2
    ldrlo r3, [r0], #4
    strlo r3, [r1], #4
    blo 2b
    mcr p15, 0, r1, c7, c5, 0
    bx lr

irq_enable:
    mrs r0, cpsr
    bic r0, r0, #0x80
    msr cpsr_c, r0
    bx lr

irq_disable:
    mrs r0, cpsr
    orr r0, r0, #0x80
    msr cpsr_c, r0
    bx lr

irq_entry:
    sub lr, lr, #4
    stmfd sp!, {r0-r12, lr}
    bl minux_irq_handler
    ldmfd sp!, {r0-r12, pc}^

svc_entry:
    stmfd sp!, {r0-r12, lr}
    mrs r0, spsr
    ldr r1, [sp, #0]
    ldr r2, [sp, #4]
    ldr r3, [sp, #8]
    ldr r12, [sp, #52]
    stmfd sp!, {r12}
    bl minux_svc_handler
    add sp, sp, #4
    cmp r0, #0
    bne svc_return_kernel
    ldmfd sp!, {r0-r12, pc}^

svc_return_kernel:
    ldmfd sp!, {r0-r12, lr}
    mrs r0, cpsr
    bic r0, r0, #0x80
    msr cpsr_c, r0
    b user_probe_resume

minux_user_svc_probe:
    stmfd sp!, {r4, r5, lr}
    mrs r4, cpsr
    bic r0, r4, #0x1f
    orr r0, r0, #0x1f
    msr cpsr_c, r0
    ldr sp, =__user_probe_stack_top
    msr cpsr_c, r4
    mov r0, #0x10
    msr spsr_cxsf, r0
    ldr lr, =user_probe_start
    movs pc, lr

user_probe_start:
    mov r0, #42
    svc #0
    b .

user_probe_resume:
    ldmfd sp!, {r4, r5, pc}

minux_user_syscall:
    stmfd sp!, {r4, r5, lr}
    ldr r4, [sp, #12]
    mrs r5, cpsr
    bic r12, r5, #0x1f
    orr r12, r12, #0x1f
    msr cpsr_c, r12
    mov sp, r4
    msr cpsr_c, r5
    mov r12, #0x10
    msr spsr_cxsf, r12
    ldr lr, =user_syscall_start
    movs pc, lr

user_syscall_start:
    svc #0
    b .

.align 5
vectors_start:
    ldr pc, reset_vector
    ldr pc, undef_vector
    ldr pc, swi_vector
    ldr pc, pabort_vector
    ldr pc, dabort_vector
    ldr pc, reserved_vector
    ldr pc, irq_vector
    ldr pc, fiq_vector
reset_vector:    .word _start
undef_vector:    .word hang
swi_vector:      .word svc_entry
pabort_vector:   .word hang
dabort_vector:   .word hang
reserved_vector: .word hang
irq_vector:      .word irq_entry
fiq_vector:      .word hang
vectors_end:

hang:
    b hang
