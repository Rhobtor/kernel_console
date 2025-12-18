# Kernel Console - Custom OS for Gaming Handhelds

A complete custom Linux operating system stack designed for game console handhelds with PDA capabilities.

## Project Vision

Building a **multi-version game console and mobile computing device** with custom OS, custom hardware, and full system control.

## Version Roadmap

### **v0.x** (Current) - OS Foundation
- Custom Linux kernel (6.12.60-console-v1+)
- BusyBox minimal OS (2.5 MB initramfs)
- Base architecture and boot system
- **Status:** Core OS complete, documentation done

### **v1.0** - First Hardware Release
- **Hardware:** Raspberry Pi 4 + Custom PCB
- **Features:** Game controls, battery, charging circuit
- **Software:** Full OS with game launcher
- **Target:** Fully functional gaming handheld

### **v2.0** - Enhanced Version
- **Hardware:** Raspberry Pi 5M + Advanced PCB
- **Features:** Better performance, improved controls, optimized power management
- **Software:** Enhanced launcher, more emulator support

### **v2.5** - Chip Variant
- **Hardware:** Alternative processor variant + Specialized PCB
- **Features:** Performance tuning for specific chip
- **Software:** Optimized drivers and features

### **v3.0** - Next Generation
- **Hardware:** Integrated Graphics + Custom PCB
- **Features:** Native graphics acceleration
- **Software:** Leverages GPU capabilities

## Dual Purpose: Gaming Console + PDA

Each version functions as both:
- **Gaming Console:** Emulators, games, full game launcher
- **Mobile Computer:** File management, networking, applications

## Current Development Phase: v0.x OS Design

### What's Done ✅
- Custom compiled kernel (ARM aarch64)
- Minimal BusyBox rootfs (300+ tools)
- Complete initramfs boot system
- SD card access from custom OS
- 8-phase comprehensive documentation

### What's Next 📋
1. Game controller input handling
2. Graphics rendering (framebuffer/SDL2)
3. Game launcher UI
4. Emulator integration
5. Battery management framework
6. PDA applications

### Planned Learning & Development 🎓
- **PCB Design:** Custom control layouts, power management, charging circuits
- **Embedded Programming:** Driver development, hardware integration
- **Software Architecture:** Modular design for multi-version deployment
- **Game Development:** Emulator optimization, game integration

## Technical Stack

- **Kernel:** Linux 6.12.60 (custom compiled)
- **Userspace:** BusyBox
- **Language:** Shell scripts, C (for drivers/apps)
- **Build System:** Make, Kconfig

## Repository Structure

```
kernel_console/
├── progress_logs/          # Development phases (Phase 0-8)
├── readme.md              # This file
├── (future) kernel/       # Kernel sources
├── (future) rootfs/       # OS filesystem
├── (future) hardware/     # PCB designs, schematics
├── (future) drivers/      # Custom drivers
└── (future) apps/         # Applications & launcher
```

## Key Features of Custom OS

✓ **Minimal Footprint:** 2.5 MB compressed, runs entirely in RAM
✓ **Independence:** Doesn't rely on traditional Linux distro
✓ **Hardware Control:** Direct access to all hardware via /proc and /sys
✓ **Performance:** Optimized for gaming and PDA use
✓ **Scalability:** Same base OS across all hardware versions
✓ **Flexibility:** Easy to add emulators, games, and applications

## Long-term Goals

- Support 5+ hardware versions
- Unified OS codebase across versions
- Professional gaming handheld device
- Feature parity between gaming and PDA modes
- Community support and customization

## Contributing

This is a personal/team project. Contributions and ideas welcome!

## License

TBD - Define licensing strategy as project matures

## Contact

For questions about the project, refer to the comprehensive documentation in `progress_logs/`

---

**Project Status:** Active Development  
**Current Focus:** OS Foundation (v0.x)  
**Hardware Target:** Raspberry Pi 4  
**Next Milestone:** Game controller integration
