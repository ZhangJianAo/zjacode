#ifndef sim_phonebook_h
#define sim_phonebook_h

typedef struct sim_phonebook {
	int count;
	char **numbers;
	char **names;
} sim_phonebook;

sim_phonebook * ReadAllPB();

#endif
