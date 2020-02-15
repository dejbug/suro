NAME := suro
DEBUG := 1
CONSOLE := 0

ASSEMBLER := GoAsm.exe
LINKER := GoLink.exe
RESOURCER := GoRC.exe

SYSTEM32 := $(SystemRoot)\system32

ASSEMBLER_FLAGS := /ni
LINKER_FLAGS := /ni

ifneq ($(CONSOLE),0)
	LINKER_FLAGS += /console
endif

ifeq ($(DEBUG),1)
LINKER_FLAGS += /debug coff /unused /files
endif
ifeq ($(DEBUG),2)
ASSEMBLER_FLAGS += /l
endif

WINLIBS := kernel32 shell32 msvcrt
WINDLLS := $(addsuffix .dll,$(addprefix $(SYSTEM32)\,$(WINLIBS)))

$(NAME).exe : main.obj resource.obj $(WINDLLS) $(DEJLIB_OBJECTS)

resource.obj : resource.rc ; $(RESOURCER) /fo $@ /ni /o $(filter %.rc,$^)

%.exe : ; $(LINKER) $(LINKER_FLAGS) /fo $@ $(call LINKER_FILTER,$^)
%.obj : %.asm ; $(ASSEMBLER) $(ASSEMBLER_FLAGS) /fo $@ $<

LINKER_FILTER = $(filter %.obj %.exe %.dll %.res,$1)

.PHONY : clean reset run

clean : ; DEL *.obj main.lst 2>NUL
reset : | clean ; DEL $(NAME).exe 2>NUL
run : $(NAME).exe ; @.\$<
