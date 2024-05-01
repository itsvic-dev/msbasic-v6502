#include "v6502/cpu.h"
#include "v6502/memory.h"
#include "v6502/print.h"
#include <cstdint>
#include <cstring>
#include <exception>
#include <fcntl.h>
#include <iostream>
#include <ostream>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/select.h>
#include <termios.h>
#include <unistd.h>
#include <vector>

#define ROM_SIZE (0x10000 - 0xC000)

std::vector<uint8_t> inputTest = {
    '\r', '\r', 'P', 'R', 'I', 'N', 'T', '"', '\r',
};
bool running = true;

/**
 * Memory map:
 * - 0x0000-0x01FF - RAM (zero page, stack)
 * - 0x0200 - putchar (WO)
 * - 0x0201 - getchar (RO)
 * - 0x0202 - is kbd ready? (RO)
 * - 0x0203-0x02FF - reserved
 * - 0x0300-0xBFFF - RAM
 * - 0xC000-0xFFFF - ROM
 */
class BasicMemoryBus : public MemoryBus {
public:
  BasicMemoryBus(uint8_t *rom) : rom(rom) {
    ram1 = new uint8_t[0x01FF - 0x0000 + 1];
    ram2 = new uint8_t[0xBFFF - 0x0300 + 1];
  }
  ~BasicMemoryBus() {
    delete[] ram1;
    delete[] ram2;
  }

  uint8_t read(uint16_t addr) override {
    if (addr <= 0x01FF) {
      return ram1[addr];
    }

    if (addr == 0x0201) {
      char retVal = inputTest[0];
      inputTest.erase(inputTest.begin());
      return retVal;
    }

    if (addr == 0x0202) {
      if (!inputTest.size())
        running = false;
      return !!inputTest.size();
    }

    if (addr >= 0x0300 && addr <= 0xBFFF) {
      return ram2[addr - 0x0300];
    }

    if (addr >= 0xC000) {
      return rom[addr - 0xC000];
    }

    return 0xFF;
  }

  void write(uint16_t addr, uint8_t data) override {
    if (addr <= 0x01FF) {
      ram1[addr] = data;
    }

    if (addr >= 0x0300 && addr <= 0xBFFF) {
      ram2[addr - 0x0300] = data;
    }

    if (addr == 0x0200) {
      std::cout << (char)data << std::flush;
    }
  }

private:
  uint8_t *ram1;
  uint8_t *ram2;
  uint8_t *rom;
};

int main(int argc, char **argv) {
  if (argc < 2) {
    print("i NEED rom file\n");
    return -1;
  }
  // disable input echoing
  termios oldt;
  tcgetattr(STDIN_FILENO, &oldt);
  termios newt = oldt;
  newt.c_lflag &= ~ECHO;
  tcsetattr(STDIN_FILENO, TCSANOW, &newt);

  // mmap ROM
  int fd = open(argv[1], O_RDONLY);
  if (fd == -1) {
    print("failed to open ROM\n");
    return -1;
  }

  uint8_t *rom = (uint8_t *)mmap(NULL, ROM_SIZE, PROT_READ, MAP_PRIVATE, fd, 0);
  if (rom == MAP_FAILED) {
    print("failed to mmap ROM\n");
    return -1;
  }

  BasicMemoryBus bus(rom);
  CPU cpu(&bus);

  print("resetting CPU\n");
  cpu.reset();

  try {
    while (running) {
      cpu.executeStep();
    }
  } catch (std::exception &exc) {
    print("\n---\nsmth failed, whoops!\n");
    return -1;
  }

  munmap(rom, ROM_SIZE);
  close(fd);
  return 0;
}
