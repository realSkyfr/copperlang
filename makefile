LUAJIT_INC = /opt/homebrew/include/luajit-2.1
LUAJIT_LIB = /opt/homebrew/lib

CC = gcc
CFLAGS = -I$(LUAJIT_INC)
LDFLAGS = -L$(LUAJIT_LIB) -lluajit-5.1 -lm -ldl

TARGET = build/cli
SRC = cli.c

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $(SRC) -o $(TARGET) $(LDFLAGS)
	dot_clean ./

clean:
	rm -f $(TARGET)/*
	dot_clean ./
