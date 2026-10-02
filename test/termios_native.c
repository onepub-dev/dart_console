#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>

#if defined(__APPLE__)
#include <util.h>
#else
#include <pty.h>
#endif

size_t helper_termios_size(void) { return sizeof(struct termios); }
size_t helper_iflag_offset(void) { return offsetof(struct termios, c_iflag); }
size_t helper_oflag_offset(void) { return offsetof(struct termios, c_oflag); }
size_t helper_cflag_offset(void) { return offsetof(struct termios, c_cflag); }
size_t helper_lflag_offset(void) { return offsetof(struct termios, c_lflag); }
size_t helper_cc_offset(void) { return offsetof(struct termios, c_cc); }
size_t helper_ispeed_offset(void) { return offsetof(struct termios, c_ispeed); }
size_t helper_ospeed_offset(void) { return offsetof(struct termios, c_ospeed); }

static void fill(struct termios *value) {
  value->c_iflag = 0x11223344;
  value->c_oflag = 0x22334455;
  value->c_cflag = 0x33445566;
  value->c_lflag = 0x44556677;
#if !defined(__APPLE__)
  value->c_line = 0x5a;
#endif
  for (size_t i = 0; i < NCCS; ++i) value->c_cc[i] = (cc_t)((i * 11 + 3) & 0xff);
  value->c_ispeed = 0x55667788;
  value->c_ospeed = 0x66778899;
}

void helper_fill_sentinels(void *value) { fill((struct termios *)value); }

int helper_validate_sentinels(const void *raw) {
  const struct termios *value = (const struct termios *)raw;
  struct termios expected;
  memset(&expected, 0, sizeof(expected));
  fill(&expected);
  if (value->c_iflag != expected.c_iflag || value->c_oflag != expected.c_oflag ||
      value->c_cflag != expected.c_cflag || value->c_lflag != expected.c_lflag ||
      value->c_ispeed != expected.c_ispeed || value->c_ospeed != expected.c_ospeed)
    return 0;
#if !defined(__APPLE__)
  if (value->c_line != expected.c_line) return 0;
#endif
  return memcmp(value->c_cc, expected.c_cc, NCCS) == 0;
}

int helper_open_pty(int *master, int *slave) { return openpty(master, slave, NULL, NULL, NULL); }
int helper_close_fd(int fd) { return close(fd); }
int helper_dup_fd(int fd) { return dup(fd); }
int helper_dup2_fd(int from, int to) { return dup2(from, to); }

int helper_configure_terminal(int fd) {
  struct termios value;
  if (tcgetattr(fd, &value) != 0) return 0;
  value.c_iflag |= IGNBRK | BRKINT | PARMRK | INPCK | ISTRIP | INLCR | IGNCR | ICRNL | IXON;
  value.c_oflag |= OPOST;
  value.c_cflag |= CS8 | PARENB;
  value.c_lflag |= ECHO | ECHONL | ICANON | ISIG | IEXTEN;
  value.c_cc[VERASE] = 0x08;
  value.c_cc[VINTR] = 0x03;
  if (cfsetispeed(&value, B9600) != 0 || cfsetospeed(&value, B19200) != 0) return 0;
  return tcsetattr(fd, TCSANOW, &value) == 0;
}

int helper_snapshot(int fd, void *raw) {
  return tcgetattr(fd, (struct termios *)raw) == 0;
}

int helper_raw_matches(int fd, const void *raw_original) {
  struct termios current;
  const struct termios *original = (const struct termios *)raw_original;
  if (tcgetattr(fd, &current) != 0) return 0;
  if (current.c_iflag & (BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON)) return 0;
#if defined(__APPLE__)
  if ((current.c_iflag & IGNBRK) == 0 || (current.c_iflag & INPCK)) return 0;
#else
  if ((current.c_iflag & IGNBRK) || (current.c_iflag & INPCK) == 0) return 0;
#endif
  if (current.c_oflag & OPOST) return 0;
  if ((current.c_cflag & CSIZE) != CS8 || (current.c_cflag & PARENB)) return 0;
  if (current.c_lflag & (ECHO | ECHONL | ICANON | ISIG | IEXTEN)) return 0;
  if (current.c_cc[VMIN] != 0 || current.c_cc[VTIME] != 1) return 0;
  return cfgetispeed(&current) == cfgetispeed(original) &&
         cfgetospeed(&current) == cfgetospeed(original) &&
         current.c_ispeed == original->c_ispeed && current.c_ospeed == original->c_ospeed;
}

int helper_matches_snapshot(int fd, const void *raw_original) {
  struct termios current;
  const struct termios *original = (const struct termios *)raw_original;
  if (tcgetattr(fd, &current) != 0) return 0;
  if (current.c_iflag != original->c_iflag || current.c_oflag != original->c_oflag ||
      current.c_cflag != original->c_cflag || current.c_lflag != original->c_lflag ||
      current.c_ispeed != original->c_ispeed || current.c_ospeed != original->c_ospeed)
    return 0;
#if !defined(__APPLE__)
  if (current.c_line != original->c_line) return 0;
#endif
  return memcmp(current.c_cc, original->c_cc, NCCS) == 0;
}
