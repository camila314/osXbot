#include "MKit.h"

kern_return_t readProcessMemory(mach_vm_address_t address, size_t length, char* bytes) {
    uint32_t placehoolder;
    return mach_vm_read(mach_task_self(), address, length,(vm_offset_t*)bytes,&placehoolder);
}


kern_return_t _protectProcessMemory(mach_vm_address_t address, size_t length, vm_prot_t protection) {
    return mach_vm_protect(mach_task_self(), address, length, FALSE, protection);
}

kern_return_t writeProcessMemory(mach_vm_address_t address, size_t length, char* bytes) {
    kern_return_t ret = _protectProcessMemory(address, length, 7);
    if(ret != KERN_SUCCESS)
        return ret;
    
    return mach_vm_write(mach_task_self(), address, (vm_offset_t)bytes, (mach_msg_type_number_t)length);
}

long baseAddress() {
    return _dyld_get_image_vmaddr_slide(0)+0x100000000;
}