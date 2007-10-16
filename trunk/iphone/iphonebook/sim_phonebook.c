#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <termios.h>
#include <errno.h>
#include <time.h>
#include "sim_phonebook.h"

#define LOG stdout
#define SPEED 115200

#pragma pack(1)

#define ever ;;
#define BUFSIZE (65536+100)
char readbuf[BUFSIZE];

static struct termios term;
static struct termios gOriginalTTYAttrs;

#ifndef DEBUG_ENABLED
#define DEBUGLOG(x) 
#else
#define DEBUGLOG(x) x
#endif

#define UINT(x) *((unsigned int *) (x))

void SendCmd(int fd, void *buf, size_t size)
{
	if(write(fd, buf, size) == -1) {
		exit(1);
	}
}

#define SendBytes(fd, args...) {			\
		unsigned char sendbuf[] = {args};	\
		SendCmd(fd, sendbuf, sizeof(sendbuf));	\
	}

void SendStrCmd(int fd, char *buf)
{
	SendCmd(fd, buf, strlen(buf));
}

int ReadAtResponse(int fd, char *buf, int *buf_size)
{
	int len = 0;
	int read_size = 0;

	while(read_size < (*buf_size)) {
		len = read(fd, buf + read_size, (*buf_size) - read_size);
		read_size += len;

		if (NULL != strnstr(buf, "OK", read_size)) {
			*buf_size = read_size;
			return 0;
		} else if (NULL != strnstr(buf, "ERROR", read_size)) {
			*buf_size = read_size;
			return 1;
		}
	}

	return -1;
}

int GetAtReturn(int fd)
{
	int read_size = 0;
	while(read_size = read(fd, readbuf, sizeof(readbuf))) {
		if (NULL != strnstr(readbuf, "OK", read_size)) {
			return 0;
		} else if (NULL != strnstr(readbuf, "ERROR", read_size)) {
			return 1;
		}
	}

	return -1;
}

int InitConn()
{
	unsigned int handshake = TIOCM_DTR | TIOCM_RTS | TIOCM_CTS | TIOCM_DSR; 
	int fd = open("/dev/tty.debug", O_RDWR | O_NOCTTY | O_NOCTTY); 
   
	ioctl(fd, TIOCEXCL); 
	fcntl(fd, F_SETFL, 0); 
  
	tcgetattr(fd, &term); 

	gOriginalTTYAttrs = term;

	term.c_cflag = CS8 | CLOCAL | CREAD; 
	term.c_iflag = 0; 
	term.c_oflag = 0; 
	term.c_lflag = 0; 
	term.c_cc[VTIME] = 0; 
	term.c_cc[VMIN] = 0;

	cfsetspeed(&term, B115200); 
	cfmakeraw(&term); 
	tcsetattr(fd, TCSANOW, &term); 
  
	ioctl(fd, TIOCSDTR); 
	ioctl(fd, TIOCCDTR); 
	ioctl(fd, TIOCMSET, &handshake); 
 
	return fd;
}

void CloseConn(int fd)
{
	SendStrCmd(fd,"ate1\r");
	GetAtReturn(fd);
	tcdrain(fd);
	tcsetattr(fd, TCSANOW, &gOriginalTTYAttrs);
	close(fd);
}

void SendAT(int fd)
{
	SendStrCmd(fd, "AT\r");
}

void AT(int fd)
{
	SendAT(fd);
  
	for (ever) {
		if(0 == GetAtReturn(fd)) {
				break;
		}
		SendAT(fd);
	}
}

typedef unsigned char	UCHAR;
typedef unsigned char	*LPSTR;
typedef unsigned char	*LPBYTE;

sim_phonebook * ReadAllPB()
{
	char buf[1024];
	int buf_len, process_len, i;
	ssize_t read_size;
	char cmd[64];
	int begin, end;
	int len;

	int fd = InitConn(); 
	AT(fd);  
	SendStrCmd(fd, "ATE0\r");
	GetAtReturn(fd);
	SendStrCmd(fd,"AT+CSCS=\"UCS2\"\r");
	GetAtReturn(fd);
	SendStrCmd(fd,"at+cpbr=?\r");
	buf_len = sizeof(buf);
	ReadAtResponse(fd, buf, &buf_len);
	sscanf(buf,"\r\n+CPBR: (%d-%d),%*d,%*d", &begin, &end);

	sim_phonebook *result = malloc(sizeof(*result));
	result->count = 0;
	result->numbers = malloc(sizeof(char *) * (end - begin + 1));
	result->names = malloc(sizeof(char *) * (end - begin + 1));

	bzero(result->numbers, sizeof(char *) * (end - begin + 1));
	bzero(result->names, sizeof(char *) * (end - begin + 1));

	for(i = begin; i < end; i++) {
		sprintf(cmd,"at+cpbr=%d\r", i);
		SendStrCmd(fd,cmd);

		buf_len = sizeof(buf);
		ReadAtResponse(fd, buf, &buf_len);
		buf[buf_len] = '\0';
		ParsePhoneBookLine(buf, buf_len, result);
	}

	CloseConn(fd);

	return result;
}

int ParsePhoneBookLine(char *buf, int buf_len, sim_phonebook *spb)
{
	char *buf_end = buf + buf_len;
	char *begin, *end;
	char *phone, *name;

	int ret = 0;

	begin = memchr(buf, '"', buf_len);
	if (NULL == begin) {
		return -1;
	}

	end = memchr(begin + 1, '"', buf_end - begin - 1);
	if (NULL == end) {
		return -1;
	}

	*end = '\0';
	spb->numbers[spb->count] = strdup(begin + 1);

	begin = memchr(end + 1, '"', buf_end - end - 1);
	if (NULL == begin) {
		return -1;
	}
	end = memchr(begin + 1, '"', buf_end - begin - 1);
	if (NULL == end) {
		return -1;
	}
		
	*end = '\0';
	spb->names[spb->count] = strdup(begin + 1);

	spb->count++;

	return ret;
}
