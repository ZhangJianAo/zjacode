#ifndef sim_phonebook_h
#define sim_phonebook_h

typedef struct sim_phonebook {
	int count;
	char **numbers;
	char **names;
} sim_phonebook;

sim_phonebook * sim_read_pb();
char * sim_get_lasterror();

#endif
