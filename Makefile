CXX=/usr/bin/gcc
LINKER=/usr/bin/gcc
C_OPT_FLAGS = -O3
SYS_LIB =-lm -lpthread
TARGET = app-executer

# other compilation flags
COMP_FLAGS = -DAPPROACH_WANG=1 -DPRINT_OUTPUT=1
CFLAGS= $(C_OPT_FLAGS) $(COMP_FLAGS)

# Every *.c file
TEST_C=$(wildcard *.c)

# Every value of TEST_CPP change it from .c -> .o
TEST_OBJ=$(TEST_C:.c=.o)

#$@, the name of the TARGET
#$<, the name of the first prerequisite
$(TARGET): $(TEST_OBJ)
	$(LINKER) -o $(TARGET) $(TEST_OBJ) $(SYS_LIB)

main.o: main.c
	$(LINKER) -o $@ -c $<

Settings.o: Settings.c
		$(LINKER) -o $@ -c $<

test:
	@echo "Not implemented yet..."

clean:
	@rm -f *.o *.bc *.bin *.log  *~ $(TARGET) $(TARGET).exe
