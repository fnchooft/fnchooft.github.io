# Makefile

CC = gcc
CFLAGS = -Wall -g # Use c99 for strdup
GSL = gsl

XML_INPUT = entities.xml
GSL_SCRIPT = entity_generator.gsl
MAIN_C = main.c
TARGET = entity_manager

# Infer entity names from the XML to generate list of C and H files
# This is a bit of a hack for Make. A more robust way might be for GSL to output a file list.
# For simplicity, we'll assume entity names don't have spaces or weird chars.
#ENTITIES := $(xmllint --xpath '//entity/@name' $(XML_INPUT) | sed 's| name="\([^"]*\)"|\1|g' | sed -e 'N;s/\n/ /' )
#ENTITIES := Person Product
#ENTITIES := $(shell xmlstarlet sel -t -v '//entity/@name' entities.xml | sed -e 'N;s/\n/ /')
ENTITIES := $(shell xmllint --xpath '//entity/@name' $(XML_INPUT) | sed 's| name="\([^"]*\)"|\1|g' | sed -e 'N;s/\n/ /')

#  | sed 's/name="\([^"]*\)"/\1/g'
GENERATED_H_FILES := $(foreach entity,$(ENTITIES),$(entity).h)
GENERATED_C_FILES := $(foreach entity,$(ENTITIES),$(entity).c)
GENERATED_O_FILES := $(GENERATED_C_FILES:.c=.o)

entities:
	@echo "entities: $(ENTITIES)"

OBJECTS = $(MAIN_C:.c=.o) $(GENERATED_O_FILES)

# Default target
all: $(TARGET)

# Rule to link the executable
$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJECTS)

# Rule to compile main.c
$(MAIN_C:.c=.o): $(MAIN_C) $(GENERATED_H_FILES)
	$(CC) $(CFLAGS) -c $(MAIN_C) -o $@

# Pattern rule to compile generated .c files
# Each EntityName.o depends on EntityName.c and EntityName.h
%.o: %.c %.h
	$(CC) $(CFLAGS) -c $< -o $@

# Rule to generate all C files from GSL template
# This makes all generated .h and .c files depend on the XML and GSL script
$(GENERATED_H_FILES) $(GENERATED_C_FILES): $(XML_INPUT) $(GSL_SCRIPT)
	@echo "Running GSL to generate C files for entities: $(ENTITIES)..."
	$(GSL) $(XML_INPUT)
	@echo "GSL generation complete."

# Clean rule
clean:
	@echo "Cleaning up..."
	rm -f $(OBJECTS) $(TARGET) $(GENERATED_H_FILES) $(GENERATED_C_FILES)
	@echo "Cleanup complete."

# Phony targets
.PHONY: all clean