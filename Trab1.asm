;***********************************************************************AUTORES***************************************************************************************
;*************************************************************ERICH MORAIS E GUILHERME MORAIS*************************************************************************
;**************************************************************ARQUITETURA DE COMPUTADORES****************************************************************************
.model small
.stack 100h
.data
;********************************************************************************************************************************************************************;

matriz_de_bombas dw 800 dup(0)          ; Numero maximo de linhas e colunas, respectivamente.

linha db 00h                            ;criacao de variaveis funcao pseudo_aleatorio
coluna db 00h
multiplicador_a db 00h
mod_divisao dw 00h
incremento_c dw 00h
semente_x dw 00h
contador db 00h
bomba db 00h

mouse_x dw  00h                             ;Variaveis do mouse
mouse_y dw  00h
verif_mouse_clicado db 00h

segundos dw 3030h                            ;Variaveis do Cronometro
segundos_len equ $-segundos
minutos dw 3030h
minutos_len equ $-minutos
seconds  db 99

marked_bombs dw 3030h                       ;Variaveis da escrita
marked_bombs_len equ $-marked_bombs

game_name_msg db "C A M P O  M I N A D O"
game_name_len equ $-game_name_msg


configuracoes_msg db "C O N F I G U R A C O E S"
configuracoes_len equ $-configuracoes_msg

autores_msg db "GUILHERME E ERICH MORAIS"
autores_len equ $-autores_msg

numero_msg db "NUMERO DE MINAS (>=5): "
numero_len equ $-numero_msg

largura_msg db "LARGURA DO CAMPO [5:40]: "
largura_len equ $-largura_msg

altura_msg db "ALTURA DO CAMPO [5:20]: "
altura_len equ $-altura_msg

esc_msg db "[ESC] SAIR"
esc_len equ $-esc_msg

erro_msg db "V A L O R  I N C O R R E T O"
erro_len equ $-erro_msg

time_msg db "TEMPO"
time_len equ $-time_msg

markedBombsMessage db "BOMBAS MARCADAS"
markedBombsMessage_len equ $-markedBombsMessage

gameover_msg db "*** F I M  D E  J O G O ***"
gameover_len equ $-gameover_msg

lost_msg db " L E V O U  B O M B A ! "
lost_len equ $-lost_msg

win_msg db "P A R A B E N S !"
win_len equ $-win_msg

again_msg db "Pressione a tecla [N] para jogar novamente, a tecla [I] para ir a tela inicial  ou [ESC] p/ sair"
again_len equ $-again_msg
;********************************************************************************************************************************************************************;
.code

push_all MACRO  ; macro para salvar o contexto
    push ax
    push bx
    push cx
    push dx
    ;;;;;;;
    push si
    push di
    push bp
endm
;********************************************************************************************************************************************************************;
pop_all MACRO      ; macro para restaurar o contexto
    pop bp
    pop di
    pop si
    ;;;;;;
    pop dx
    pop cx
    pop bx
    pop ax
endm
;********************************************************************************************************************************************************************;
delay proc          ; proc para criar delay
    push_all
    mov ax,8600h    ; ax 86 faz esperar wait
    mov cx,5bh      ; numero de microsegundos a esperar high byte = 5b
    mov dx,8d80h    ; numero de microsegundos a esperar low byte = 8d80 = 5.000.000 milhoes
    int 15h         ; int 15h diversos servicos do sistema
    pop_all
ret
endp
;********************************************************************************************************************************************************************;
stop proc
    push ax
    xor ax,ax      ; zera para (ler tecla pressionada) com int 16
    int 16h        ; int que interrompe chamada (teclado)
    pop ax
ret
endp
;********************************************************************************************************************************************************************;
clear_screen_40x25 proc
    push_all
    xor bx,bx          ;zera representa a cor
    xor cx,cx          ;zera linha de cima e col da esquerda
    mov ax,0600h       ;al 00 = limpa a tela inteira pois representa quantidade de linhas para (scroll) 40x25
    mov dx,2439h       ;DH e a linha canto inferior e DL a coluna da direita
    int 10h            ;int de video
    pop_all
ret
endp
;********************************************************************************************************************************************************************;
clear_screen_80x25 PROC ; Limpa a tela
    push ax
    mov ah,00h  ;modo de video
    mov al,03h  ;text mode. 80x25. 16 colors. 8 pages.
    int 10h     ;int de video
    pop ax
ret
endp
;********************************************************************************************************************************************************************;
read_char proc
    push ax
    mov ax,0200h        ;ah AH = 02h write one char to standart output DL = key pressed
    int 21h             ;int dos
    pop ax
ret
endp
;********************************************************************************************************************************************************************;
clear_memory proc       ;logica para limpar a memoria
    push dx
    push bx
    mov bx,10
    div bx
    pop bx
ret
endp
;********************************************************************************************************************************************************************;
backspace_clear proc
    push ax
    push dx
    mov ah,02h          ;escreve char para a saida padrao
    mov dl,08h          ;char a ser escrito backspace que eh 08
    int 21h             ;int dos
    mov dl,20h          ;aqui segue a mesma logica pro espaco ate acabar
    int 21h
    mov dl,08h
    int 21h
    pop dx
    pop ax
ret
endp
;********************************************************************************************************************************************************************;
read_number proc  ;retorna em ax o valor lido do teclado
    push bx
    push cx
    push dx
    xor ax,ax      ;zera os registradores ax e bx
    xor bx,bx
    mov cx,10
    read_next:
    push ax
    read_n:
    mov ax,0700h        ;DIRECT CHARACTER INPUT, WITHOUT ECHO, Return: AL = character read from standard input
    int 21h
    cmp al,13           ;compara al com enter
    jz end_read_number
    cmp al,8
    jz backspace        ;caso seja digitado 8 , aqui limpa o backspace para nao dar problema
    cmp al,1bh
    jz exits
    cmp al,'0'
    jb read_n
    cmp al,'9'
    ja read_n
    mov dl,al
    call read_char
    sub al,'0'          ;converte char lido para decimal
    mov bl,al
    pop ax
    mul cx
    add ax,bx
    jmp read_next
    backspace:                  ;limpa espaco,memoria,e le prox
    pop ax
    call backspace_clear
    call clear_memory
    jmp read_next
    exits:
    call clear_screen_40x25
    mov al,00
    mov ah,04ch
    int 21h
    end_read_number:                 ;termina
    pop ax
    pop dx
    pop cx
    pop bx
ret
endp
;********************************************************************************************************************************************************************;
set_cur_pos MACRO linhas,colunas
    push ax
    xor ax,ax
    mov ah,02h      ;seta a pos do cursor
    mov dh,linhas    ;linha do cursor
    mov dl,colunas   ;coluna do cursor
    int 10h
    pop ax
endm
;********************************************************************************************************************************************************************;
show_menu proc                         ; retorna o n de colunas no cx e o n de linhas no bx
    push_all

    again:
    call clear_screen_40x25        ;limpa tela
    mov ax,1125h                   ;seta pos do cursor na linha 2
    int 10h                        ;interrupcao bios

    mov ax,1301h                   ;atualiza a pos do cursor depois de escrever
    mov bx,04h                     ;n da pag de video,atributo do caractere se o bit 1 em al for 0
    mov bp,offset game_name_msg    ;registrador base pointer para apontar no inicio da string
    mov cx,offset game_name_len    ;tamanho, em caracteres, da string
    mov dx,0209h                   ;linha, coluna da pos de impressao
    int 10h                        ;interrupcao bios

    mov ax,1123h                   ;retorna cursor para 1 linha
    int 10h                        ;interrupcao bios

    mov ax,1301h                   ;daqui pra frente segue a mesma logica
    mov bx,07h
    mov bp,offset autores_msg
    mov cx,offset autores_len
    mov dx,0508h
    int 10h

    mov bx,02h
    mov bp,offset configuracoes_msg
    mov cx,offset configuracoes_len
    mov dx,0708h
    int 10h

    mov bl,0Fh
    mov cx,numero_len
    mov dl,05
    mov dh,10
    mov bp,offset numero_msg
    int 10h              ;funcao para escrever na tela

    mov cx,largura_len
    mov dl,05
    mov dh,12
    mov bp,offset largura_msg
    int 10h

    mov cx,altura_len
    mov dx,05
    mov dh,14
    mov bp,offset altura_msg
    int 10h

    mov bp,offset esc_msg
    mov cx,offset esc_len
    mov dx,1602h
    int 10h

    ;le o numero de bombas digitado pelo usuario
    mov dh,10               ;linha
    mov dl,27               ;coluna
    mov ah,2                ;seta cursor na posicao
    int 10h                 ;dos
    call read_number
    mov cl,5
    cmp al,cl
    jb erro
    mov bomba,al            ;seta o valor do teclado ao numero de minas

    ;le o numero de colunas digitado pelo usuario
    mov dh,12              ;daqui pra frente segue a mesma logica
    mov dl,29
    mov ah,2
    int 10h
    call read_number      ;le numero
    mov cl,5
    cmp al,cl
    jb erro               ;jb jump se cf=1 esta setado
    mov dl,40
    cmp al,dl
    jg erro               ;jump baseado nas flags
    mov coluna,al         ;seta o valor do teclado ao campo largura

    ;le o numero de linhas digitado pelo usuario
    mov dh,14
    mov dl,28
    mov ah,2
    int 10h
    call read_number
    mov cl,5
    cmp al,cl
    jb erro
    mov dl,20
    cmp al,dl
    jg erro
    mov linha,al      ;seta o valor do teclado ao campo altura

    xor bx,bx       ;Zera os registradores utilizados
    xor dx,dx

    mov bl,coluna
    mul bx              ;multiplica o n de linhas(ax) pelo n de colunas(bx) e o resultado fica armazenado em ax
    push ax
    xor ax,ax
    mov al,bomba
    mov bx,3
    mul bx
    mov dx,ax
    pop ax

    cmp ax,dx       ;compara a o n de linhas mult pelo n de colunas como n de bombas,caso seja menor que 3 vezes o n de bombas, ele requisita again
    jb erro


    jmp certo

    erro:     ;limpa tela e escreve mensagem de erro
    call clear_screen_40x25
    mov ax,1301h
    mov bl,04h
    mov cx,erro_len
    mov dx,06
    mov dh,10
    mov bp,offset erro_msg
    int 10h
    call stop
    call clear_screen_40x25

    jmp again
    certo:
    pop_all
ret
endp
;********************************************************************************************************************************************************************;
transforma_pos_matriz_pos_tela MACRO; dh <- linha e dl <- coluna o valor da pos na matriz, e retorna nos mesmos registradores o valor correspondente a tela
    push dx
    inc dh                       ; incrementa dh, pois a pos da linha na tela e na matriz tem a diferenca de 1 unidade
    add dh,3                     ; Subtrai 3 da linha, para ajusta a matriz
    add dl,20                    ; soma na pos na matriz, o valor 20, pois a pos da coluna na tela e na matriz tem a diferenca de 20 unidades
    set_cur_pos dh,dl            ; seta a pos do cursor na tela
    pop dx
endm
;********************************************************************************************************************************************************************;
esc_elem_na_tela MACRO          ; escreve o caracter armazenado em al na tela
        push ax
        push bx
        push cx
        mov ah,0ah                  ; seta o modo de video para escrever no cursor um caracter
        mov bh,0h                   ; n da pagina
        xor cx,cx
        mov cl,1
        int 10h                     ; chamada da int para escrever o caracter armazenado em al
        pop cx
        pop bx
        pop ax
endm
;********************************************************************************************************************************************************************;
inicia_campo proc                       ;vai gerar e desenhar campo
    push_all
    xor dx,dx                           ; linha = 0
    xor cx,cx                           ; col = 0

    pega_elem_atual:
    xor ax,ax                           ; ax tera valor da pos [dl][dh] na matriz
    mov bx,offset matriz_de_bombas
    call pega_elem_matriz               ; pega o conteudo do registradores [dl][dh] e coloca em ax
    mov cl,al                           ; copia valor do registrador
    cmp cl,01h                          ; CF <- Bit menos signf, que indica se o campo esta aparecendo ou nao
    je escreve_conteudo                 ; caso o campo esteja aparecendo, ele escreve o valor de bombas vizinhas
    cmp cl,02h                          ; CF <- Bit menos signf, que indica se o campo esta marcado
    je escreve_campo_marcado            ; se estiver marcado esc char 219
    jmp escreve_campo_escondido         ; se nao estiver marcado nem visivel, escreve o caracter 219

    escreve_conteudo:
    mov al,ah                           ; ah == valor de bombas vizinhas
    transforma_pos_matriz_pos_tela      ; transforma a pos da matriz em uma pos relativa a tela

    cmp al,0
    je vazio
    jmp nao_vazio

    vazio:
    mov al,178
    esc_elem_na_tela
    jmp vai_para_prox_col

    nao_vazio:
    add al,30h                  ;Transforma em caracter ascii o valor atual de bombas vizinhas
    mov ah,09h                  ;Write character and attribute at cursor position
    mov bh,0h                   ;Pagina
    mov cl,1                    ;Number of times to print character
    cmp al,38h
    je oito
    mov bl,al                   ;A cor e a mesma que seu codigo de cor
    and bl,0fh                  ;Deixar o fundo preto e o numero igual
    escreve_atributo:
    int 10h
    jmp fim_atributo
    oito:
    mov bl, 0Ah
    jmp escreve_atributo
    fim_atributo:
    jmp vai_para_prox_col

    escreve_campo_marcado:
    mov al,219
    transforma_pos_matriz_pos_tela          ;Transforma a pos da matriz em uma pos relativa a tela
    mov ah,09h
    mov bh,0h
    mov cl,1
    mov bl,34h
    int 10h
    jmp vai_para_prox_col

    escreve_campo_escondido:
    mov al, 219
    transforma_pos_matriz_pos_tela          
    mov ah,09h
    mov bh,0h
    mov cl,1
    mov bl,07h
    int 10h
    jmp vai_para_prox_col                   ; incrementa a coluna

    vai_para_prox_col:
    inc dl
    cmp dl,coluna
    jz vai_para_prox_lin
    jmp pega_elem_atual

    vai_para_prox_lin:
    xor dl,dl
    inc dh
    cmp dh,linha
    jz termina_inicia_campo
    jmp pega_elem_atual

    termina_inicia_campo:
    pop_all
ret
endp
;********************************************************************************************************************************************************************;
pseudo_aleatorio proc         ; (X+1 = (a*X + c)* mod m) formula do valor aleatorio
    push_all
    xor bx,bx
    xor ax,ax
    mov ah, 2ch ; funcao q pega a hora
    int 21h
    mov dh, 00
    mov semente_x,dx           ; X da formula com milisegundos do sistema
    ;mov semente_x,1           ; X da formula sempre na mesma posicao
    xor ax,ax
    mov multiplicador_a,33    ; a da formula (multiplicador)
    mov incremento_c,1        ; c da formula (incremento)
    mov bl,coluna
    mov al,linha
    mul bx                    ; armazena o m (mod de divisao)
    mov mod_divisao,ax

    mov contador,0

    n_aleatorio:
    xor ax,ax
    mov al,multiplicador_a ; move para ax o valor do multiplicador.
    mov bx,semente_x
    mul bx                 ; multiplicao do multiplicador com a semente
    add ax,incremento_c
    mov bx,mod_divisao
    div bx
    mov semente_x,dx       ; move para a semente o valor do resto da divisao
    mov ax,dx
    xor bx,bx
    mov bl,coluna
    div bl
    mov dh,al
    mov dl,ah

    inc contador

    mov ax,2a00h            ; Move o caracter * para ax
    call escreve_elemento_matriz

    mov al,bomba
    cmp contador,al     ; verifica se contador ja chegou no lim de numeros gerados
    jge termina_pseudo_aleatorio
    jmp n_aleatorio

    termina_pseudo_aleatorio:
    pop_all
ret
endp
;********************************************************************************************************************************************************************;
pega_bombas_vizinhas proc          ; dh<-linha e dl<-coluna onde sera feita a verificacao, e retornara em cl o n de bombas vizinhas
    push bx
    push dx

    xor cl,cl
    xor bx,bx

    dec dh                         ; verific a noroeste da pos passada
    dec dl                         

    encontra_bombas_vizinhas:
    xor ax,ax
    call pega_elem_matriz
    cmp ah,2Ah                     ; compara ah com o valor 2ah ou seja bomba
    jz inc_bomba                   ; incrementa o n de bombas vizinhas
    jmp cont_proc

    inc_bomba:
    inc cl

    cont_proc:
    inc bl
    cmp bl,03
    jz inc_lin_reseta_col
    inc dl
    jmp encontra_bombas_vizinhas

    inc_lin_reseta_col:
    xor bl,bl                      
    sub dl,02h
    inc bh
    inc dh
    cmp bh,03
    jz termina_pega_bombas_vizinhas
    jmp encontra_bombas_vizinhas

    termina_pega_bombas_vizinhas:
    pop dx
    pop bx
    ret
    endp
;********************************************************************************************************************************************************************;
n_bombas_vizinhas proc           ; dh==linha e dl==col
    push_all
    xor dl,dl                   
    xor dh,dh                  

    procura_bombas:
    call pega_elem_matriz        ; valor de linha e coluna e passado por parametro
    cmp ah,2ah                   ; se pos eh bomba entao nao calcula vizinhanca e avanca col
    je prox_col                  ; jump if equal

    call pega_bombas_vizinhas    ; retorna o n de bombas da vizinhanca na pos dh-linha e dl-coluna em cl
    mov ah,cl                    ; move para ah a quantia de bombas encontradas na vizinhaca

    mov bx,offset matriz_de_bombas
    call escreve_elemento_matriz  ; escreve o n de bombas achadas na vizinhaca em ah
    
    ;comp de col e lin para ver se chegou no lim da matriz fornecida pelo usuario
    prox_col:
    inc dl                       ; incremente a coluna da pos
    cmp dl,coluna                ; compara com o tam da col (user-stdin), se for == ele volta para a col 0 e inc a coluna, senao continua a verificar
    jz prox_lin
    jmp procura_bombas

    prox_lin:
    xor dl,dl                    ; coluna e zerado
    inc dh                       ; pula para a prox linha
    cmp dh,linha                 ; compara com linha (user-stdin), se for a ultima finaliza a proc, senao continua a verificar
    jz termina_n_bombas_vizinhas
    jmp procura_bombas

    termina_n_bombas_vizinhas:
    pop_all
ret
endp
;********************************************************************************************************************************************************************;
pega_elem_matriz proc                ; pega elemento da matriz dada em bx na pos dh==linha e dl==coluna e coloca em ax
    push cx
    push bx
    push si
    push dx

    call verifica_posicao_valida
    cmp cl,0
    je termina_pega_elem_matriz ;se pos eh invalida acaba proc

    mov al,coluna               ; move para al o tamanho da col
    mul dh                      ; multiplica pelo n da linha para corrigir a pos de acesso na matriz
    xor dh,dh                  
    add ax,dx                   ; soma o valor multiplicado acima pela coluna para corrigir a pos de acesso na matriz
    shl ax,1                    ; multiplica a pos por 2, pois um elemento da matrix ocupa 2 pos

    mov si,ax                   ; move para si para ser usado como deslocamento no end base na matriz de elementos

    mov ax,[matriz_de_bombas][si]
    ; move para ax o valor solicitado na pos dh linha dl coluna na matriz (source index for string operations ,pointer)
    
    termina_pega_elem_matriz:
    pop dx
    pop si
    pop bx
    pop cx
ret
endp
;********************************************************************************************************************************************************************;
escreve_elemento_matriz proc     ; esc o conteudo de ax na pos dh == linha e dl == coluna  da matriz armazenada em bx
    push cx
    push bx
    push si
    push dx
    push ax

    call verifica_posicao_valida
    cmp cl,0
    je termina_escreve_elemento_matriz

    mov al,coluna            ; al <- tam col
    mul dh                   ; multiplica pelo n da linha para corrigir a pos de acesso na matriz
    xor dh,dh             
    add ax,dx                ; soma o valor multiplicado acima pela coluna para corrigir a pos de acesso na matriz
    shl ax,1                 ; multiplica a pos por 2, pois um elemento da matrix ocupa 2 pos

    mov si,ax                ; move para si para ser usado como deslocamento no endereco base na matriz de elementos

    pop ax                   ; desempilha o valor para ser salvo na pos dh linha e dl col
    mov [matriz_de_bombas][si],ax   ; armazena conteudo de ax na matriz

    termina_escreve_elemento_matriz:
    pop dx
    pop si
    pop bx
    pop cx
ret
endp
;********************************************************************************************************************************************************************;
linha_col_pos_clicada proc                  ; cx possui a linha e dx a coluna da pos clicada e retorna a pos da matriz
                                            ; se pos eh valida CL = 1;
    push bx
    push ax

    mov bl,08
    mov ax,mouse_x                          ; dx indica a coluna do cursor que vai ser div por 8
    div bl                                  ; ax/bx
    mov dl,al                               ; dl <- queciente da div,que indica a coluna certa
    mov ax,mouse_y                          ; cx indica a linha do cursor que vai ser div por 8
    div bl                                  ; ax/bx
    mov dh,al                               ; dh <- quociente da div,que indica a linha certa

    mov bh,20
    sub dl,bh   ; subtraimos o valor atual da coluna por 20, que indica o valor base da coluna onde foi iniciado o desenho do campo minado
    mov bh,3
    sub dh,bh
    dec dh      ; subtraimos o valor atual da linh por 3, que indica o valor base da linha onde foi iniciado o desenho do campo minado

    pop ax
    pop bx
ret
endp
;********************************************************************************************************************************************************************;
verifica_posicao_valida proc            ; dh <- linha , dl <- coluna, se pos for valida cl <- 1 senao cl <- 0

    xor cl,cl                           ; cl indica se eh valida ou nao

    cmp dl,0                            ; se col < do que 0 pos invalida
    js termina_verifica_posicao_valida
    cmp dl,coluna                       ; se col > que lim da matriz pos invalida
    jge termina_verifica_posicao_valida
    cmp dh,0                            ; se linha < do que 0 pos invalida
    js termina_verifica_posicao_valida
    cmp dh,linha                        ; se linha > do que lim da matriz pos invalida 
    jge termina_verifica_posicao_valida ; (jump > or ==)

    verifica_posicao_valida_inc:        ; caso contrario eh valida
    inc cl

    termina_verifica_posicao_valida:
ret
endp
;********************************************************************************************************************************************************************;
desc_pos_sem_bomba proc
    push dx
    push bx
    texte:
    call pega_elem_matriz       ; pega o elemento na pos dh==linha e dl==coluna e poe em axl
    cmp al,02                   ; compara se o elemente e marcado
    je open_vizinho
    
    mov al,01                 ; seta a visibilidade para 1, sinalizando que o conteudo do campo sera mostrado
    call escreve_elemento_matriz
    
    cmp ah,0                   ; caso campo seja vazio, eh feito um jump para analizar a vizinhanca, caso contrario finaliza a proc.
    ja fim_desc_pos_sem_bomba   ; se CF == 0 e ZF == 0 

    open_vizinho:               ; comeca a procurar vizinhos
    inc dl                      ;Diagonal superior direita
    dec dh        
    xor bx,bx                   ; reseta bx para ser um contador de linha==bx e coluna==bl

    open_current_vizinho:
    call verifica_posicao_valida ; cl=0 pos invalida e cl=1 pos valida
    cmp cl,0                     ; se cl==0 pula pra prox col
    je pula_prox_col   
    xor ax,ax                    ; zera ax que possui pos atual da matriz
    call pega_elem_matriz        ; ax = dh e dl == linha e coluna
    cmp al,01                   ; caso o campo esteja visivel,avanca para a prox pos
    je pula_prox_col
    cmp al,02                   ; caso o campo esteja marcado,avanca para a prox pos
    je pula_prox_col
    jmp texte

    pula_prox_col:
    pula_prox_lin:


    fim_desc_pos_sem_bomba:
    pop bx
    pop dx
ret
endp
;********************************************************************************************************************************************************************;
esc_marcacoes_bomba proc; recebe em marked_bombs o valor atual de bombas para escrever na tela.
    push_all
    mov ax,1301h
    mov bl,04h
    mov cx,offset markedbombsmessage_len
    mov dl,35
    mov dh,2
    mov bp,offset  markedbombsmessage
    int 10h

    cmp dx,marked_bombs
    je n_mudou


    mov dx, marked_bombs
    cmp dh,'9'
    ja ajusta
    cmp dh,'0'
    jb ajuste


    marcacao:
    mov bl,0Fh
    mov cx,offset marked_bombs_len
    mov dl,42
    mov dh,3
    mov bp,offset  marked_bombs
    int 10h

    mov dx, marked_bombs
    jmp n_mudou

    ajusta:
    sub dh, 10
    add dl, 1
    mov  marked_bombs, dx

    jmp marcacao

    ajuste:
    add dh, 10
    sub dl, 1
    mov  marked_bombs, dx

    jmp marcacao

    n_mudou:

    pop_all
ret
endp
;********************************************************************************************************************************************************************;
win_check proc
    push dx
    xor dx,dx
    xor cx,cx

    win_check_loop:
    xor ax,ax
    call pega_elem_matriz
    cmp ah,2ah                      ;Verifica se tem uma bomba na posicao
    je go_next_column
    cmp al,0                        ;Verifica se a posicao esta com a visibilidade ativada
    je finish_win_check
    cmp al,2                        ; Verifica se aposicao tem campo marcado
    je finish_win_check

    go_next_column:
    inc dl
    cmp dl,coluna
    je go_next_row
    jmp win_check_loop

    go_next_row:
    xor dl,dl
    inc dh
    cmp dh,linha
    je won
    jmp win_check_loop

    won:
    inc cl

    finish_win_check:
    pop dx
ret
endp
;********************************************************************************************************************************************************************;
mostra_bombas proc
    push dx
    xor dx,dx
    xor cx,cx

    show_all_bombs_loop:
    xor ax,ax
    call pega_elem_matriz
    cmp ah, 2ah
    je write_bomb
    jmp jump_column

    write_bomb:
    mov al,ah
    transforma_pos_matriz_pos_tela
    esc_elem_na_tela

    jump_column:
    xor ax,ax
    call escreve_elemento_matriz
    inc dl
    cmp dl,coluna
    je jump_row
    jmp show_all_bombs_loop

    jump_row:
    xor dl,dl
    inc dh
    cmp dh,linha
    je finaliza_mostra_bombas
    jmp show_all_bombs_loop

    finaliza_mostra_bombas:
    pop dx
ret
endp
;********************************************************************************************************************************************************************;
clock proc ; pega os segundos do sistema em dh e os minutos em cl
    push_all

    mov ax,1301h                   ;atualiza a pos do cursor depois de escrever
    mov bl,0Ah                     ;n da pag de video,atributo do caractere se o bit 1 em al for 0
    mov bp,offset game_name_msg    ;registrador base pointer para apontar
    mov cx,offset game_name_len    ;tamanho, em caracteres, da string
    mov dh, 1
    mov dl, 24                     ;linha, coluna da pos de impressao
    int 10h                        ;interrupcao bios

    mov ah,2ch
    int 21h
    cmp dh,seconds
    je no_change

    mov  seconds, dh

    mov dh, 1
    mov dl, 0

    add segundos, dx
    mov dx, segundos
    cmp dh,'9'
    ja decimal


    escrev:
    mov ax, 1301h
    mov bl,04h
    mov cx, offset time_len
    mov dl, 20
    mov dh,02
    mov bp,offset  time_msg
    int 10h
    mov bl,0fh
    mov cx,minutos_len
    mov dl,20
    mov dh,03
    mov bp,offset  minutos
    int 10h
    mov dl, ':'
    mov ah, 2
    int 21h
    mov ax, 1301h
    mov cx,segundos_len
    mov dl,23
    mov dh,03
    mov bp,offset segundos
    int 10h

    jmp no_change

    decimal:
    sub dh, 10
    add dl, 1
    mov segundos, dx

    cmp dl, '6'
    jb escrev
    sub dl, 6
    mov segundos,dx
    mov dx, minutos
    mov dh, 1
    mov dl, 0

    add minutos, dx
    jmp escrev

    no_change:
    pop_all
ret
endp
;********************************************************************************************************************************************************************;
start proc
    mov ax,013h                     ; modo grafico 40x25. 256 cores 320x200 pixels
    int 10h                         ; interrupcao BIOS video
    call clear_screen_40x25         ; limpa a tela
    call show_menu                  ; requisita informacoes do menu principal (tela inicial)
endp
;********************************************************************************************************************************************************************;
reset proc
    call pseudo_aleatorio           ; gera as bombas aleatoriamente (funcao randomica da folha)
    call n_bombas_vizinhas          ; procura bombas vizinhas
    call clear_screen_80x25         ; limpa a tela modo de video 80x25

    mov marked_bombs,3030h          ;valor char 0 na tabela ascii
    mov segundos,3030h
    mov minutos,3030h

    call inicia_campo               ; escreve o campo
    call esc_marcacoes_bomba        ; escreve na tela a quantidade de bombas marcadas

endp
;********************************************************************************************************************************************************************;
mouse proc
    mouse_input:
    mov ax,0001h                 ; mostra mouse na tela
    int 33h                      ; int do mouse
    mov ax,0003h                 ; coleta info do mouse
    int 33h                      ; int do mouse

    call clock

    cmp verif_mouse_clicado,1    ; verifica se o mouse esta clicado
    je mouse_esta_clicado        ; caso o mouse esteja clicado ele verifica se nao esta mais clicado
    jmp analisa_mouse            ; se mouse nao estiver clicado ele fica esperando por ser clicado

    mouse_esta_clicado:
    cmp bx,0                     ; se o mouse esta solto, ele seta o verif_mouse_clicado para 0, aavisando que o mouse sera analisado depois de clicado
    je libera_mouse
    jmp mouse_input              ; se o mouse esta clicado ele fica no loop ate ser liberado

    libera_mouse:
    mov verif_mouse_clicado,0    ; solta mouse

    analisa_mouse:
    mov mouse_x,cx               ; mouse_x armazena a linha
    mov mouse_y,dx               ; mouse_y armazena a col
    cmp bx,0                     ; se bx for maior que 0,entao o mouse foi clicado pois 0 eh solto
    ja botao_mouse_clicado       ; analisa qual botao foi clicado (jump above CF=0 E ZF=0)

    jmp mouse_input              ; caso nenhum botao seja clicado, continua no loop ate ser

    botao_mouse_clicado:
    mov verif_mouse_clicado,1    ; 1 indica que mouse esta clicado
    call linha_col_pos_clicada   ; retorna pos clicada
    call verifica_posicao_valida 
    cmp cl,0
    je mouse_input               ; se pos clic eh invalida, volta pro loop
    mov ax,0002h                 ; mostra mouse na tela
    int 33h                     
    call pega_elem_matriz        ; ax <- valor linha e coluna de dh e dl
    
                                 ; bx tem valor do botao press
    shr bx,1                     ; se o shr de bx resultar no carry flag = 1 entao botao esq foi clicado
    jc botao_esquerdo            ; jump if carry == 1
    shr bx,1                     ; se o bit 1 ou o bit 2 bit de bx resultar no carry flag = 1, entao o botao direito foi clicado
    jc botao_direito
   
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    botao_direito:
    cmp al,01                    ; se campo clicado eh visivel entao nao marca
    je mouse_input
    cmp al,02                    ; se campo clicado eh visivel entao nao marca
    je mouse_input
    
    mov al,02                    ; al<-2 ou seja, mostra qie o campo esta marcado
    call escreve_elemento_matriz ; altera na matrix a visibilidade do campo clicado
    call inicia_campo            ; escreve o campo
    mov dh,1
    mov dl,0
    add marked_bombs, dx         ; incrementa o contador de bombas marcadas
    call esc_marcacoes_bomba     ; escreve na tela a quantidade de bombas marcadas
    jmp mouse_input              ; volta para o loop do mouse

    
    botao_esquerdo:
    cmp al,02                    ; verifica se o campo clicado esta marcado, caso sim ele desmarca o campo
    je desmarca_campo_marcado
    cmp al,01                    ; verifica se o campo clicado ja esta visivel, caso sim ele retorna para a verificao do mouse e nao acontece nada
    je mouse_input
    cmp ah,2ah                   ;se ah (pos clicada) for 2ah == bomba game over haha
    je game_over
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    ADAMI:                       ; abre o campo clicado e toda sua vizinhanca, caso ele seja vazio
   
    call desc_pos_sem_bomba      ; Descobre as pos sem bomba (abre campos vazios)    
    call inicia_campo            ; escreve o campo
    call win_check
    cmp cl,1
    je win
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    jmp mouse_input              ; volta para o loop do mouse.

    desmarca_campo_marcado:
    xor al,al                    ; limpa o valor de al ou seja oculto
    call escreve_elemento_matriz ; campo volta ao normal (desclicado)
    call inicia_campo           
    mov dh, 1
    mov dl, 0
    sub marked_bombs, dx         ; sub quantidade de bombas
    call esc_marcacoes_bomba     ; printa n de bombas marcadas
    jmp mouse_input              ; volta para o loop do mouse

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    game_over:
    call mostra_bombas
    call delay
    call clear_screen_40x25
    mov ax,013h
    int 10h
    mov ax,1301h
    mov bl,04h
    mov cx,gameover_len
    mov dl,06
    mov dh,10
    mov bp,offset gameover_msg
    int 10h
    mov cx,offset lost_len
    mov dl,08
    mov dh,12
    mov bp,offset lost_msg
    int 10h
    jmp finish_game

    win:
    call mostra_bombas
    call delay
    call clear_screen_40x25
    mov ax,013h
    int 10h
    mov ax,1301h
    mov bl,04h
    mov cx,offset gameover_len
    mov dl,06
    mov dh,10
    mov bp,offset gameover_msg
    int 10h
    mov bl,02h
    mov cx,offset win_len
    mov dl,11
    mov dh,12
    mov bp,offset win_msg
    int 10h
    jmp finish_game


    finish_game:
    mov bl,0fh
    mov cx,again_len
    mov dl,00
    mov dh,16
    mov bp,offset again_msg
    int 10h

    keep_reading:
    mov ah,07h
    int 21h
    cmp al,6eh ; i
    je I
    cmp al,69h ; n
    je N
    cmp al,1bh ;esc
    je finaliza
    jmp keep_reading

    N:
    jmp start
    I:
    jmp reset

    finaliza:
    mov ah,4ch   ; prepara o fim do programa
    int 21h      ; sinaliza o dos

endp
;********************************************************************************************************************************************************************;
inicio:
    mov ax,@data                    ; ax aponta para segmento de dados
    mov ds,ax                       ; copia para ds
    mov es,ax                       ; copia para es tambem

    call start
    call reset
    call mouse
end inicio
;********************************************************************************************************************************************************************;


