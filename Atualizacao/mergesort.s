    .section .text
    .globl main
main:
    # -------------------------------------------------
    # main: configura N e buffer_base = N, width = 1
    # -------------------------------------------------
    addi    x20, x0, 4       # x20 = N = 4 (também buffer_base)
    addi    x5,  x0, 1       # x5 = width_e

width_loop:
    # enquanto width_e < N
    bge     x5, x20, done

    addi    x6, x0, 0       # x6 = i_e

i_loop:
    # para cada bloco de 2*width_e
    bge     x6, x20, after_i_loop

    # mid_e = min(i_e + width_e, N)
    add     x7, x6, x5
    bge     x7, x20, mid_eq_N
    jal     x0, cont1
mid_eq_N:
    add     x7, x20, x0
cont1:

    # end_e = min(i_e + 2*width_e, N)
    slli    x17, x5, 1     # x17 = 2*width_e
    add     x8,  x6, x17   # x8 = i_e + 2*width_e
    bge     x8, x20, end_eq_N
    jal     x0, cont2
end_eq_N:
    add     x8, x20, x0
cont2:

    # pula se bloco vazio ou unitário
    bge     x7, x8, skip_merge

    # inicializa ponteiros
    add     x9,  x6,  x0   # left_e
    add     x10, x7,  x0   # right_e
    add     x11, x6,  x0   # j_e (índice no buffer)

merge_loop:
    # se um dos lados acabou, sai
    bge     x9,  x7, merge_remaining
    bge     x10, x8, merge_remaining

    # carrega left_val e right_val
    slli    x18, x9,  2    # offset_left_bytes
    lw      x12, 0(x18)    # left_val = A[left_e]
    slli    x18, x9, 2
    lw      x12, 0(x18)
    slli    x19, x10, 2    # offset_right_bytes
    lw      x13, 0(x19)    # right_val = A[right_e]

    # escolhe menor
    blt     x12, x13, left_smaller

right_smaller:
    # buffer[j_e] = right_val
    add     x21, x11, x20  # idx = j_e + buffer_base
    slli    x22, x21, 2
    sw      x13, 0(x22)
    addi    x11, x11, 1
    addi    x10, x10, 1
    jal     x0, merge_loop

left_smaller:
    # buffer[j_e] = left_val
    add     x21, x11, x20
    slli    x22, x21, 2
    sw      x12, 0(x22)
    addi    x11, x11, 1
    addi    x9,  x9,  1
    jal     x0, merge_loop

merge_remaining:
    # copia resto do left
merge_left_loop:
    bge     x9,  x7, copy_right_remaining
    slli    x18, x9, 2
    lw      x12, 0(x18)
    add     x21, x11, x20
    slli    x22, x21, 2
    sw      x12, 0(x22)
    addi    x11, x11, 1
    addi    x9,  x9,  1
    jal     x0, merge_left_loop

copy_right_remaining:
    # copia resto do right
merge_right_loop:
    bge     x10, x8, copy_back
    slli    x19, x10, 2
    lw      x13, 0(x19)
    add     x21, x11, x20
    slli    x22, x21, 2
    sw      x13, 0(x22)
    addi    x11, x11, 1
    addi    x10, x10, 1
    jal     x0, merge_right_loop

# -------------------------------------------------
# copy_back: copia buffer[0..(end_e- i_e)-1]
#           de volta para A[i_e..end_e-1]
# -------------------------------------------------
copy_back:
    add     x23, x6, x0    # k_e = i_e

copy_back_loop:
    bge     x23, x8, after_merge
    # lê do buffer
    add     x21, x23, x20
    slli    x22, x21, 2
    lw      x24, 0(x22)
    # escreve em A[k_e]
    slli    x25, x23, 2
    sw      x24, 0(x25)
    addi    x23, x23, 1
    jal     x0, copy_back_loop

after_merge:
skip_merge:
    # próximo bloco
    add     x6, x6, x17
    jal     x0, i_loop

after_i_loop:
    # dobra width_e
    slli    x5, x5, 1
    jal     x0, width_loop

done:
    # loop infinito
    jal     done
