#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <termios.h>
#include <errno.h>
#include <time.h>

#define LOG stdout
#define SPEED 115200

#pragma pack(1)

#define ever ;;
#define BUFSIZE (65536+100)
unsigned char readbuf[BUFSIZE];

static struct termios term;
static struct termios gOriginalTTYAttrs;
int InitConn(int speed);

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

int ReadResp(int fd)
{
	int len = 0;
	struct timeval timeout;
	int nfds = fd + 1;
	fd_set readfds;
	int select_ret;

	FD_ZERO(&readfds);
	FD_SET(fd, &readfds);

	// Wait a second
	timeout.tv_sec = 1;
	timeout.tv_usec = 500000;

	while (select_ret = select(nfds, &readfds, NULL, NULL, &timeout) > 0)
	{
		len += read(fd, readbuf + len, BUFSIZE - len);
		FD_ZERO(&readfds);
		FD_SET(fd, &readfds);
		timeout.tv_sec = 0;
		timeout.tv_usec = 500000;
	}

	return len;
}

int InitConn(int speed)
{
	struct termios buf;
	int rate;
  
	int fd = open ("/dev/tty.debug", O_RDWR | O_NOCTTY | O_NONBLOCK);
	if (fd < 0) {
		return fd;
	}
	/* open() calls from other applications shall fail now */
	ioctl (fd, TIOCEXCL, (char *) 0);

	if (tcgetattr (fd, &buf)) {
		return (0);
	}
	gOriginalTTYAttrs = buf;
	fcntl(fd, F_SETFL, 0);

	//
	// Reset to the serial port to raw mode.
	//
	buf.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP |
			 INLCR | IGNCR | ICRNL | IXON);
	buf.c_oflag &= ~OPOST;
	buf.c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
	buf.c_cflag &= ~(CSIZE | PARENB);
	buf.c_cflag |= CS8;
	buf.c_cc[VMIN] = 1;
	buf.c_cc[VTIME] = 10;
	//
	// Get the baud rate.
	//
	switch (speed) {
	case 9600:
	{
		rate = B9600;
		break;
	}

	case 19200:
	{
		rate = B19200;
		break;
	}

	case 38400:
	{
		rate = B38400;
		break;
	}

	case 57600:
	{
		rate = B57600;
		break;
	}

	case 115200:
	{
		rate = B115200;
		break;
	}
	}

	//
	// Set the input and output baud rate of the serial port.
	//
	cfsetispeed (&buf, rate);
	cfsetospeed (&buf, rate);
	//
	// Set data bits to 8.
	//
	buf.c_cflag &= ~CSIZE;
	buf.c_cflag |= CS8;

	//
	// Set stop bits to one.
	//
	buf.c_cflag &= ~CSTOPB;

	//
	// Disable parity.
	//
	buf.c_cflag &= ~(PARENB | PARODD);

	//
	// Set the new settings for the serial port.
	//
	if (tcsetattr (fd, TCSADRAIN, &buf)) {
		return -1;
	}
	//
	// Wait until the output buffer is empty.
	//
	tcdrain (fd);
	ioctl(fd, TIOCSDTR);
	ioctl(fd, TIOCCDTR);
	unsigned int handshake = TIOCM_DTR | TIOCM_RTS | TIOCM_CTS | TIOCM_DSR;
	ioctl(fd, TIOCMSET, &handshake);
  
	return fd;
}

void CloseConn(int fd)
{
	SendStrCmd(fd,"ate1\r");
	ReadResp(fd);
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
		if(ReadResp(fd) != 0) {
			if(strstr(readbuf,"OK"))
			{
				break;
			}
		}
		SendAT(fd);
	}
}

typedef unsigned char	UCHAR;
typedef unsigned char	*LPSTR;
typedef unsigned char	*LPBYTE;

int ReadAllPB()
{
	unsigned char buf[1024];
	ssize_t read_size;
	unsigned char cmd[64];
	int begin, end;
	int len;

	int fd = InitConn(115200); 
	AT(fd);  
	SendStrCmd(fd, "ATE0\r");
	ReadResp(fd);
	SendStrCmd(fd,"AT+CSCS=\"UCS2\"\r");
	ReadResp(fd); 
	SendStrCmd(fd,"at+cpbr=?\r");
	ReadResp(fd);
	sscanf(readbuf,"\r\n+CPBR: (%d-%d),%*d,%*d", &begin, &end);
	sprintf(cmd,"at+cpbr=1,%d\r",end);
	SendStrCmd(fd,cmd);
	while((read_size = read(fd, buf, 1024)) > 0) {
	}
	CloseConn(fd);

	return NULL;
}
