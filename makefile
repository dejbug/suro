SHELL := cmd.exe

NAME := suro
DEBUG := 0

ASSEMBLER := "e:\Programs\GoDevTool\Goasm\GoAsm.exe"
LINKER := "e:\Programs\GoDevTool\Golink\GoLink.exe"
RESOURCER := "e:\Programs\GoDevTool\Gorc\GoRC.exe"

SYSTEM32 := $(SystemRoot)\system32

ASSEMBLER_FLAGS := /ni
LINKER_FLAGS := /ni /unused /files

ifeq ($(DEBUG),1)
LINKER_FLAGS += /debug coff
endif
ifeq ($(DEBUG),2)
ASSEMBLER_FLAGS += /l
endif

LINKER_FLAGS_C := $(LINKER_FLAGS) /console
LINKER_FLAGS_W := $(LINKER_FLAGS)
ASSEMBLER_FLAGS_C := $(ASSEMBLER_FLAGS) /d DEBUG=$(DEBUG) /d CONSOLE
ASSEMBLER_FLAGS_W := $(ASSEMBLER_FLAGS) /d DEBUG=$(DEBUG)

WINLIBS := kernel32 shell32 msvcrt
WINDLLS := $(addsuffix .dll,$(addprefix $(SYSTEM32)\,$(WINLIBS)))

.PHONY : all
all : $(NAME)-c.exe $(NAME)-w.exe

$(NAME)-c.exe : main-c.obj resource.obj $(WINDLLS) $(DEJLIB_OBJECTS)
$(NAME)-w.exe : main-w.obj resource.obj $(WINDLLS) $(DEJLIB_OBJECTS)

resource.obj : resource.rc ; $(RESOURCER) /fo $@ /ni /o $(filter %.rc,$^)

%-c.exe : ; $(LINKER) /fo $@ $(LINKER_FLAGS_C) $(call LINKER_FILTER,$^)
%-w.exe : ; $(LINKER) /fo $@ $(LINKER_FLAGS_W) $(call LINKER_FILTER,$^)
%-c.obj : %.asm ; $(ASSEMBLER) /fo $@ $(ASSEMBLER_FLAGS_C) $<
%-w.obj : %.asm ; $(ASSEMBLER) /fo $@ $(ASSEMBLER_FLAGS_W) $<

LINKER_FILTER = $(filter %.obj %.exe %.dll %.res,$1)

.PHONY : clean reset

clean : ; del *.obj main.lst 2>NUL
reset : | clean ; del $(NAME)-c.exe $(NAME)-w.exe 2>NUL
