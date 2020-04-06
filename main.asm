; 14 Feb 2020 / Dejan Budimir / <dejbug@gmail.com>


ccall(funcname,%2,%3,%4,%5,%6) MACRO
	#if ARGCOUNT=1
	INVOKE funcname
	#elif ARGCOUNT=2
	INVOKE funcname,%2
	#elif ARGCOUNT=3
	INVOKE funcname,%2,%3
	#elif ARGCOUNT=4
	INVOKE funcname,%2,%3,%4
	#elif ARGCOUNT=5
	INVOKE funcname,%2,%3,%4,%5
	#elif ARGCOUNT=6
	INVOKE funcname,%2,%3,%4,%5,%6
	#endif
	#if ARGCOUNT>1
	ADD esp, ARGCOUNT-1*4
	#endif
ENDM

DUMP(%1) MACRO
#if DEBUG > 0
	PUSH eax,ebx,ecx,edx,esi,edi

	; ccall (wprintf, ADDR L'%1 = %08X (%d)', %1, %1)
	; INVOKE Endl

	PUSH %1
	PUSH %1
	PUSH ADDR L'%1 = %08X (%d)'
	CALL wprintf
	ADD ESP, 12
	INVOKE Endl

	POP edi,esi,edx,ecx,ebx,eax
#endif
ENDM


DUMPS(%1) MACRO
#if DEBUG > 0
	PUSH eax,ebx,ecx,edx,esi,edi

	PUSH %1
	PUSH %1
	PUSH ADDR L'%1 = %08X |%s|'
	CALL wprintf
	ADD ESP, 12

	INVOKE Endl

	POP edi,esi,edx,ecx,ebx,eax
#endif
ENDM


ERROR_NONE = 0
ERROR_MODULE_NAME = 1
ERROR_MODULE_NAME_EXT = 2
ERROR_NO_CONFIG_OR_BAT = 3
ERROR_TOO_MANY_ARGS = 4
ERROR_SPAWN = 5
ERROR_SPAWN_FILE_NOT_FOUND = 6
ERROR_SPAWN_NOT_EXE = 7
ERROR_SPAWN_OUT_OF_MEM = 8

MAX_PATH = 260
MAX_CONFIG_PATH_SIZE = MAX_PATH + 8

_P_WAIT = 0
_P_OVERLAY = 2

ENOENT = 2
ENOEXEC = 8
ENOMEM = 12


DATA SECTION


configPath DW MAX_CONFIG_PATH_SIZE DUP ?
configPathLength DD 0

configLine DW 2048 DUP ?

argc dd 0


CONST SECTION


lineScanFormat DW L'%2048[^', 13, 10, L']'


CODE SECTION


Endl:
#if DEBUG > 0
	PUSH ADDR <13,0,10,0,0,0>
	CALL wprintf
	ADD ESP, 4
#endif
	RET


PrintString FRAME text
#if DEBUG > 0
	ccall (wprintf, [text])
#endif
	RET
ENDF


OpenFileForReading FRAME path
	ccall (_wfopen, [path], ADDR L"rt")
	RET
ENDF


GetExePath FRAME path, size

	INVOKE GetModuleFileNameW, 0, [path], MAX_PATH
	MOV [size], eax

	; Ensure result is at least 4 chars long.
	CMP eax, 8 ; assert(eax >= wstrlen(L".exe"))
	JGE >.ok

	INVOKE PrintString, ADDR <L"! couldn't retrieve exe path",13,0,10,0,0,0>
	INVOKE ExitProcess, ERROR_MODULE_NAME

.ok RET
ENDF


SetExt FRAME path, size, ext
	USES ebx
	LOCALS extPtr

.moveToExt

	ccall (wcsrchr, [path], 2Eh)

	TEST eax, eax
	JNZ >.next

	MOV eax, [path]

	; eax is either [path] or the right-most dot's char-address.

.next
	MOV ebx, eax
	SUB ebx, [path]
	SHR ebx, 1

	; ebx is 0 or the offset to the extension.

	NEG ebx
	ADD ebx, [size]

	; ebx is the number of available output chars.

.replaceExt
	ccall (wcsncpy, eax, [ext], ebx)

	; Make sure the string is zero-terminated.
	MOV D[eax+ebx*2-2], 0

	RET

ENDF


TryOpenWithExt FRAME templatePath, ext

	INVOKE SetExt, [templatePath], MAX_CONFIG_PATH_SIZE, [ext]
	INVOKE OpenFileForReading, [templatePath]

	RET

ENDF


OpenConfig FRAME templatePath

	INVOKE TryOpenWithExt, [templatePath], ADDR L'.path'

	TEST eax, eax
	JNZ >.ok

	INVOKE TryOpenWithExt, [templatePath], ADDR L'.bat'

	TEST eax, eax
	JZ >.fnf

	ccall (fclose, eax)
	JMP >.ok

.fnf

	INVOKE PrintString, L"! no config file was found"
	INVOKE ExitProcess, ERROR_NO_CONFIG_OR_BAT

.ok RET
ENDF


InitConfigLine FRAME handle

	MOV eax, [handle]
	TEST eax, eax
	JZ >.noConfigDoBat

	INVOKE ReadLineAndClose, eax, ADDR configLine
	MOV eax, _P_OVERLAY

	JMP >.end

.noConfigDoBat

	ccall (wcscpy, ADDR configLine, ADDR configPath)
	MOV eax, _P_WAIT

.end

	RET

ENDF


ReadLineAndClose FRAME handle, buffer

	ccall (fwscanf, [handle], ADDR lineScanFormat, [buffer])
	ccall (fclose, [handle])

	RET

ENDF


SkipArgv0 FRAME text
	USES ecx, edi

	CLD

	ccall (wcslen, [text])
	MOV ecx, eax
	MOV edi, [text]

	MOV ax, L'"'
	SCASW
	JNE >.next1

	; Looking for the next '"'.

	REPNE SCASW
	TEST ecx, ecx
	JZ >.end

	; Skipping all the consecutive '"'.
	; This is garbage added by the '^"' escape sequence.

	REPE SCASW
	JMP >.next2

.next1
	MOV ax, L' '
	REPNE SCASW
	TEST ecx, ecx
	JNZ >.end

.next2
	TEST ecx, ecx
	JNZ >.end
	DEC edi
	DEC edi

.end
	MOV eax, edi
	RET

ENDF


AppendCommandLineArgumentsToConfigLine FRAME

	INVOKE GetCommandLineW
	INVOKE SkipArgv0, eax
	ccall (wcscat, ADDR configLine, eax)
	RET

ENDF


PrintTokenizedCommandLine FRAME argv, argc
#if DEBUG > 1
	USES ebx

	MOV eax, [argv]

 	DUMP([argc])
 	DUMPS([eax+0])

	XOR ebx, ebx
.loop
	CMP ebx, [argc]
	JGE >.next
	INC ebx
	DUMPS([eax+4*ebx])
	JMP .loop
.next

#endif
	RET
ENDF


Spawn FRAME argv, argc

	MOV eax, [argv]
	PUSH eax
	PUSH [eax]

#ifdef CONSOLE
	PUSH _P_WAIT
#else
	PUSH _P_OVERLAY
#endif

	CALL _wspawnvp
	ADD esp,12

	TEST eax, eax
	JZ >.ok

	CMP eax, -1
	JE >.spawnErrorM1

	JMP >.ok

.spawnErrorM1:

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

.ok: RET

ENDF


start:

	INVOKE GetExePath, ADDR configPath, ADDR configPathLength
	INVOKE OpenConfig, ADDR configPath
	INVOKE InitConfigLine, eax

	INVOKE AppendCommandLineArgumentsToConfigLine
	INVOKE CommandLineToArgvW, eax, ADDR argc
	; INVOKE PrintTokenizedCommandLine, eax, [argc]

	INVOKE Spawn, eax, [argc]

	INVOKE ExitProcess, 0

	RET
