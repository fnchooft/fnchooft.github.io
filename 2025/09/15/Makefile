# Makefile for STB Data Structures example
TARGET = dhcp_config

STB_URL = https://raw.githubusercontent.com/nothings/stb/master/stb_ds.h
STB_HEADER = stb_ds.h

STB_SURL = https://raw.githubusercontent.com/nothings/stb/master/stb_sprintf.h
STB_SHEADER = stb_sprintf.h

.PHONY: all clean deps

all: deps $(TARGET)

# Download stb_ds.h if missing
deps:
	@if [ ! -f "$(STB_HEADER)" ]; then \
		echo "Downloading $(STB_HEADER)..."; \
		curl -s -o $(STB_HEADER) $(STB_URL) || wget -q -O $(STB_HEADER) $(STB_URL); \
	fi
	@if [ ! -f "$(STB_SHEADER)" ]; then \
		echo "Downloading $(STB_SHEADER)..."; \
		curl -s -o $(STB_SHEADER) $(STB_SURL) || wget -q -O $(STB_SHEADER) $(STB_SURL); \
	fi

# Compile the program
$(TARGET): $(TARGET).c
	$(CC) -O2 -Wall -Wextra -o $@ $<

clean:
	$(RM) $(TARGET)

distclean: clean
	$(RM) $(STB_HEADER)
	
