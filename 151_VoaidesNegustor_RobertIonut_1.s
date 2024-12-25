.section .note.GNU-stack,"",@progbits
.data
    memory: .space 1048576, 0
    order: .space 256, 0
    size: .space 1024, 0
    N: .long 0
    ID: .long 0
    sz: .long 0
    i: .long 0
    j: .long 0
    k: .long 0
    length: .long 0
    numberOfOperations: .long 0
    codification: .long 0
    formatScanf: .asciz "%ld"
    formatPrintf1: .asciz "%ld: ((%ld, %ld), (%ld, %ld))\n"
    formatPrintf2: .asciz "%ld: ((0, 0), (0, 0))\n"
    formatPrintf3: .asciz "((%ld, %ld), (%ld, %ld))\n"
    formatPrintf4: .asciz "((0, 0), (0, 0))\n"
    formatPrintf5: .asciz "%ld "
.text

    # definim functia getIndex(ID, i, j)
    getIndex:
        pushl %ebp
        movl %esp, %ebp
        pushl %ebx

        xorl %eax, %eax
        movl %eax, i

        et_for_find_i:
            movl i, %eax
            cmp $1024, %eax
            jae et_exit_for_find_i

            xorl %eax, %eax
            movl %eax, j

            et_for_find_j:
                movl j, %eax
                cmp $1024, %eax
                jae et_exit_for_find_j

                xorl %edx, %edx
                movl i, %eax
                movl $1024, %ebx
                mull %ebx # eax = i * 1024
                addl j, %eax # eax = i * 1024 + j 

                xorl %ebx, %ebx
                movb memory(,%eax,1), %bl

                movl ID, %eax
                cmp %eax, %ebx
                je et_return # inseamna ca am gasit valoarea, ramane memory[i][j] pozitia in care am gasit valoarea cautata

                incl j
                jmp et_for_find_j

            et_exit_for_find_j:
            incl i
            jmp et_for_find_i

        et_exit_for_find_i:
        xorl %eax, %eax
        movl %eax, i
        movl %eax, j
        jmp et_return # cand iese din for natural, nu am gasit
        # ramane i = 0, j = 0

        et_return:
        popl %ebx
        popl %ebp
        ret

    # definim functia printFiles
    printFiles:
        pushl %ebp
        movl %esp, %ebp
        pushl %ebx

        xorl %eax, %eax
        movl %eax, i 
        et_for_i_files:
            movl i, %eax
            cmp $1024, %eax
            jae et_exit_for_i_files

            xorl %eax, %eax
            movl %eax, j

            et_for_j_files:
            movl j, %eax
            cmp $1024, %eax
            jae et_exit_for_j_files

            xorl %edx, %edx
            movl i, %eax
            movl $1024, %ecx
            mull %ecx 
            addl j, %eax  # eax = i * 1024 + j

            xorl %ecx, %ecx
            movb memory(,%eax,1), %cl 

            cmp $0, %ecx
            je et_increment_j

            movl size(,%ecx,4), %ebx
            addl j, %ebx
            subl $1, %ebx

            pushl %ebx
            pushl i
            pushl j
            pushl i
            pushl %ecx
            pushl $formatPrintf1
            call printf
            addl $20, %esp
            popl %ebx

            movl %ebx, j

            et_increment_j:
            incl j
            jmp et_for_j_files

            et_exit_for_j_files:
            incl i
            jmp et_for_i_files

        et_exit_for_i_files:
        popl %ebx
        popl %ebp
        ret

    # Definim functia ADD
    func_ADD:
        pushl %ebp
        movl %esp, %ebp
        pushl %ebx

        pushl $N 
        pushl $formatScanf
        call scanf 
        addl $8, %esp

        # for citire N perechi (ID, size)
        # tinem ecx = i
        xorl %ecx, %ecx
        et_for_read_ADD:
            cmp N, %ecx
            jae et_exit_for_read_ADD # iesim din for

            pushl %ecx
            pushl $ID
            pushl $formatScanf
            call scanf
            addl $8, %esp
            popl %ecx

            movl ID, %ebx
            movl size(,%ebx,4), %edx
            cmp $0, %edx
            jne et_no_seq_found_2 # in cazul in care avem un ID deja existent
            # !!!!!!
            # defineste o eticheta mai buna
            # aici iti goleste size-ul, in caz ca apare de doua ori 

            pushl %ecx
            pushl $sz
            push $formatScanf
            call scanf
            addl $8, %esp
            popl %ecx

            # transformam size-ul in numar de blocuri
            xorl %edx, %edx
            movl sz, %eax
            addl $7, %eax
            movl $8, %ebx
            divl %ebx
            movl ID, %ebx
            movl %eax, size(, %ebx, 4) # size[ID] = sz

            cmp $1, %eax
            jle et_no_seq_found

            # i = 0
            xorl %eax, %eax
            movl %eax, i

            # for-ul de cautare a unei secvente
            et_find_sequence_i:
                movl i, %eax
                cmp $1024, %eax
                jae et_no_seq_found

                xorl %eax, %eax
                movl %eax, length # length = 0

                # j = 0
                xorl %eax, %eax
                movl %eax, j
                et_find_sequence_j:
                    movl j, %eax
                    cmp $1024, %eax
                    jae et_exit_for_j

                    # vrem sa avem eax = i * 1024 + j
                    xorl %edx, %edx
                    movl i, %eax
                    movl $1024, %ebx
                    mull %ebx # eax = i * 1024
                    addl j, %eax
                    # ebx = memory[i][j]
                    xorl %ebx, %ebx
                    movb memory(,%eax,1), %bl

                    cmpb $0, %bl
                    jne et_else_find_seq

                    et_if_then_find_seq:
                    incl length
                    # gasim o secventa care poate memora fisierul
                    movl length, %eax
                    movl ID, %ebx
                    cmp size(,%ebx,4), %eax
                    je et_seq_found
                    incl j
                    jmp et_find_sequence_j

                    et_else_find_seq:
                    xorl %eax, %eax
                    movl %eax, length
                    incl j
                    jmp et_find_sequence_j

                et_exit_for_j:
                incl i
                jmp et_find_sequence_i
            
            # aici vom afisa cazul in care nu se poate stoca
            et_no_seq_found: 

            movl ID, %ebx
            xorl %eax, %eax
            movl %eax, size(,%ebx,4) # aici golim size[ID], pt ca nu putem memora fisierul cu descriptorul ID

            et_no_seq_found_2:

            movl ID, %ebx
            pushl %ecx
            pushl %ebx
            pushl $formatPrintf2 # afisam id: ((0, 0), (0, 0))
            call printf
            addl $8, %esp
            popl %ecx
            jmp et_exit_find_sequence

            # aici vom afisa unde se stocheaza
            et_seq_found:
            movl j, %eax
            movl ID, %ebx
            movl size(,%ebx,4), %edx
            subl %edx, %eax
            addl $1, %eax
            pushl %ecx
            pushl j
            pushl i
            pushl %eax # j - size + 1
            pushl i
            pushl ID
            pushl $formatPrintf1
            call printf
            addl $12, %esp
            popl %eax
            addl $8, %esp
            popl %ecx

            # aici il stocam efectiv
            et_fill_memory:
            pushl %ecx
            movl %eax, %ecx

            et_for_fill:
            cmpl j, %ecx
            ja et_fill_exit

            xorl %edx, %edx
            movl i, %eax
            movl $1024, %ebx
            mull %ebx
            addl %ecx, %eax

            xorl %ebx, %ebx
            movb ID, %bl
            movb %bl, memory(,%eax,1)

            incl %ecx
            jmp et_for_fill

            et_fill_exit:
            popl %ecx

            et_exit_find_sequence:
            incl %ecx
            jmp et_for_read_ADD

        et_exit_for_read_ADD:
            popl %ebx
            popl %ebp
            ret

# definim functia GET()
    func_GET:
        pushl %ebp
        movl %esp, %ebp

        pushl $ID
        pushl $formatScanf
        call scanf
        addl $8, %esp

        movl ID, %eax
        movl size(,%eax,4), %edx
        cmpl $0, %edx
        je et_file_not_found

        et_file_found:
            call getIndex
            movl j, %eax
            movl ID, %edx
            addl size(,%edx,4), %eax
            subl $1, %eax

            pushl %eax
            pushl i
            pushl j
            pushl i
            pushl $formatPrintf3
            call printf
            addl $20, %esp
            jmp et_exit_GET

        et_file_not_found:
            pushl $formatPrintf4
            call printf
            addl $4, %esp

        et_exit_GET:
        popl %ebp
        ret

# definim functia DELETE
    func_DELETE:
        pushl %ebp
        movl %esp, %ebp
        pushl %ebx

        pushl $ID
        pushl $formatScanf
        call scanf
        addl $8, %esp
        
        movl ID, %eax
        movl size(,%eax,4), %edx
        cmp $0, %edx
        je et_exit_delete

        call getIndex # avem i, j a.i. memory[i][j] = ID

        movl j, %eax
        movl ID, %edx
        addl size(,%edx,4), %eax
        movl %eax, length # length = j + size[ID]

        movl j, %ecx
        et_for_empty:
            cmp length, %ecx
            jae et_exit_delete

            xorl %edx, %edx
            movl i, %eax
            movl $1024, %ebx
            mull %ebx
            addl %ecx, %eax # eax = i * 1024 + ecx

            xorl %edx, %edx
            movb %dl, memory(,%eax,1)

            incl %ecx
            jmp et_for_empty

        et_exit_delete:
        movl ID, %edx
        xorl %eax, %eax
        movl %eax, size(,%edx,4)
        call printFiles
        popl %ebx
        popl %ebp
        ret

# definim functia DEFRAG
    func_DEFRAG:
        pushl %ebp
        movl %esp, %ebp
        pushl %ebx

        # golim vectorul order
        xorl %ecx, %ecx
        for_empty_order:
            cmp $256, %ecx
            jae exit_for_empty_order

            xorl %eax, %eax
            movb %al, order(,%ecx,1)

            incl %ecx
            jmp for_empty_order
        
        exit_for_empty_order:
        xorl %eax, %eax
        movl %eax, k 

        # extragem ordinea fisierelor din memorie
        movl %eax, i
        et_for_i_order:
            movl i, %eax
            cmp $1024, %eax
            jae et_exit_for_i_order

            xorl %eax, %eax
            movl %eax, j
            et_for_j_order:
                movl j, %eax
                cmp $1024, %eax
                jae et_exit_for_j_order

                xorl %edx, %edx
                movl i, %eax
                movl $1024, %ebx
                mull %ebx
                addl j, %eax # eax = i * 1024 + j

                xorl %edx, %edx
                movb memory(,%eax,1), %dl # edx = memory[i][j]

                cmpb $0, %dl
                je et_increment_j_order

                movl k, %ecx
                movb %dl, order(,%ecx,1)
                incl k

                movl size(,%edx,4), %eax
                addl j, %eax
                subl $1, %eax
                movl %eax, j

                et_increment_j_order:
                incl j
                jmp et_for_j_order

            et_exit_for_j_order:
            incl i 
            jmp et_for_i_order

        et_exit_for_i_order:
        # golim memoria
        xorl %eax, %eax
        movl %eax, i 

        et_for_empty_i:
            movl i, %eax
            cmp $1024, %eax
            jae et_exit_for_empty_i

            xorl %eax, %eax
            movl %eax, j 

            et_for_empty_j:
                movl j, %eax
                cmp $1024, %eax
                jae et_exit_for_empty_j

                xorl %edx, %edx
                movl i, %eax
                movl $1024, %ebx
                mull %ebx
                addl j, %eax # eax = memory[i][j]

                xorl %edx, %edx
                movb %dl, memory(,%eax,1)

                incl j
                jmp et_for_empty_j

            et_exit_for_empty_j:
            incl i 
            jmp et_for_empty_i
        et_exit_for_empty_i:

        # reumplem memoria
        xorl %eax, %eax
        movl %eax, k 
        movl %eax, i
        movl %eax, j

        et_while_refill:
            xorl %ecx, %ecx
            movl k, %eax
            movb order(,%eax,1), %cl
            cmpb $0, %cl
            je et_exit_while_refill

            movl size(,%ecx,4), %ebx
            addl j, %ebx # ebx = j + size[order[k]] 
            cmp $1024, %ebx
            ja et_cannot_fit_on_the_row

            et_can_fit_on_the_row: 
                movl size(,%ecx,4), %ebx
                addl j, %ebx
                et_for_1:
                    movl j, %ecx
                    cmp %ebx, %ecx
                    je et_iterate_rewrite

                    pushl %ebx
                    xorl %edx, %edx
                    movl i, %eax
                    movl $1024, %ebx
                    mull %ebx
                    addl j, %eax # eax = i * 1024 + j

                    movl k, %edx
                    xorl %ebx, %ebx
                    movb order(,%edx,1), %bl
                    movb %bl, memory(,%eax,1)
                    popl %ebx

                    incl j
                    jmp et_for_1
                
            et_cannot_fit_on_the_row:
                xorl %eax, %eax
                movl %eax, j
                incl i
                jmp et_can_fit_on_the_row

            et_iterate_rewrite:
            incl k
            jmp et_while_refill
        et_exit_while_refill:
        # afisam
        call printFiles
        popl %ebx
        popl %ebp
        ret

.global main
main:
    # read the number of operations
    pushl $numberOfOperations
    push $formatScanf
    call scanf
    addl $8, %esp
    xorl %ecx, %ecx
    et_loop_main:
        cmp numberOfOperations, %ecx
        jae et_exit

        pushl %ecx
        pushl $codification # codificarea operatiei
        push $formatScanf
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
    
