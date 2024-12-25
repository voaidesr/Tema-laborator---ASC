.section .note.GNU-stack,"",@progbits
.data
    scanfFormat: .asciz "%ld"
    printfFormat1: .asciz "%ld: (%ld, %ld)\n"
    printfFormat2: .asciz "(%ld, %ld)\n"
    printfFormat3: .asciz "(0, 0)\n"
    printfFormat4: .asciz "%ld: (0, 0)\n"
    printfFormat5: .asciz "%ld "
    printFormat6: .asciz "\n Test: %ld \n"
    numberOfOperations: .long 0
    codification: .long 0
    N: .long 0
    ID: .long 0
    sz: .long 0
    # reprezentam fiecare indice in bytes, asa ca memoria trebuie sa aiba exact 1000 b
    memory: .space 1024, 0
    # tinem pana la 256 de descriptori, fiecare cu marime long, deci 254 * 4 = 1024
    size: .space 1024

# ##########################3
# caller saved: (se modifica) eax, ecx, edx
# restul (callee saved) trebuie restaurati

.text
# Functia shift_l
    shift_l:
        pushl %ebp
        movl %esp, %ebp
        pushl %ebx

        movl 8(%ebp), %ebx # ebx = position
        movl 12(%ebp), %edx # edx = amount
        addl %ebx, %edx # edx = position + amount
        movl %edx, %ecx # ecx = position + amount
        et_loop_shift:
            cmp $1024, %ecx
            je et_exit_shift
            
            xorl %eax, %eax
            movb memory(,%ecx,1), %al # ecx = i + amount
            movb %al, memory(,%ebx,1) # ebx = i
            xorl %eax, %eax
            movb %al, memory(,%ecx,1)

            incl %ebx
            incl %ecx
            jmp et_loop_shift

        et_exit_shift:
        popl %ebx
        popl %ebp
        ret
# Functia get_index (gaseste primul bloc al unui fisier)
    get_index:
        # argument: primeste un ID
        pushl %ebp
        movl %esp, %ebp
        pushl %ebx
        pushl %esi

        movl 8(%ebp), %ebx # ebx = ID
        xorl %esi, %esi
        et_get_index_loop:
            cmp $1024, %esi
            je et_finish_get_index_loop

            xorl %edx, %edx
            movb memory(,%esi,1), %dl
            cmp %edx, %ebx
            je et_found_index # v[i] == ID

            incl %esi
            jmp et_get_index_loop

        et_found_index:
            mov %esi, %eax # return i in eax
            jmp et_exit_get_index

        et_finish_get_index_loop:
            xorl %eax, %eax 

        et_exit_get_index:
        popl %esi
        popl %ebx
        popl %ebp
        ret

    # functia print_files()
    print_files:
        pushl %ebp
        movl %esp, %ebp
        pushl %ebx

        xorl %ecx, %ecx # i
        et_loop_print_files:
            cmp $1024, %ecx
            jae et_exit_loop_print_files
            xorl %ebx, %ebx
            movb memory(,%ecx,1), %bl # ebx = v[i]
 
            cmp $0, %ebx # if (!v[i])
            je et_iterate

            # what happens else
            pushl %ecx
            pushl %ebx
            call get_index # eax = get_index(v[i])
            popl %ebx
            popl %ecx
            
            movl size(,%ebx,4), %edx # edx = size[v[i]]
            addl %eax, %edx
            subl $1, %edx
            
            pushl %edx
            pushl %eax
            pushl %ebx
            push $printfFormat1
            call printf
            addl $4, %esp
            popl %ebx
            popl %eax
            popl %edx

            movl %edx, %ecx
            incl %ecx
            jmp et_loop_print_files

        et_iterate:
            incl %ecx
            jmp et_loop_print_files

        et_exit_loop_print_files:
        popl %ebx
        popl %ebp
        ret

    printMemory:
        pushl %ebp
        movl %esp, %ebp
        # registrul edi, ebx este callee saved
        pushl %edi
        pushl %ebx

        lea memory, %edi
        xorl %ecx, %ecx
        et_loop_print:
            cmp $1024, %ecx
            je et_print_exit

            # ecx e caller saved si va fi schimbat de functia printf
            pushl %ecx

            xorl %ebx, %ebx
            mov (%edi, %ecx, 1), %bl

            pushl %ebx
            pushl $printfFormat5
            call printf 
            addl $8, %esp
            
            # retrieveing ecx
            popl %ecx
            incl %ecx
            jmp et_loop_print

        et_print_exit:
            popl %ebx
            popl %edi
            popl %ebp
            ret
# ######################################################################################################
#
# Implementam functia ADD()
#
# ######################################################################################################
    func_ADD:
        pushl %ebp
        movl %esp, %ebp
        pushl %ebx
        pushl %esi

        # citim N - numarul de operatii
        pushl $N
        push $scanfFormat
        call scanf
        addl $8, %esp

        # facem for-ul care citeste urmatoarele 2N linii si adauga fisierele in memorie
        xorl %ecx, %ecx
        et_loop_ADD:
            cmp N, %ecx
            je et_exit_ADD
            # Citim ID-ul 
            pushl %ecx # ecx este modificat in printf
            pushl $ID
            push $scanfFormat
            call scanf
            addl $8, %esp
            popl %ecx

            movl ID, %ebx
            movl size(,%ebx,4), %edx
            cmp $0, %edx
            jne et_exit_find_sequence

            pushl %ecx
            # Citim size-ul
            pushl $sz
            push $scanfFormat
            call scanf
            addl $8, %esp
            popl %ecx # recuperam ecx

            # transformam size-ul in numar de blocuri
            xorl %edx, %edx
            movl sz, %eax
            addl $7, %eax
            movl $8, %ebx
            
            # vrem sa avem sz = sz / 8 daca e divizibila cu 8 si sz = sz / 8 + 1 daca nu e divizibila. echivalent cu a imparti sz + 7 la 8
            divl %ebx
            movl ID, %ebx
            movl %eax, size(, %ebx, 4) # size[ID] = sz

            # avem nevoie de size[ID] = eax
            # avem nevoie de un lenght = edx
            # avem nevoie un i = esi
            xorl %edx, %edx # lenght = 0
            xorl %esi, %esi # i = 0
            et_find_sequence:
                cmp $1024, %esi
                je et_exit_find_sequence # i = 1000

                xorl %ebx, %ebx
                movb memory(,%esi,1), %bl # ebx = v[i]
                cmp $0, %ebx
                jne et_nonzero_case

            et_zero_case:
                incl %edx
                cmp %eax, %edx
                je et_found_sequence
                incl %esi
                jmp et_find_sequence

            et_nonzero_case:
                xorl %edx, %edx
                incl %esi
                jmp et_find_sequence

            et_exit_find_sequence:
                movl ID, %ebx # avem ID 
                pushl %ecx
                pushl %ebx
                push $printfFormat4 # !!!!!!!!!
                                    # momentan, cand nu se gaseste spatiu pentru un fisier, se afiseaza (0, 0)
                                    # asta ca sa ma pliez pe teste
                                    # pe github am varianta care afiseaza ID: (0, 0) simple fix: inlocuiestie cu printfFormat4
                                    # vezi exact ce se cere
                                    # !!!!!!!!!
                call printf
                addl $8, %esp
                popl %ecx 

                pushl %eax # adaugat ulterior, doesn't really do anything, dar nu mai stiu daca am nevoie sau nu de eax
                movl ID, %ebx
                xorl %eax, %eax
                movl %eax, size(,%ebx,4)
                popl %eax
                jmp et_seq_exit             
            
            et_found_sequence:
                movl ID, %ebx # avem ID
                # avem i in esi - end_index
                movl %esi, %edx # edx = i
                subl %eax, %edx # edx = i - size[ID]
                addl $1, %edx
                pushl %ecx
                # printf("%d: (%d, %d)\n", ID, i - size[ID] + 1, i);
                pushl %esi
                pushl %edx
                pushl %ebx
                push $printfFormat1
                call printf
                addl $4, %esp
                popl %ebx
                popl %edx
                popl %esi
                popl %ecx

            et_fill_memory:
                # esi = i
                # edx = i - size[ID] + 1
                cmp %esi, %edx
                ja et_seq_exit
                movb %bl, memory(,%edx,1)
                incl %edx
                jmp et_fill_memory
 
            et_seq_exit:
            incl %ecx
            jmp et_loop_ADD

        et_exit_ADD:
            popl %esi
            popl %ebx
            popl %ebp
            ret
# ######################################################################################################
#
# Implementam functia GET
#
# ######################################################################################################
    func_GET:
        pushl %ebp
        movl %esp, %ebp
        pushl %ebx

        push $ID
        push $scanfFormat
        call scanf
        addl $8, %esp
        movl ID, %ebx # ebx = ID

        movl size(,%ebx,4), %edx # edx = size[ID]
        cmp $0, %edx
        je et_get_not_found

        pushl %edx
        pushl ID
        call get_index # eax va tine indexul
        popl %ebx
        popl %edx
        addl %eax, %edx
        subl $1, %edx

        pushl %edx
        pushl %eax
        push $printfFormat2
        call printf
        addl $12, %esp

        jmp et_exit_get

        et_get_not_found:
            push $printfFormat3
            call printf
            addl $4, %esp

        et_exit_get:
        popl %ebx
        popl %ebp
        ret

# ######################################################################################################
#
# Implementam functia DELETE()
#
# ######################################################################################################
    func_DELETE:
        pushl %ebp
        movl %esp, %ebp
        pushl %ebx

        push $ID
        push $scanfFormat
        call scanf
        addl $8, %esp
        movl ID, %ebx
        movl size(,%ebx,4), %edx # edx = size[ID]

        cmp $0, %edx # fisierul nu exista
        je et_exit_DELETE

        pushl %edx
        pushl %ebx
        call get_index # eax = index[ID]
        popl %ebx
        popl %edx

        # ebx = id
        # eax = i
        # edx = index + size[ID]
        addl %eax, %edx
        xorl %ecx, %ecx
        movl %ecx, size(,%ebx,4)
        et_loop_empty_memory:
            cmp %edx, %eax
            je et_exit_DELETE
            xorl %ecx, %ecx
            movb %cl, memory(,%eax,1)
            incl %eax
            jmp et_loop_empty_memory  

        et_exit_DELETE:
        call print_files
        popl %ebx
        popl %ebp
        ret

# ######################################################################################################
#
# Implementam functia DEFRAG()
#
# ######################################################################################################

    func_DEFRAG:
        pushl %ebp
        movl %esp, %ebp
        pushl %ebx

        et_while_defrag:
            pushl $0
            call get_index # eax = index = prima aparitie a lui 0
            addl $4, %esp

            # vedem daca in valoarea gasita in index este intr-adevar 0, daca nu, inseamna ca nu exista 0 si nu avem ce defragmenta
            xorl %ebx, %ebx
            movb memory(, %eax, 1), %bl
            cmp $0, %ebx
            jne et_exit_while_defrag

            movl %eax, %ebx # memoram eax in ebx
            

            xorl %edx, %edx # edx = amount we want to shift (acum 0)
            et_for_defrag:
                incl %edx # amount ++
                incl %eax # index ++

                cmp $1024, %eax
                je et_exit_while_defrag

                xorl %ecx, %ecx
                movb memory(,%eax,1), %cl
                cmp $0, %ecx
                jne et_exit_for_defrag

                jmp et_for_defrag

            et_exit_for_defrag:
            # edx = size
            # eax = index
            pushl %edx
            pushl %ebx # indicele original
            call shift_l
            addl $8, %esp
            
            jmp et_while_defrag
        et_exit_while_defrag:
        call print_files
        popl %ebx
        popl %ebp
        ret

.global main

main:
    # read the number of operations
    pushl $numberOfOperations
    push $scanfFormat
    call scanf
    addl $8, %esp
    xorl %ecx, %ecx
    et_loop_main:
        cmp numberOfOperations, %ecx
        je et_exit

        pushl %ecx
        pushl $codification # codificarea operatiei
        push $scanfFormat
        call scanf
        addl $8, %esp
        popl %ecx

        movl codification, %ebx

        cmp $1, %ebx
        je et_add

        cmp $2, %ebx
        je et_get

        cmp $3, %ebx
        je et_del

        cmp $4, %ebx
        je et_defrag

        et_add:
            pushl %ecx
            call func_ADD
            popl %ecx
            incl %ecx
            jmp et_loop_main

        et_get:
            pushl %ecx
            call func_GET
            popl %ecx
            incl %ecx
            jmp et_loop_main

        et_del:
            pushl %ecx
            call func_DELETE
            popl %ecx
            incl %ecx
            jmp et_loop_main

        et_defrag:
            pushl %ecx
            call func_DEFRAG
            popl %ecx
            incl %ecx
            jmp et_loop_main

et_exit:
    pushl $0
    call fflush
    popl %ebx

    movl $1, %eax
    movl $0, %ebx
    int $0x80
    