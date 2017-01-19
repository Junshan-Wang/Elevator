DATA SEGMENT
        LED DB 3FH,06H,5BH,4FH,66H,6DH,7DH,07H,7FH
        FLR DB 1
        DIR DB 0
        KEYB DB '1','4','7','0','2','5','8','0','3','6','9','0','0','0','0','0'
        FLAG DB 0
        REQ_IN DB 0
        REQ_UP DB 0
        REQ_DN DB 0

NUM1    DB 0,0,0,0,7FH,0,0,0,0,0,0,0,0,0,0,0
NUM2    DB 0,0,4FH,49H,49H,49H,79H,0,0,0,0,0,0,0,0,0
NUM3    DB 0,0,49H,49H,49H,49H,7FH,0,0,0,0,0,0,0,0,0
NUM4    DB 0,0,78H,08H,08H,08H,7FH,0,0,0,0,0,0,0,0,0
NUM5    DB 0,0,79H,49H,49H,49H,4FH,0,0,0,0,0,0,0,0,0
NUM6    DB 0,0,7FH,49H,49H,49H,4FH,0,0,0,0,0,0,0,0,0

ARUP    DB 0,0,10H,30H,7EH,30H,10H,0,0,0,0,0,0,0,0,0
ARDN    DB 0,0,08H,0CH,7EH,0CH,08H,0,0,0,0,0,0,0,0,0
ARHD    DB 0,0,0,10H,10H,10H,0,0,0,0,0,0,0,0,0,0

index db  00h
looptimer db 00h

DATA ENDS

STACK SEGMENT PARA STACK
        DW 128H DUP(0)
STACK ENDS
                                                                                       
CODE SEGMENT
        ASSUME CS:CODE,SS:STACK,DS:DATA

START:  MOV AL,00110110B	;����8253��ͨ��0��ͨ��1����
        MOV DX,0E483H
        OUT DX,AL
        MOV DX,0E480H
        MOV AX,0800H
        OUT DX,AL
        MOV AL,AH
        OUT DX,AL
        MOV AL,01110110B
        MOV DX,0E483H
        OUT DX,AL
        MOV DX,0E481H
        MOV AX,0400H
        OUT DX,AL
        MOV AL,AH
        OUT DX,AL


        MOV DX,0E48BH		;����8255��A�������B�������C�ڸ���λ���룬����λ���
        MOV AL,88H
        OUT DX,AL

        MOV DX,0E4ABH		;����16*16����
        MOV AL,80H
        OUT DX,AL

        MOV AX,CS		;�����ж�
        MOV DS,AX
        MOV DX,OFFSET IRQ
        MOV AX,250EH
        INT 21H
        CLI
        MOV DX,0EC4CH
        MOV AL,43H
        OUT DX,AL
        INC DX
        MOV AL,1DH
        OUT DX,AL
        IN AL,21H
        AND AL,10111111B
        OUT 21H,AL
        MOV AX,DATA
        MOV DS,AX
        STI

NEXT:   MOV AL,0
        MOV [FLAG],AL
BUTTN:  MOV AH,01H
        INT 16H
        JNZ ENDI

        CALL READIN

        CALL JUDGE

        CALL SHOWLED

MOVE:   CMP [FLAG],0
        JZ BUTTN

        CALL SHOWFLR

        JMP NEXT

         
ENDI:   IN AL,21H
        OR AL,40H
        OUT 21H,AL
        MOV DX,0EC4CH
        MOV AL,42H
        OUT DX,AL
        STI
        MOV AH,4CH
        INT 21H


;���ݿ��Ƴ���
JUDGE PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX

        MOV CL,[FLR]
        DEC CL
        MOV AL,1
        SHL AL,CL
        XOR AL,0FFH      

        MOV CL,[FLR]
        CMP [DIR],1
        JZ UP
        JG DOWN
        JMP HLD

UP:     AND [REQ_IN],AL		;��ǰ����״̬����
        AND [REQ_UP],AL
        MOV AL,[REQ_IN]
        SHR AL,CL
        JNZ ENDJ
        MOV AL,[REQ_UP]
        SHR AL,CL
        JNZ ENDJ
        MOV AL,[REQ_DN]
        SHR AL,CL
        JNZ ENDJ
        MOV [DIR],0
        JMP ENDJ

DOWN:   AND [REQ_IN],AL		;��ǰ����״̬����
        AND [REQ_DN],AL
        MOV AL,9
        SUB AL,CL
        MOV CL,AL
        MOV AL,[REQ_IN]
        SHL AL,CL
        JNZ ENDJ
        MOV AL,[REQ_UP]
        SHL AL,CL
        JNZ ENDJ
        MOV AL,[REQ_DN]
        SHL AL,CL
        JNZ ENDJ
        MOV [DIR],0
        JMP ENDJ

HLD:    AND [REQ_IN],AL		;��ǰ����״ֹ̬ͣ
        AND [REQ_UP],AL
        AND [REQ_DN],AL
        MOV AL,[REQ_IN]
        OR AL,[REQ_UP]
        OR AL,[REQ_DN]
        CMP AL,0
        JZ ENDJ
        DEC CL
        MOV BL,1
        SHL BL,CL
        CMP AL,BL
        JG HLD1
        JL HLD2
        JMP ENDJ
HLD1:   MOV [DIR],1
        JMP ENDJ
HLD2:   MOV [DIR],2
        JMP ENDJ

ENDJ:   POP DX
        POP CX
        POP BX
        POP AX
        RET
JUDGE ENDP

;�������к���ʾ����ܳ���¥������Ӧ+1��-1�򲻱䣬����������
SHOWFLR PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX

        MOV AL,[FLR]
        CMP [DIR],1
        JZ INCR
        JG DECR
        JMP HOLD

INCR:
        MOV BL,[REQ_IN]
        OR BL,[REQ_UP]
        MOV BH,1
        MOV CL,AL
        SHL BH,CL
        AND BH,BL
        JZ INCR1
        CALL BEEP
INCR1:  INC AL
        JMP HOLD

DECR:
        MOV BL,[REQ_IN]
        OR BL,[REQ_DN]
        MOV BH,1
        MOV CL,AL
        SUB CL,2
        SHL BH,CL
        AND BH,BL
        JZ DECR1
        CALL BEEP
DECR1:  DEC AL

HOLD:   MOV [FLR],AL
        MOV BX,OFFSET LED
        XLAT
        MOV DX,0E488H
        OUT DX,AL

        POP DX
        POP CX
        POP BX
        POP AX
        RET
SHOWFLR ENDP


;��ʾ�������	16*16�ĵ����ϰ벿����ʾ��ǰ����¥�������°벿����ʾ����״̬��
SHOWLED PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX

        mov bx,0h
S0:  
        mov dx,0E4A8H;      ;a
        mov al,index

        push bx
        CMP [DIR],1
        JZ UPSS
        JG DNSS
        MOV BX,OFFSET ARHD
        XLAT
        JMP SSH
UPSS:   mov bx, offset ARUP
        xlat
        JMP SSH
DNSS:   MOV BX,OFFSET ARDN
        XLAT
        JMP SSH
SSH:    pop bx
        out dx,al
        mov dx,0E4A9H

        mov al,index

        push bx
        CMP [FLR],1
        JZ NN1
        CMP [FLR],2
        JZ NN2
        CMP [FLR],3
        JZ NN3
        CMP [FLR],4
        JZ NN4
        CMP [FLR],5
        JZ NN5
        CMP [FLR],6
        JZ NN6

SS0:    JMP s0

NN1:    MOV BX,OFFSET NUM1
        JMP NNEND
NN2:    MOV BX,OFFSET NUM2
        JMP NNEND
NN3:    MOV BX,OFFSET NUM3
        JMP NNEND
NN4:    MOV BX,OFFSET NUM4
        JMP NNEND
NN5:    MOV BX,OFFSET NUM5
        JMP NNEND
NN6:    MOV BX,OFFSET NUM6
        JMP NNEND
NNEND:  XLAT
        POP BX
        out dx,al

        inc index
        cmp index, 010h
        jnz goon
        sub index, 010h

GOON:

        MOV DX,0E4AAH     ;c
        MOV AL,BL
        OUT DX,AL


        ADD BL,01H
        CMP BL,010H
        JNZ SS0
        MOV BL,0
        INC LOOPTIMER
        CMP LOOPTIMER,04FH
        JNZ KEY0
        SUB LOOPTIMER,04FH
KEY0:
        POP DX
        POP CX
        POP BX
        POP AX
        RET

SHOWLED ENDP

;����΢������������
BEEP PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        MOV BL,0FFH
        MOV AX,10110110B
        OUT 43H,AL
        MOV AX,1190
        OUT 42H,AL
        MOV AL,AH
        OUT 42H,AL
        IN AL,61H
        MOV AH,AL
        OR AL,03H
        OUT 61H,AL
        MOV CX,0
L0:     LOOP L0
        DEC BL
        JNZ L0
        MOV AL,AH
        OUT 61H,AL
        POP CX
        POP BX
        POP AX
        RET
BEEP ENDP


;���ּ���ɨ�����ɨ��ʵ�����ϵ����ּ���
READIN PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX

        MOV CH,0
        MOV BX,OFFSET KEYB
SCAN:   
        MOV DX,0E48AH
        MOV AL,1
        MOV CL,CH
        SHL AL,CL
        NOT AL
        OUT DX,AL
        IN AL,DX
        NOT AL
        MOV CL,4
        SHR AL,CL

        CMP CH,0
        JZ C0
        CMP CH,1
        JZ C1
        CMP CH,2
        JZ C2
        CMP CH,3
        JZ C3

C0:     CMP AL,1
        JZ C00
        CMP AL,2
        JZ C01
        CMP AL,4
        JZ C02
        CMP AL,8
        JZ C03
        JMP NXTS

C1:     CMP AL,1
        JZ C10
        CMP AL,2
        JZ C11
        CMP AL,4
        JZ C12
        CMP AL,8
        JZ C13
        JMP NXTS
  
C2:     CMP AL,1
        JZ C20
        CMP AL,2
        JZ C21
        CMP AL,4
        JZ C22
        CMP AL,8
        JZ C23
        JMP NXTS

C3:     JMP CC3

NXTS:   INC CH
        CMP CH,4
        JNZ SCAN
        MOV AL,0
        JMP READE

C00:    MOV AL,20H
        OR [REQ_DN],AL
        JMP READE
C01:    MOV AL,20H
        OR [REQ_IN],AL
        JMP READE
C02:    MOV AL,1
        OR [REQ_UP],AL
        JMP READE
C03:    MOV AL,1
        OR [REQ_IN],AL
        JMP READE
C10:    MOV AL,10H
        OR [REQ_IN],AL
        JMP READE
C11:    MOV AL,8
        OR [REQ_IN],AL
        JMP READE
C12:    MOV AL,4
        OR [REQ_IN],AL
        JMP READE
C13:    MOV AL,2
        OR [REQ_IN],AL
        JMP READE
C20:    MOV AL,10H
        OR [REQ_UP],AL
        JMP READE
C21:    MOV AL,8
        OR [REQ_UP],AL
        JMP READE
C22:    MOV AL,4
        OR [REQ_UP],AL
        JMP READE
C23:    MOV AL,2
        OR [REQ_UP],AL
        JMP READE

CC3:    CMP AL,1
        JZ C30
        CMP AL,2
        JZ C31
        CMP AL,4
        JZ C32
        CMP AL,8
        JZ C33
        JMP NXTS

C30:    MOV AL,10H
        OR [REQ_DN],AL
        JMP READE
C31:    MOV AL,8
        OR [REQ_DN],AL
        JMP READE
C32:    MOV AL,4
        OR [REQ_DN],AL
        JMP READE
C33:    MOV AL,2
        OR [REQ_DN],AL
        JMP READE

READE:  MOV AL,0
        OR AL,[REQ_IN]
        OR AL,[REQ_UP]
        OR AL,[REQ_DN]

        MOV DX,0E489H
        OUT DX,AL

        POP DX
        POP CX
        POP BX
        POP AX
        RET
READIN ENDP



IRQ PROC FAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        MOV AX,DATA
        MOV DS,AX
        MOV AL,1
        MOV [FLAG],AL
   
        MOV AL,20H
        OUT 20H,AL
        MOV DX,0EC4DH
        MOV AL,1DH
        OUT DX,AL

        POP DX
        POP CX
        POP BX
        POP AX
        IRET
IRQ ENDP
CODE ENDS
END START

         