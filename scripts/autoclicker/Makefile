CC = gcc
CFLAGS = -Wall -Wextra -O2
LDFLAGS = -lX11 -lXtst

TARGET = autoclicker
SRC = autoclicker.c

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)

clean:
	rm -f $(TARGET)

.PHONY: all clean
