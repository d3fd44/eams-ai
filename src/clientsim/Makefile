SRC      = main.c 

LIBS     ?= -lpthread -lcurl -lcjson
FLAGS    ?= -Wall -Wextra
CC       ?= gcc
TARGET    = clients_simulator

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(FLAGS) $(SRC) -o $(TARGET).ignorethis $(LIBS)

clean:
	rm -f $(TARGET).ignorethis
