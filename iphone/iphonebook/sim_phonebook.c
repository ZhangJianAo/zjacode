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

static char lastError[1024];

char * sim_get_lasterror()
{
	return lastError;
}

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

// Given the path to a serial device, open the device and configure it.
// Return the file descriptor associated with the device.
static int OpenSerialPort(const char *bsdPath)
{
	int fileDescriptor = -1;
	int handshake;
	struct termios  options;
    
	// Open the serial port read/write, with no controlling terminal, and don't wait for a connection.
	// The O_NONBLOCK flag also causes subsequent I/O on the device to be non-blocking.
	// See open(2) ("man 2 open") for details.
	fileDescriptor = open(bsdPath, O_RDWR | O_NOCTTY | O_NONBLOCK);
	if (fileDescriptor == -1)
	{
		snprintf(lastError, sizeof(lastError), "Error opening serial port %s - %s(%d).\n",
		       bsdPath, strerror(errno), errno);
		goto error;
	}

	// Note that open() follows POSIX semantics: multiple open() calls to the same file will succeed
	// unless the TIOCEXCL ioctl is issued. This will prevent additional opens except by root-owned
	// processes.
	// See tty(4) ("man 4 tty") and ioctl(2) ("man 2 ioctl") for details.
	if (ioctl(fileDescriptor, TIOCEXCL) == -1)
	{
		snprintf(lastError, sizeof(lastError), "Error setting TIOCEXCL on %s - %s(%d).\n",
		       bsdPath, strerror(errno), errno);
		goto error;
	}
    
	// Now that the device is open, clear the O_NONBLOCK flag so subsequent I/O will block.
	// See fcntl(2) ("man 2 fcntl") for details.
	if (fcntl(fileDescriptor, F_SETFL, 0) == -1)
	{
		snprintf(lastError, sizeof(lastError), "Error clearing O_NONBLOCK %s - %s(%d).\n",
		       bsdPath, strerror(errno), errno);
		goto error;
	}
    
	// Get the current options and save them so we can restore the default settings later.
	if (tcgetattr(fileDescriptor, &gOriginalTTYAttrs) == -1)
	{
		snprintf(lastError, sizeof(lastError), "Error getting tty attributes %s - %s(%d).\n",
		       bsdPath, strerror(errno), errno);
		goto error;
	}

	// The serial port attributes such as timeouts and baud rate are set by modifying the termios
	// structure and then calling tcsetattr() to cause the changes to take effect. Note that the
	// changes will not become effective without the tcsetattr() call.
	// See tcsetattr(4) ("man 4 tcsetattr") for details.
	options = gOriginalTTYAttrs;
    
	// Print the current input and output baud rates.
	// See tcsetattr(4) ("man 4 tcsetattr") for details.
	/*
	printf("Current input baud rate is %d\n", (int) cfgetispeed(&options));
	printf("Current output baud rate is %d\n", (int) cfgetospeed(&options));
	*/
    
	// Set raw input (non-canonical) mode, with reads blocking until either a single character 
	// has been received or a one second timeout expires.
	// See tcsetattr(4) ("man 4 tcsetattr") and termios(4) ("man 4 termios") for details.
	cfmakeraw(&options);
	options.c_cc[VMIN] = 1;
	options.c_cc[VTIME] = 10;
        
	// The baud rate, word length, and handshake options can be set as follows:
	cfsetspeed(&options, B115200);    // Set 19200 baud    
	/*
	options.c_cflag |= (CS7      |   // Use 7 bit words
			    PARENB     |   // Parity enable (even parity if PARODD not also set)
			    CCTS_OFLOW |   // CTS flow control of output
			    CRTS_IFLOW);  // RTS flow control of input
	*/ 
	//options.c_cflag = CS7 | CLOCAL | CREAD; 
	// Print the new input and output baud rates. Note that the IOSSIOSPEED ioctl interacts with the serial driver 
	// directly bypassing the termios struct. This means that the following two calls will not be able to read
	// the current baud rate if the IOSSIOSPEED ioctl was used but will instead return the speed set by the last call
	// to cfsetspeed.
	/*
	printf("Input baud rate changed to %d\n", (int) cfgetispeed(&options));
	printf("Output baud rate changed to %d\n", (int) cfgetospeed(&options));
	*/
    
	// Cause the new options to take effect immediately.
	if (tcsetattr(fileDescriptor, TCSANOW, &options) == -1)
	{
		snprintf(lastError, sizeof(lastError), "Error setting tty attributes %s - %s(%d).\n",
		       bsdPath, strerror(errno), errno);
		goto error;
	}

	// To set the modem handshake lines, use the following ioctls.
	// See tty(4) ("man 4 tty") and ioctl(2) ("man 2 ioctl") for details.
	if (ioctl(fileDescriptor, TIOCSDTR) == -1) // Assert Data Terminal Ready (DTR)
	{
		snprintf(lastError, sizeof(lastError), "Error asserting DTR %s - %s(%d).\n",
		       bsdPath, strerror(errno), errno);
	}
    
	if (ioctl(fileDescriptor, TIOCCDTR) == -1) // Clear Data Terminal Ready (DTR)
	{
		snprintf(lastError, sizeof(lastError), "Error clearing DTR %s - %s(%d).\n",
		       bsdPath, strerror(errno), errno);
	}
    
	handshake = TIOCM_DTR | TIOCM_RTS | TIOCM_CTS | TIOCM_DSR;
	if (ioctl(fileDescriptor, TIOCMSET, &handshake) == -1)
		// Set the modem lines depending on the bits set in handshake
	{
		snprintf(lastError, sizeof(lastError), "Error setting handshake lines %s - %s(%d).\n",
		       bsdPath, strerror(errno), errno);
	}
    
	// To read the state of the modem lines, use the following ioctl.
	// See tty(4) ("man 4 tty") and ioctl(2) ("man 2 ioctl") for details.
    
	if (ioctl(fileDescriptor, TIOCMGET, &handshake) == -1)
		// Store the state of the modem lines in handshake
	{
		snprintf(lastError, sizeof(lastError), "Error getting handshake lines %s - %s(%d).\n",
		       bsdPath, strerror(errno), errno);
	}
    
	//printf("Handshake lines currently set to %d\n", handshake);
  
	// Success
	return fileDescriptor;
    
	// Failure path
error:
	if (fileDescriptor != -1)
	{
		close(fileDescriptor);
	}
    
	return -1;
}
// Given the file descriptor for a serial device, close that device.
void CloseSerialPort(int fileDescriptor)
{
	// Block until all written output has been sent from the device.
	// Note that this call is simply passed on to the serial device driver. 
	// See tcsendbreak(3) ("man 3 tcsendbreak") for details.
	if (tcdrain(fileDescriptor) == -1)
	{
		snprintf(lastError, sizeof(lastError), "Error waiting for drain - %s(%d).\n",
		       strerror(errno), errno);
	}
    
	// Traditionally it is good practice to reset a serial port back to
	// the state in which you found it. This is why the original termios struct
	// was saved.
	if (tcsetattr(fileDescriptor, TCSANOW, &gOriginalTTYAttrs) == -1)
	{
		snprintf(lastError, sizeof(lastError), "Error resetting tty attributes - %s(%d).\n",
		       strerror(errno), errno);
	}

	close(fileDescriptor);
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

sim_phonebook * sim_read_pb()
{
	char buf[1024];
	int buf_len, process_len, i;
	ssize_t read_size;
	char cmd[64];
	int begin, end;
	int len;

	//int fd = InitConn(); 
	int fd = OpenSerialPort("/dev/tty.debug");
	if (fd < 0) {
		return NULL;
	}

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

	//CloseConn(fd);
	CloseSerialPort(fd);

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
