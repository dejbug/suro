; 14 Feb 2020 / Dejan Budimir / <dejbug@gmail.com>

; #include "resource.inc"


ERROR_NONE = 0
ERROR_MODULE_NAME = 1
ERROR_MODULE_NAME_EXT = 2
ERROR_NO_CONFIG_OR_BAT = 3
ERROR_TOO_MANY_ARGS = 4
ERROR_SPAWN = 5
ERROR_SPAWN_FILE_NOT_FOUND = 6
ERROR_SPAWN_NOT_EXE = 7
ERROR_SPAWN_OUT_OF_MEM = 8

MAX_CMDLINE_ARGS = 64 ; TODO: Don't limit this. Use the heap.
MAX_CMDLINE_BYTES = 2048
MAX_CMDLINE_BUFFER_BYTES = 2 * MAX_CMDLINE_BYTES


MAX_PATH = 260

_P_WAIT = 0
; _P_NOWAIT = 1
_P_OVERLAY = 2
; _P_NOWAITO = 3
; _P_DETACH = 4

; E2BIG = 7
; EINVAL = 22
ENOENT = 2
ENOEXEC = 8
ENOMEM = 12


CONST SECTION

fileReadMode dw L"rt",0

; Find out how to use macros inside strings. What is the escape
; method? The "2048" down here should read "MAX_CMDLINE_BYTES".
; TODO: We could use a data buffer and write this value into it
; at runtime, but that isn't necessary if there is a way. GoAsm
; is a "single-pass assembler", but this should be possible at
; compile time.
pathRow1_lineScanFormat dw L"%2048[^",13,10,L"]",0


DATA SECTION

exeFilePath dw MAX_PATH+2 dup ?
exeFilePath_dotPos dd 0
pathFile_handle dd 0
cmdLine_buffer dw MAX_CMDLINE_BUFFER_BYTES dup ?
cmdLine_argc dd 0
; cmdLine_argv dd 0
cmdLine_args dd MAX_CMDLINE_ARGS+1 dup ?


CODE SECTION

start:

	; INVOKE OutputDebugStringW, L'"suro" by Dejan Budimir'


.getExeName:

	INVOKE GetModuleFileNameW, 0, ADDR exeFilePath, MAX_PATH

	test eax, eax
	jnz >.ensureExeNameIsAtLeastFourWcharsLong
	INVOKE ExitProcess, ERROR_MODULE_NAME


; The smallest possible exeFilepath should be
; L"c:\.exe" but we assume just the non-dir
; part, i.e. L".exe". Hence all exeFilepaths are
; assumed to be at least these 4 wchars (i.e. 8
; bytes) long.

.ensureExeNameIsAtLeastFourWcharsLong:

	cmp eax, 8 ; assert(eax >= wstrlen(L".exe"))
	jge >.moveToExeNameExtension
	INVOKE ExitProcess, ERROR_MODULE_NAME


.moveToExeNameExtension:

	;; Old way via stdlib function makes no assumption
	;; other than that an exeFilePath must have an
	;; extension.

	; push 2eh ; '.'
	; push ADDR exeFilePath
	; call wcsrchr
	; add esp,8
	; test eax, eax
	; jnz >.makeConfigName
	; INVOKE ExitProcess, ERROR_MODULE_NAME_EXT


	; We assume here that exeFilePath ends with L".exe".
	; Since eax holds the byte-length of exeFilePath, we
	; need only add the pointer.
	shl eax, 1 ; we want the number of *bytes*
	add eax, ADDR exeFilePath
	sub eax, 8 ; back up 4 wchars from the end

	mov [exeFilePath_dotPos], eax

	cmp w[eax], 2eh ; L'.'
	je >.makeConfigName
	INVOKE ExitProcess, ERROR_MODULE_NAME_EXT


; NOTICE that we've reserved dw MAX_PATH+2 for
; exeFilePath's buffer, so that overwriting
; L".exe" with L".path" can't overrun.

.makeConfigName:

	mov w[eax+2], L'p'
	mov w[eax+4], L'a'
	mov w[eax+6], L't'
	mov w[eax+8], L'h'
	mov w[eax+10], 0


.openConfig:

	push ADDR fileReadMode
	push ADDR exeFilePath
	call _wfopen
	add esp, 8
	mov [pathFile_handle], eax

	test eax, eax
	jnz >.readConfigLine


.noConfigSoTryBat:

	; push ADDR exeFilePath
	; push ADDR <L'* no "*.path" file found at ("%s")',13,0,10,0,0,0>
	; call wprintf
	; add esp, 8


.makeBatName:

	mov eax, [exeFilePath_dotPos]

	mov w[eax+2], L'b'
	mov w[eax+4], L'a'
	mov w[eax+6], L't'
	mov w[eax+8], 0


.doesBatExist:

	push ADDR fileReadMode
	push ADDR exeFilePath
	call _wfopen
	add esp, 8

	test eax, eax
	jz >.batDoesNotExist

	push eax
	call fclose
	add esp,4

	mov w[cmdLine_buffer], 0
	push ADDR exeFilePath
	push ADDR cmdLine_buffer
	call wcscat
	add esp,8

	jmp >.getCommandLineArguments


.batDoesNotExist:

	; push ADDR exeFilePath
	; push ADDR <L'* no "*.bat" file found at ("%s")',13,0,10,0,0,0>
	; call wprintf
	; add esp, 8

	INVOKE ExitProcess, ERROR_NO_CONFIG_OR_BAT


.readConfigLine:

	push ADDR cmdLine_buffer
	push ADDR pathRow1_lineScanFormat
	push [pathFile_handle]
	call fwscanf
	add esp,12

	push [pathFile_handle]
	call fclose
	add esp,4


.getCommandLineArguments:

	INVOKE GetCommandLineW
	mov edi, eax

	push eax
	call wcslen
	add esp, 4
	mov ecx, eax

	mov ax, L'"'
	add edi, 2
	cmp w[edi-2], ax
	je >.advanceToEndOfExeName
	mov ax, L' '
.advanceToEndOfExeName:
	cld
	repne scasw
	sub edi, 2
	mov w[edi], L' ' ; overwrites argv[0]'s closing '"' or last char


.appendArgumentsToConfigLine:

	push edi
	push ADDR cmdLine_buffer
	call wcscat
	add esp,8


.tokeniseConfigLine:

	INVOKE CommandLineToArgvW, ADDR cmdLine_buffer, ADDR cmdLine_argc
	; mov [cmdLine_argv], eax
	mov esi, eax

	mov eax, [cmdLine_argc]
	cmp eax, MAX_CMDLINE_ARGS
	jle >.fillArgsArray
	INVOKE ExitProcess, ERROR_TOO_MANY_ARGS


.fillArgsArray:

	mov edi, ADDR cmdLine_args
	mov ecx, [cmdLine_argc]
	cld
	rep movsd
	mov d[edi], 0


.spawn:

	mov eax, ADDR cmdLine_args
	push eax
	push [eax]
#ifdef CONSOLE
	push _P_WAIT
#else
	push _P_OVERLAY
#endif
	call _wspawnvp
	add esp,12

	test eax, eax
	jz >.end

	cmp eax, -1
	je >.spawnErrorM1

	INVOKE ExitProcess, eax


.spawnErrorM1:

	; push L"suro"
	; call _wperror
	; add esp,4

	call _errno
	mov eax, [eax]
	cmp eax, ENOENT
	je >.errnoENOENT
	cmp eax, ENOEXEC
	je >.errnoENOEXEC
	cmp eax, ENOMEM
	je >.errnoENOMEM

	INVOKE ExitProcess, ERROR_SPAWN


.errnoENOENT: INVOKE ExitProcess, ERROR_SPAWN_FILE_NOT_FOUND

.errnoENOEXEC: INVOKE ExitProcess, ERROR_SPAWN_NOT_EXE

.errnoENOMEM: INVOKE ExitProcess, ERROR_SPAWN_OUT_OF_MEM


.end:

	INVOKE ExitProcess, ERROR_NONE
