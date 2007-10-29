CC=arm-apple-darwin-gcc
CPPFLAGS=-g
LD=$(CC)
LDFLAGS=-lobjc -framework CoreFoundation -framework Foundation -framework UIKit -framework LayerKit

all: iPhoneBook
	cp $^ iPhoneBook.app/

iPhoneBook: iPhoneBook.o iPhoneBookApplication.o sim_phonebook.o
	$(LD) $(LDFLAGS) -o $@ $^

%.o: %.m
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

clean:
	rm -f *.o iPhoneBook iPhoneBook.app/iPhoneBook
