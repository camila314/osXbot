#include "rd_route.h"
#include <mach/mach_vm.h> // mach_vm_*
kern_return_t writeProcessMemory(mach_vm_address_t address, size_t size, char* buffer);
kern_return_t readProcessMemory(mach_vm_address_t address, size_t size, char* buffer);

long baseAddress();