.386
.model flat, stdcall
.stack 4096

ExitProcess proto, dwExitCode:dword
INCLUDE Irvine32.inc

Account STRUCT
    accountNum   DWORD   0
    pin          DWORD   0
    balance      DWORD   0
    active       BYTE    1
    BYTE 3 DUP(?)
Account ENDS

.data
filename        db "accounts.dat",0
fileHandle      dd ?

loading_msg    db "Loading",0
progress_bar   db "[                    ]",0
complete_msg   db "Complete! Press any key to continue...",0Dh,0Ah,0

BAR_ROW        = 12
BAR_COL        = 29

COLOR_MAIN      = white + (black * 16)
COLOR_BANNER    = yellow + (black * 16)
COLOR_MENU      = lightCyan + (black * 16)
COLOR_ADMIN     = lightGreen + (black * 16)
COLOR_USER      = lightMagenta + (black * 16)
COLOR_SUCCESS   = lightGreen + (black * 16)
COLOR_ERROR     = lightRed + (black * 16)
COLOR_INPUT     = white + (black * 16)
COLOR_BALANCE   = lightGreen + (black * 16)
COLOR_LOADING   = lightBlue + (black * 16)
COLOR_PROGRESS  = lightGreen + (black * 16)
COLOR_COMPLETE  = lightGreen + (black * 16)

titleMain       db "Bank Management System",0
titleAdmin      db "Admin Panel",0
titleUser       db "Customer Panel",0
titleSuccess    db "Success",0
titleError      db "Error",0
titleWarning    db "Warning",0
titleInfo       db "Information",0

banner          db "========================================", 0Dh, 0Ah
                db "         BANK MANAGEMENT SYSTEM        ", 0Dh, 0Ah
                db "         Secure Banking Solution       ", 0Dh, 0Ah
                db "========================================", 0Dh, 0Ah, 0

mainMenu        db 0Dh, 0Ah, "            MAIN MENU", 0Dh, 0Ah
                db "          --------------", 0Dh, 0Ah, 0Dh, 0Ah
                db "      1) Administrator Login", 0Dh, 0Ah
                db "      2) Customer Login", 0Dh, 0Ah
                db "      3) Exit System", 0Dh, 0Ah, 0Dh, 0Ah, 0

adminMenu       db 0Dh, 0Ah, "        ADMINISTRATOR PANEL", 0Dh, 0Ah
                db "      ----------------------", 0Dh, 0Ah, 0Dh, 0Ah
                db "      1) Create New Account", 0Dh, 0Ah
                db "      2) View Account Details", 0Dh, 0Ah
                db "      3) Deposit Funds", 0Dh, 0Ah
                db "      4) Withdraw Funds", 0Dh, 0Ah
                db "      5) Display All Accounts", 0Dh, 0Ah
                db "      6) Delete Account", 0Dh, 0Ah
                db "      7) Return to Main Menu", 0Dh, 0Ah, 0Dh, 0Ah, 0

userMenu        db 0Dh, 0Ah, "         CUSTOMER PANEL", 0Dh, 0Ah
                db "      -------------------", 0Dh, 0Ah, 0Dh, 0Ah
                db "      1) Check Balance", 0Dh, 0Ah
                db "      2) Withdraw Money", 0Dh, 0Ah
                db "      3) Transfer Funds", 0Dh, 0Ah
                db "      4) Change PIN", 0Dh, 0Ah
                db "      5) Return to Main Menu", 0Dh, 0Ah, 0Dh, 0Ah, 0

prompt          db "      Enter Your Choice: ", 0
promptID        db "      Admin ID: ", 0
promptPass      db "      Password: ", 0
promptAccNum    db "      Account Number: ", 0
promptPIN       db "      PIN (1000-9999): ", 0
promptAmount    db "      Amount: $", 0
promptToAcc     db "      Recipient Account: ", 0
promptConfirmPIN db "     Confirm PIN: ", 0
promptNewPIN    db "      New PIN: ", 0
promptOldPIN    db "      Current PIN: ", 0
promptDeleteAcc db "      Enter Account Number to Delete: ",0
promptAdminPIN  db "      Enter Account Number to Change PIN: ",0

msgWelcome      db "Login Successful! Welcome.",0
msgInvalid      db "Invalid credentials! Access denied.",0
msgSuccess      db "Operation completed successfully!",0
msgFailed       db "Operation failed! Please try again.",0
msgBalance      db "Current Balance: $", 0
msgGoodbye      db "Thank you for using our Banking System!",0
msgNoAccounts   db "No accounts found in the system.",0
msgAccHeader    db 0Dh, 0Ah, "Account#       PIN        Balance      Status", 0Dh, 0Ah
                db "-----------------------------------------------", 0Dh, 0Ah, 0
msgSpaces       db "           ", 0
msgAccNotExist  db "Recipient account not found.",0
msgPINMismatch  db "PIN verification failed!",0
msgSameAcc      db "Cannot transfer to same account.",0
msgInvalidChoice db "Invalid selection! Choose valid option.",0
msgInvalidAmount db "Invalid amount! Must be greater than zero.",0
msgInsufficientBal db "Insufficient funds in account.",0
msgPINChanged   db "PIN updated successfully!",0
msgMaxAccounts  db "Maximum accounts limit reached.",0
msgAccExists    db "Account number already exists.",0
msgInvalidPIN   db "Invalid PIN! Must be 4-digit (1000-9999).",0
msgInvalidAccNum db "Invalid account number! Must be positive.",0
msgContinue     db "Press any key to continue...",0
msgActive       db "Active  ",0
msgInactive     db "Inactive",0
maskPIN         db "****",0
msgAccDeleted   db "Account deleted successfully!",0
msgAccNotFound  db "Account not found!",0
msgDeleteConfirm db "Are you sure? This action cannot be undone! (1=Yes, 0=No): ",0
msgDeleteCancelled db "Account deletion cancelled.",0

adminID         db "admin",0
adminPassword   db "1234",0

MAX_ACCOUNTS    equ 10
accounts        Account MAX_ACCOUNTS dup(<>)
accountCount    dd 0
currentAccIdx   dd -1

inputBuffer     db 20 dup(0)
tempBuffer      db 20 dup(0)

.code

ShowLoadingScreen PROC
    pushad
    call Clrscr
    mov dh, BAR_ROW
    mov dl, BAR_COL
    call Gotoxy
    mov edx, OFFSET progress_bar
    call WriteString
    mov esi, OFFSET progress_bar
    add esi, 1
    mov ecx, 20
    xor ebx, ebx
loading_loop:
    inc ebx
    mov byte ptr [esi], 0DBh
    inc esi
    mov eax, ebx
    cmp eax, 5
    jl color_red
    cmp eax, 10
    jl color_yellow
    cmp eax, 15
    jl color_blue
    jmp color_green
color_red:
    mov eax, lightRed + (black * 16)
    jmp display_bar
color_yellow:
    mov eax, yellow + (black * 16)
    jmp display_bar
color_blue:
    mov eax, lightBlue + (black * 16)
    jmp display_bar
color_green:
    mov eax, lightGreen + (black * 16)
display_bar:
    call SetTextColor
    mov dh, BAR_ROW
    mov dl, BAR_COL
    call Gotoxy
    mov edx, OFFSET progress_bar
    call WriteString
    mov eax, ebx
    imul eax, 5
    mov dh, BAR_ROW
    mov dl, BAR_COL
    add dl, 24
    call Gotoxy
    call WriteDec
    mov al, '%'
    call WriteChar
    mov eax, 100
    call Delay
    dec ecx
    jnz loading_loop
    call Crlf
    call Crlf
    mov eax, COLOR_COMPLETE
    call SetTextColor
    mov dh, BAR_ROW + 2
    mov dl, 30
    call Gotoxy
    mov edx, OFFSET complete_msg
    call WriteString
    call ReadChar
    mov eax, COLOR_MAIN
    call SetTextColor
    call Clrscr
    popad
    ret
ShowLoadingScreen ENDP

QuickLoading PROC
    pushad
    mov dh, 12
    mov dl, 35
    call Gotoxy
    mov ecx, 3
quick_loop:
    push ecx
    mov eax, COLOR_LOADING
    call SetTextColor
    mov edx, OFFSET loading_msg
    call WriteString
    mov ebx, 3
    sub ebx, ecx
    mov ecx, ebx
    inc ecx
print_dots:
    mov al, '.'
    call WriteChar
    loop print_dots
    mov ecx, 3
    sub ecx, ebx
    jle no_spaces
clear_spaces:
    mov al, ' '
    call WriteChar
    loop clear_spaces
no_spaces:
    mov dh, 12
    mov dl, 35
    call Gotoxy
    mov eax, 300
    call Delay
    pop ecx
    loop quick_loop
    mov dh, 12
    mov dl, 35
    call Gotoxy
    mov ecx, 15
clear_loop:
    mov al, ' '
    call WriteChar
    loop clear_loop
    popad
    ret
QuickLoading ENDP

OperationLoading PROC
    pushad
    mov dh, 10
    mov dl, 20
    call Gotoxy
    mov eax, COLOR_LOADING
    call SetTextColor
    mov edx, OFFSET loading_msg
    call WriteString
    mov dh, 12
    mov dl, 20
    call Gotoxy
    mov edx, OFFSET progress_bar
    call WriteString
    mov esi, OFFSET progress_bar
    add esi, 1
    mov ecx, 20
    xor ebx, ebx
op_loading_loop:
    inc ebx
    mov byte ptr [esi], 0DBh
    inc esi
    mov eax, ebx
    cmp eax, 5
    jl op_color_red
    cmp eax, 10
    jl op_color_yellow
    cmp eax, 15
    jl op_color_blue
    jmp op_color_green
op_color_red:
    mov eax, lightRed + (black * 16)
    jmp op_display_bar
op_color_yellow:
    mov eax, yellow + (black * 16)
    jmp op_display_bar
op_color_blue:
    mov eax, lightBlue + (black * 16)
    jmp op_display_bar
op_color_green:
    mov eax, lightGreen + (black * 16)
op_display_bar:
    call SetTextColor
    mov dh, 12
    mov dl, 20
    call Gotoxy
    mov edx, OFFSET progress_bar
    call WriteString
    mov eax, ebx
    imul eax, 5
    mov dh, 12
    mov dl, 45
    call Gotoxy
    call WriteDec
    mov al, '%'
    call WriteChar
    mov eax, 80
    call Delay
    dec ecx
    jnz op_loading_loop
    mov eax, 500
    call Delay
    popad
    ret
OperationLoading ENDP

SafeReadInt PROC
    push edx
    push ecx
    push esi
    mov edi, OFFSET inputBuffer
    mov ecx, SIZEOF inputBuffer
    xor al, al
    cld
    rep stosb
    mov edx, OFFSET inputBuffer
    mov ecx, SIZEOF inputBuffer - 1
    call ReadString
    test eax, eax
    jz InvalidInput
    mov edx, OFFSET inputBuffer
    call ParseInteger32
    jc InvalidInput
    clc
    jmp Done
InvalidInput:
    stc
Done:
    pop esi
    pop ecx
    pop edx
    ret
SafeReadInt ENDP

CompareStrings PROC
    push eax
    push ebx
    push esi
    push edi
CompareLoop:
    mov al, [esi]
    mov bl, [edi]
    cmp al, bl
    jne NotEqual
    test al, al
    jz Equal
    inc esi
    inc edi
    jmp CompareLoop
Equal:
    xor eax, eax
    jmp DoneCompare
NotEqual:
    or eax, 1
DoneCompare:
    pop edi
    pop esi
    pop ebx
    pop eax
    ret
CompareStrings ENDP

ClearBuffer PROC
    push eax
    push edi
    push ecx
    xor al, al
    cld
    rep stosb
    pop ecx
    pop edi
    pop eax
    ret
ClearBuffer ENDP

FindAccountByNumber PROC
    push ebx
    push ecx
    push edx
    push edi
    xor ebx, ebx
    mov ecx, accountCount
    test ecx, ecx
    jz NotFound
SearchLoop:
    cmp ebx, ecx
    jge NotFound
    mov edx, SIZEOF Account
    imul edx, ebx
    lea edi, accounts[edx]
    cmp eax, (Account PTR [edi]).accountNum
    je Found
    inc ebx
    jmp SearchLoop
Found:
    mov eax, ebx
    jmp Done
NotFound:
    mov eax, -1
Done:
    pop edi
    pop edx
    pop ecx
    pop ebx
    ret
FindAccountByNumber ENDP

DisplayMessage PROC
    push eax
    push edx
    push ebx
    call Crlf
    call Crlf
    mov eax, COLOR_SUCCESS
    call SetTextColor
    mov edx, ebx
    call WriteString
    mov al, ':'
    call WriteChar
    mov al, ' '
    call WriteChar
    mov edx, [esp+4]
    call WriteString
    call Crlf
    call Crlf
    mov eax, COLOR_INPUT
    call SetTextColor
    mov edx, OFFSET msgContinue
    call WriteString
    call ReadChar
    pop ebx
    pop edx
    pop eax
    ret
DisplayMessage ENDP

SetupConsole PROC
    mov eax, COLOR_MAIN
    call SetTextColor
    call Clrscr
    ret
SetupConsole ENDP

DisplayBanner PROC
    call Clrscr
    mov eax, COLOR_BANNER
    call SetTextColor
    mov edx, OFFSET banner
    call WriteString
    mov eax, COLOR_MAIN
    call SetTextColor
    ret
DisplayBanner ENDP

DisplayMainMenu PROC
    call Crlf
    mov eax, COLOR_MENU
    call SetTextColor
    mov edx, OFFSET mainMenu
    call WriteString
    mov eax, COLOR_INPUT
    call SetTextColor
    mov edx, OFFSET prompt
    call WriteString
    ret
DisplayMainMenu ENDP

DisplayAdminMenu PROC
    call Clrscr
    call DisplayBanner
    call Crlf
    mov eax, COLOR_ADMIN
    call SetTextColor
    mov edx, OFFSET adminMenu
    call WriteString
    mov eax, COLOR_INPUT
    call SetTextColor
    mov edx, OFFSET prompt
    call WriteString
    ret
DisplayAdminMenu ENDP

DisplayUserMenu PROC
    call Clrscr
    call DisplayBanner
    call Crlf
    mov eax, COLOR_USER
    call SetTextColor
    mov edx, OFFSET userMenu
    call WriteString
    mov eax, COLOR_INPUT
    call SetTextColor
    mov edx, OFFSET prompt
    call WriteString
    ret
DisplayUserMenu ENDP

AdminLoginProc PROC
    call Clrscr
    call DisplayBanner
    call Crlf
    call Crlf
    mov eax, COLOR_INPUT
    call SetTextColor
    mov edi, OFFSET inputBuffer
    mov ecx, SIZEOF inputBuffer
    call ClearBuffer
    mov edi, OFFSET tempBuffer
    mov ecx, SIZEOF tempBuffer
    call ClearBuffer
    mov edx, OFFSET promptID
    call WriteString
    mov edx, OFFSET inputBuffer
    mov ecx, SIZEOF inputBuffer - 1
    call ReadString
    call Crlf
    mov edx, OFFSET promptPass
    call WriteString
    mov edx, OFFSET tempBuffer
    mov ecx, SIZEOF tempBuffer - 1
    call ReadString
    mov esi, OFFSET inputBuffer
    mov edi, OFFSET adminID
    call CompareStrings
    jnz LoginFailed
    mov esi, OFFSET tempBuffer
    mov edi, OFFSET adminPassword
    call CompareStrings
    jnz LoginFailed
    mov ebx, OFFSET titleAdmin
    mov edx, OFFSET msgWelcome
    call DisplayMessage
    mov eax, 1
    ret
LoginFailed:
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgInvalid
    call DisplayMessage
    xor eax, eax
    ret
AdminLoginProc ENDP

UserLoginProc PROC
    call Clrscr
    call DisplayBanner
    call Crlf
    call Crlf
    mov eax, COLOR_INPUT
    call SetTextColor
    mov edx, OFFSET promptAccNum
    call WriteString
    call SafeReadInt
    jc LoginFailed
    test eax, eax
    jle LoginFailed
    push eax
    call Crlf
    mov edx, OFFSET promptPIN
    call WriteString
    call SafeReadInt
    jc LoginFailedPop
    cmp eax, 1000
    jl LoginFailedPop
    cmp eax, 9999
    jg LoginFailedPop
    mov edi, eax
    pop eax
    call FindAccountByNumber
    cmp eax, -1
    je LoginFailed
    mov ebx, SIZEOF Account
    imul ebx, eax
    lea esi, accounts[ebx]
    cmp edi, (Account PTR [esi]).pin
    jne LoginFailed
    cmp (Account PTR [esi]).active, 1
    jne LoginFailed
    mov currentAccIdx, eax
    mov ebx, OFFSET titleUser
    mov edx, OFFSET msgWelcome
    call DisplayMessage
    mov eax, currentAccIdx
    ret
LoginFailedPop:
    pop eax
LoginFailed:
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgInvalid
    call DisplayMessage
    mov eax, -1
    ret
UserLoginProc ENDP

CreateAccountProc PROC
    call Clrscr
    call OperationLoading
    call DisplayBanner
    call Crlf
    call Crlf
    mov eax, COLOR_INPUT
    call SetTextColor
    mov eax, accountCount
    cmp eax, MAX_ACCOUNTS
    jge MaxAccounts
GetAccNum:
    mov edx, OFFSET promptAccNum
    call WriteString
    call SafeReadInt
    jc InvalidAccNum
    test eax, eax
    jle InvalidAccNum
    push eax
    call FindAccountByNumber
    cmp eax, -1
    jne AccExists
    pop eax
    push eax
GetPIN:
    call Crlf
    mov edx, OFFSET promptPIN
    call WriteString
    call SafeReadInt
    jc InvalidPIN
    cmp eax, 1000
    jl InvalidPIN
    cmp eax, 9999
    jg InvalidPIN
    mov ebx, accountCount
    mov ecx, SIZEOF Account
    imul ecx, ebx
    lea edi, accounts[ecx]
    pop ecx
    mov (Account PTR [edi]).accountNum, ecx
    mov (Account PTR [edi]).pin, eax
    mov (Account PTR [edi]).balance, 0
    mov (Account PTR [edi]).active, 1
    inc accountCount
    mov ebx, OFFSET titleSuccess
    mov edx, OFFSET msgSuccess
    call DisplayMessage
    ret
InvalidAccNum:
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgInvalidAccNum
    call DisplayMessage
    jmp GetAccNum
InvalidPIN:
    pop eax
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgInvalidPIN
    call DisplayMessage
    jmp GetAccNum
AccExists:
    pop eax
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgAccExists
    call DisplayMessage
    jmp GetAccNum
MaxAccounts:
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgMaxAccounts
    call DisplayMessage
    ret
CreateAccountProc ENDP

ViewAccountProc PROC
    call Clrscr
    call QuickLoading
    call DisplayBanner
    call Crlf
    call Crlf
    mov eax, COLOR_INPUT
    call SetTextColor
GetAccNum:
    mov edx, OFFSET promptAccNum
    call WriteString
    call SafeReadInt
    jc InvalidInput
    test eax, eax
    jle InvalidInput
    call FindAccountByNumber
    cmp eax, -1
    je NotFound
    mov ebx, SIZEOF Account
    imul ebx, eax
    lea esi, accounts[ebx]
    call Crlf
    call Crlf
    mov eax, COLOR_BALANCE
    call SetTextColor
    mov edx, OFFSET msgBalance
    call WriteString
    mov eax, (Account PTR [esi]).balance
    call WriteInt
    call Crlf
    call Crlf
    mov eax, COLOR_INPUT
    call SetTextColor
    mov edx, OFFSET msgContinue
    call WriteString
    call ReadChar
    ret
InvalidInput:
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgInvalidAccNum
    call DisplayMessage
    jmp GetAccNum
NotFound:
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgFailed
    call DisplayMessage
    ret
ViewAccountProc ENDP

DepositMoneyProc PROC
    call Clrscr
    call OperationLoading
    call DisplayBanner
    call Crlf
    call Crlf
    mov eax, COLOR_INPUT
    call SetTextColor
GetAccNum:
    mov edx, OFFSET promptAccNum
    call WriteString
    call SafeReadInt
    jc InvalidAccNum
    test eax, eax
    jle InvalidAccNum
    call FindAccountByNumber
    cmp eax, -1
    je NotFound
    push eax
GetAmount:
    call Crlf
    mov edx, OFFSET promptAmount
    call WriteString
    call SafeReadInt
    jc InvalidAmount
    test eax, eax
    jle InvalidAmount
    pop ebx
    mov ecx, SIZEOF Account
    imul ecx, ebx
    lea edi, accounts[ecx]
    add (Account PTR [edi]).balance, eax
    mov ebx, OFFSET titleSuccess
    mov edx, OFFSET msgSuccess
    call DisplayMessage
    ret
InvalidAccNum:
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgInvalidAccNum
    call DisplayMessage
    jmp GetAccNum
InvalidAmount:
    pop eax
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgInvalidAmount
    call DisplayMessage
    jmp GetAccNum
NotFound:
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgFailed
    call DisplayMessage
    ret
DepositMoneyProc ENDP

AdminWithdrawProc PROC
    call Clrscr
    call OperationLoading
    call DisplayBanner
    call Crlf
    call Crlf
    mov eax, COLOR_INPUT
    call SetTextColor
GetAccNum:
    mov edx, OFFSET promptAccNum
    call WriteString
    call SafeReadInt
    jc InvalidAccNum
    test eax, eax
    jle InvalidAccNum
    call FindAccountByNumber
    cmp eax, -1
    je NotFound
    push eax
GetAmount:
    call Crlf
    mov edx, OFFSET promptAmount
    call WriteString
    call SafeReadInt
    jc InvalidAmount
    test eax, eax
    jle InvalidAmount
    pop ebx
    push ebx
    mov ecx, SIZEOF Account
    imul ecx, ebx
    lea edi, accounts[ecx]
    cmp eax, (Account PTR [edi]).balance
    jg InsufficientBal
    sub (Account PTR [edi]).balance, eax
    pop ebx
    mov ebx, OFFSET titleSuccess
    mov edx, OFFSET msgSuccess
    call DisplayMessage
    ret
InvalidAccNum:
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgInvalidAccNum
    call DisplayMessage
    jmp GetAccNum
InvalidAmount:
    pop eax
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgInvalidAmount
    call DisplayMessage
    jmp GetAccNum
InsufficientBal:
    pop ebx
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgInsufficientBal
    call DisplayMessage
    ret
NotFound:
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgFailed
    call DisplayMessage
    ret
AdminWithdrawProc ENDP

ShowAllAccountsProc PROC
    call Clrscr
    call QuickLoading
    call DisplayBanner
    call Crlf
    mov eax, accountCount
    test eax, eax
    jz NoAccounts
    mov eax, COLOR_MENU
    call SetTextColor
    mov edx, OFFSET msgAccHeader
    call WriteString
    mov eax, COLOR_INPUT
    call SetTextColor
    xor ebx, ebx
DisplayLoop:
    cmp ebx, accountCount
    jge DisplayDone
    mov ecx, SIZEOF Account
    imul ecx, ebx
    lea esi, accounts[ecx]
    mov eax, (Account PTR [esi]).accountNum
    call WriteDec
    mov edx, OFFSET msgSpaces
    call WriteString
    mov edx, OFFSET maskPIN
    call WriteString
    mov edx, OFFSET msgSpaces
    call WriteString
    mov al, '$'
    call WriteChar
    mov eax, (Account PTR [esi]).balance
    call WriteInt
    mov edx, OFFSET msgSpaces
    call WriteString
    cmp (Account PTR [esi]).active, 1
    jne ShowInactive
    mov edx, OFFSET msgActive
    jmp ShowStatus
ShowInactive:
    mov edx, OFFSET msgInactive
ShowStatus:
    call WriteString
    call Crlf
    inc ebx
    jmp DisplayLoop
DisplayDone:
    call Crlf
    mov edx, OFFSET msgContinue
    call WriteString
    call ReadChar
    ret
NoAccounts:
    mov ebx, OFFSET titleInfo
    mov edx, OFFSET msgNoAccounts
    call DisplayMessage
    ret
ShowAllAccountsProc ENDP

DeleteAccountProc PROC
    call Clrscr
    call OperationLoading
    call DisplayBanner
    call Crlf
    call Crlf
    mov eax, COLOR_INPUT
    call SetTextColor
GetAccToDelete:
    mov edx, OFFSET promptDeleteAcc
    call WriteString
    call SafeReadInt
    jc InvalidInputDelete
    test eax, eax
    jle InvalidInputDelete
    call FindAccountByNumber
    cmp eax, -1
    je AccountNotFound
    mov ebx, eax
    call Crlf
    mov edx, OFFSET msgDeleteConfirm
    call WriteString
    call SafeReadInt
    jc DeleteCancelled
    cmp eax, 1
    jne DeleteCancelled
    mov ecx, accountCount
    dec ecx
    cmp ebx, ecx
    jge NoShiftNeeded
ShiftLoop:
    mov eax, ebx
    inc eax
    cmp eax, accountCount
    jge ShiftDone
    mov edx, SIZEOF Account
    imul edx, eax
    lea esi, accounts[edx]
    mov edx, SIZEOF Account
    imul edx, ebx
    lea edi, accounts[edx]
    push ecx
    mov ecx, SIZEOF Account
    rep movsb
    pop ecx
    inc ebx
    jmp ShiftLoop
ShiftDone:
NoShiftNeeded:
    dec accountCount
    mov ebx, OFFSET titleSuccess
    mov edx, OFFSET msgAccDeleted
    call DisplayMessage
    ret
InvalidInputDelete:
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgInvalidAccNum
    call DisplayMessage
    jmp GetAccToDelete
AccountNotFound:
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgAccNotFound
    call DisplayMessage
    ret
DeleteCancelled:
    mov ebx, OFFSET titleInfo
    mov edx, OFFSET msgDeleteCancelled
    call DisplayMessage
    ret
DeleteAccountProc ENDP

CheckBalanceProc PROC
    call Clrscr
    call QuickLoading
    call DisplayBanner
    call Crlf
    call Crlf
    call Crlf
    mov eax, COLOR_BALANCE
    call SetTextColor
    mov eax, currentAccIdx
    mov ebx, SIZEOF Account
    imul ebx, eax
    lea esi, accounts[ebx]
    mov edx, OFFSET msgBalance
    call WriteString
    mov eax, (Account PTR [esi]).balance
    call WriteInt
    call Crlf
    call Crlf
    mov eax, COLOR_INPUT
    call SetTextColor
    mov edx, OFFSET msgContinue
    call WriteString
    call ReadChar
    ret
CheckBalanceProc ENDP

WithdrawMoneyProc PROC
    call Clrscr
    call QuickLoading
    call DisplayBanner
    call Crlf
    call Crlf
    mov eax, COLOR_INPUT
    call SetTextColor
GetAmount:
    mov edx, OFFSET promptAmount
    call WriteString
    call SafeReadInt
    jc InvalidAmount
    test eax, eax
    jle InvalidAmount
    mov ebx, currentAccIdx
    mov ecx, SIZEOF Account
    imul ecx, ebx
    lea esi, accounts[ecx]
    cmp eax, (Account PTR [esi]).balance
    jg InsufficientBal
    sub (Account PTR [esi]).balance, eax
    mov ebx, OFFSET titleSuccess
    mov edx, OFFSET msgSuccess
    call DisplayMessage
    ret
InvalidAmount:
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgInvalidAmount
    call DisplayMessage
    jmp GetAmount
InsufficientBal:
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgInsufficientBal
    call DisplayMessage
    ret
WithdrawMoneyProc ENDP

SendMoneyProc PROC
    call Clrscr
    call OperationLoading
    call DisplayBanner
    call Crlf
    call Crlf
    mov eax, COLOR_INPUT
    call SetTextColor
GetRecipient:
    mov edx, OFFSET promptToAcc
    call WriteString
    call SafeReadInt
    jc InvalidRecipient
    test eax, eax
    jle InvalidRecipient
    mov ebx, currentAccIdx
    mov ecx, SIZEOF Account
    imul ecx, ebx
    lea esi, accounts[ecx]
    cmp eax, (Account PTR [esi]).accountNum
    je SameAccount
    call FindAccountByNumber
    cmp eax, -1
    je RecipientNotFound
    push eax
GetAmount:
    call Crlf
    mov edx, OFFSET promptAmount
    call WriteString
    call SafeReadInt
    jc InvalidAmount
    test eax, eax
    jle InvalidAmount
    push eax
    mov ebx, currentAccIdx
    mov ecx, SIZEOF Account
    imul ecx, ebx
    lea esi, accounts[ecx]
    pop eax
    cmp eax, (Account PTR [esi]).balance
    jg InsufficientBal
    push eax
GetPIN:
    call Crlf
    mov edx, OFFSET promptConfirmPIN
    call WriteString
    call SafeReadInt
    jc InvalidPIN
    cmp eax, 1000
    jl InvalidPIN
    cmp eax, 9999
    jg InvalidPIN
    cmp eax, (Account PTR [esi]).pin
    jne WrongPIN
    pop eax
    pop ebx
    mov ecx, currentAccIdx
    mov edx, SIZEOF Account
    imul edx, ecx
    lea esi, accounts[edx]
    sub (Account PTR [esi]).balance, eax
    mov edx, SIZEOF Account
    imul edx, ebx
    lea edi, accounts[edx]
    add (Account PTR [edi]).balance, eax
    mov ebx, OFFSET titleSuccess
    mov edx, OFFSET msgSuccess
    call DisplayMessage
    ret
InvalidRecipient:
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgInvalidAccNum
    call DisplayMessage
    jmp GetRecipient
SameAccount:
    mov ebx, OFFSET titleWarning
    mov edx, OFFSET msgSameAcc
    call DisplayMessage
    jmp GetRecipient
RecipientNotFound:
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgAccNotExist
    call DisplayMessage
    jmp GetRecipient
InvalidAmount:
    pop eax
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgInvalidAmount
    call DisplayMessage
    jmp GetRecipient
InsufficientBal:
    pop eax
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgInsufficientBal
    call DisplayMessage
    ret
InvalidPIN:
    pop eax
    pop eax
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgInvalidPIN
    call DisplayMessage
    jmp GetRecipient
WrongPIN:
    pop eax
    pop eax
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgPINMismatch
    call DisplayMessage
    jmp GetRecipient
SendMoneyProc ENDP

ChangePINProc PROC
    call Clrscr
    call QuickLoading
    call DisplayBanner
    call Crlf
    call Crlf
    mov eax, COLOR_INPUT
    call SetTextColor
    mov eax, currentAccIdx
    mov ebx, SIZEOF Account
    imul ebx, eax
    lea esi, accounts[ebx]
GetOldPIN:
    mov edx, OFFSET promptOldPIN
    call WriteString
    call SafeReadInt
    jc InvalidOldPIN
    cmp eax, 1000
    jl InvalidOldPIN
    cmp eax, 9999
    jg InvalidOldPIN
    cmp eax, (Account PTR [esi]).pin
    jne WrongPIN
GetNewPIN:
    call Crlf
    mov edx, OFFSET promptNewPIN
    call WriteString
    call SafeReadInt
    jc InvalidNewPIN
    cmp eax, 1000
    jl InvalidNewPIN
    cmp eax, 9999
    jg InvalidNewPIN
    mov (Account PTR [esi]).pin, eax
    mov ebx, OFFSET titleSuccess
    mov edx, OFFSET msgPINChanged
    call DisplayMessage
    ret
InvalidOldPIN:
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgInvalidPIN
    call DisplayMessage
    jmp GetOldPIN
WrongPIN:
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgPINMismatch
    call DisplayMessage
    jmp GetOldPIN
InvalidNewPIN:
    mov ebx, OFFSET titleError
    mov edx, OFFSET msgInvalidPIN
    call DisplayMessage
    jmp GetNewPIN
ChangePINProc ENDP

SaveAccountData PROC
    pushad
    mov edx, OFFSET filename
    call CreateOutputFile
    cmp eax, INVALID_HANDLE_VALUE
    je SaveError
    mov fileHandle, eax
    mov eax, fileHandle
    mov edx, OFFSET accountCount
    mov ecx, 4
    call WriteToFile
    mov eax, fileHandle
    mov edx, OFFSET accounts
    mov ecx, SIZEOF Account
    imul ecx, accountCount
    call WriteToFile
    mov eax, fileHandle
    call CloseFile
SaveError:
    popad
    ret
SaveAccountData ENDP

LoadAccountData PROC
    pushad
    mov edx, OFFSET filename
    call OpenInputFile
    cmp eax, INVALID_HANDLE_VALUE
    je LoadError
    mov fileHandle, eax
    mov eax, fileHandle
    mov edx, OFFSET accountCount
    mov ecx, 4
    call ReadFromFile
    mov eax, fileHandle
    mov edx, OFFSET accounts
    mov ecx, SIZEOF Account
    imul ecx, MAX_ACCOUNTS
    call ReadFromFile
    mov eax, fileHandle
    call CloseFile
LoadError:
    popad
    ret
LoadAccountData ENDP

main PROC
    call SetupConsole
    call ShowLoadingScreen
    call LoadAccountData
MainLoop:
    call DisplayBanner
    call DisplayMainMenu
    call SafeReadInt
    jc InvalidInputMain
    cmp eax, 1
    je AdminLogin
    cmp eax, 2
    je UserLogin
    cmp eax, 3
    je ExitProgram
InvalidInputMain:
    mov ebx, OFFSET titleWarning
    mov edx, OFFSET msgInvalidChoice
    call DisplayMessage
    jmp MainLoop
AdminLogin:
    call AdminLoginProc
    test eax, eax
    jz MainLoop
    jmp AdminPanelLoop
AdminPanelLoop:
    call DisplayAdminMenu
    call SafeReadInt
    jc InvalidInputAdmin
    cmp eax, 1
    je CreateAccount
    cmp eax, 2
    je ViewAccount
    cmp eax, 3
    je DepositMoney
    cmp eax, 4
    je AdminWithdraw
    cmp eax, 5
    je ShowAllAccounts
    cmp eax, 6
    je DeleteAccount
    cmp eax, 7
    je MainLoop
InvalidInputAdmin:
    mov ebx, OFFSET titleWarning
    mov edx, OFFSET msgInvalidChoice
    call DisplayMessage
    jmp AdminPanelLoop
UserLogin:
    call UserLoginProc
    cmp eax, -1
    je MainLoop
    mov currentAccIdx, eax
    jmp UserPanelLoop
UserPanelLoop:
    call DisplayUserMenu
    call SafeReadInt
    jc InvalidInputUser
    cmp eax, 1
    je CheckBalance
    cmp eax, 2
    je WithdrawMoney
    cmp eax, 3
    je SendMoney
    cmp eax, 4
    je ChangePIN
    cmp eax, 5
    je MainLoop
InvalidInputUser:
    mov ebx, OFFSET titleWarning
    mov edx, OFFSET msgInvalidChoice
    call DisplayMessage
    jmp UserPanelLoop
CreateAccount:
    call CreateAccountProc
    jmp AdminPanelLoop
ViewAccount:
    call ViewAccountProc
    jmp AdminPanelLoop
DepositMoney:
    call DepositMoneyProc
    jmp AdminPanelLoop
AdminWithdraw:
    call AdminWithdrawProc
    jmp AdminPanelLoop
ShowAllAccounts:
    call ShowAllAccountsProc
    jmp AdminPanelLoop
DeleteAccount:
    call DeleteAccountProc
    jmp AdminPanelLoop
CheckBalance:
    call CheckBalanceProc
    jmp UserPanelLoop
WithdrawMoney:
    call WithdrawMoneyProc
    jmp UserPanelLoop
SendMoney:
    call SendMoneyProc
    jmp UserPanelLoop
ChangePIN:
    call ChangePINProc
    jmp UserPanelLoop
ExitProgram:
    call SaveAccountData
    mov ebx, OFFSET titleMain
    mov edx, OFFSET msgGoodbye
    call DisplayMessage
    call Clrscr
    exit
main ENDP

END main