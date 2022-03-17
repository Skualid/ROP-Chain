.data
.text
.global _start
_start:
        mov $0x2f, %al
        shr $4, %al

        mov $0x647773ff, %r12d # dws
        shr $8, %r12d
        mov $0x7361702f6374652f, %r13 # sap/cte/
        push %r12
        push %r13
        mov %rsp,%rdi #primer argumento

        xor %rbx, %rbx
        mov %bl,%sil   # segundo argumento un 0 (O_RDONLY)

        syscall #Hacemos la llamada open()


        cmp %rax,%rbx #comparacion
        jg error_open # salto cuando hay error en apertura (return value < 0)

        #si todo bien, continuamos

        mov %rax,%r12 #salvaguardo el valor de retorno de open()

        #Dejamos un hueco en la pila para el buffer
        mov $0x100, %r14w
        sub %r14, %rsp

start_loop:
        #xor %rbx, %rbx
        mov %rbx,%rax # read()
        mov %r12,%rdi 
        mov %rsp,%rsi 
        mov %r14,%rdx
        syscall #read(fd, buffer, N)

        mov %rax,%r13 #salvaguardo el valor de retorno de read()

        cmp %eax,%ebx
        jge final_loop #salgo del bucle cuando EOF ó error (return value <= 0) 


        mov $0x1fff, %ax #write()
        shr $12, %ax

        mov $0x1,%dil
        mov %rsp,%rsi
        mov %r13,%rdx
        syscall     #write(1,buffer,nr)

        jmp start_loop #salto incondicional

final_loop:
        mov $0x3,%al #close()

        mov %r12,%rdi
        syscall


        mov $0x3c,%al # exit()

        mov %bl,%dil # exit(0) -> sin errores (aunque no controlamos que read() nos de fallo :( )
        syscall

error_open:
        mov $0x3c, %al #exit(1)

        mov $0x1,%dil #exit(1) -> con error

        syscall