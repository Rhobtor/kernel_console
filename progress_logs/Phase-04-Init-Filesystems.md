# Phase 4: Filesystems & Init Script

## Overview
Creating essential directories, device nodes, and the init script that will run as PID 1 when your OS boots.

---

## 4.1 Create Essential Directories

### What You Did
```bash
cd ~/os_lab/rootfs
sudo mkdir -p dev proc sys tmp mnt
sudo chmod 1777 tmp
```

### Directory Purposes

| Directory | Purpose | Contents |
|-----------|---------|----------|
| **dev/** | Device nodes | /dev/console, /dev/null, /dev/sda, etc. |
| **proc/** | Kernel information | /proc/cpuinfo, /proc/meminfo, etc. |
| **sys/** | Hardware info | /sys/devices, /sys/class, etc. |
| **tmp/** | Temporary files | Runtime temp data |
| **mnt/** | Mount points | External storage, partitions |

### Directory Permissions Explained

| Command | Meaning |
|---------|---------|
| `mkdir -p` | Create if doesn't exist, create parents |
| `chmod 1777` | Permissions + sticky bit |

### Permission Breakdown for tmp

```
1777 = 1000 + 777
       ^^^^    ^^^
     Sticky   rwx for all
     bit
```

- **1** (sticky bit) → Only owner can delete their files
- **7** (owner) → read, write, execute
- **7** (group) → read, write, execute
- **7** (others) → read, write, execute

This prevents users from deleting each other's temp files!

---

## 4.2 Create Device Nodes

### What You Did
```bash
cd ~/os_lab/rootfs
sudo mknod dev/console c 5 1
sudo mknod dev/null    c 1 3
sudo chmod 600 dev/console
sudo chmod 666 dev/null
```

### Device Node Syntax
```bash
mknod <path> <type> <major> <minor>
```

| Parameter | Meaning |
|-----------|---------|
| `<path>` | Where to create the node |
| `c` | Character device (not block device) |
| `<major>` | Driver number (identifies driver) |
| `<minor>` | Which instance of driver |

### Device Information

#### /dev/console
```
mknod dev/console c 5 1
      ^^^^^^^^^^^^   ^ ^ ^
      Path           | | └─ Minor number (1)
                    | └─── Major number (5 = console driver)
                    └───── Character device
```

**Purpose:** Kernel console output and emergency input
**Critical:** Without this, kernel can't communicate!

#### /dev/null
```
mknod dev/null c 1 3
      ^^^^^^^^^  ^ ^ ^
      Path       | | └─ Minor number (3)
                | └─── Major number (1 = memory driver)
                └───── Character device
```

**Purpose:** Data sink (discards everything)
**Use:** Redirect unwanted output to null

### Permissions Explained

| Node | Perms | User | Group | Others | Why |
|------|-------|------|-------|--------|-----|
| console | 600 | r+w | - | - | Only root can use |
| null | 666 | r+w | r+w | r+w | Anyone can write |

### Verification
```bash
ls -l ~/os_lab/rootfs/dev/
```

Output:
```
crw------- 1 root root 5, 1 /dev/console
crw-rw-rw- 1 root root 1, 3 /dev/null
           ^ ^ ^ ^
           | | | └─ Minor number
           | | └─── Major number
           | └───── Type (c = character)
           └─────── Block/Character indicator
```

---

## 4.3 Create Init Script

### What You Did
```bash
cd ~/os_lab/rootfs
sudo nano init
```

### Init Script Content

```bash
#!/bin/sh

echo ""
echo "====================================="
echo "  Init minimal de la consola (v0.3)"
echo "====================================="
echo ""

# Mount /proc and /sys if not already mounted
mount -t proc proc /proc 2>/dev/null || echo "proc ya montado"
mount -t sysfs sys /sys 2>/dev/null || echo "sys ya montado"

echo ""
echo "Montado /proc y /sys (o ya lo estaban)"
echo ""

# Ensure /dev/console and /dev/null exist
[ -e /dev/console ] || mknod /dev/console c 5 1
[ -e /dev/null ]    || mknod /dev/null    c 1 3
chmod 600 /dev/console
chmod 666 /dev/null

echo "Entrando en shell BusyBox..."
exec /bin/sh
```

### Line-by-Line Explanation

```bash
#!/bin/sh
```
Shebang - tells kernel to execute this with `/bin/sh`

```bash
echo "Init minimal de la consola (v0.3)"
```
Display boot message

```bash
mount -t proc proc /proc 2>/dev/null || echo "proc ya montado"
```
- `mount -t proc` → Mount proc filesystem
- `proc /proc` → Mount at /proc directory
- `2>/dev/null` → Suppress error messages
- `|| echo` → If mount fails, print message

```bash
[ -e /dev/console ] || mknod /dev/console c 5 1
```
- `[ -e /dev/console ]` → Test if file exists
- `||` → If NOT exists, then...
- `mknod` → Create the device node

```bash
exec /bin/sh
```
Replace this process with shell (becomes PID 1)

### Make Init Executable
```bash
sudo chmod +x ~/os_lab/rootfs/init
```

### Verify
```bash
ls -l ~/os_lab/rootfs/init
# Output: -rwxr-xr-x init
         ^^^
         Executable
```

---

## Init Script Execution Flow

```
Kernel finishes booting
        ↓
Kernel looks for init (root=/dev/ram0 rdinit=/init)
        ↓
Kernel executes /init script
        ↓
/init becomes PID 1 (init process)
        ↓
/init mounts /proc and /sys
        ↓
/init ensures /dev/console exists
        ↓
/init executes: exec /bin/sh
        ↓
Shell replaces init as PID 1
        ↓
You get shell prompt: / #
```

---

## 4.4 Verify Your Rootfs Structure

```bash
tree ~/os_lab/rootfs/
```

Or with ls:
```bash
find ~/os_lab/rootfs -type d | sort
```

Expected structure:
```
rootfs/
├── bin/
│   ├── busybox
│   ├── sh -> busybox
│   └── ... (300+ applets)
├── sbin/
│   ├── init -> busybox
│   └── ...
├── usr/
│   ├── bin/
│   └── sbin/
├── dev/
│   ├── console (character device, major 5, minor 1)
│   └── null (character device, major 1, minor 3)
├── proc/        (empty, mounted at runtime)
├── sys/         (empty, mounted at runtime)
├── tmp/         (empty, tmp files at runtime)
├── mnt/         (empty, mount point for storage)
└── init         (executable script)
```

---

## Device Major/Minor Numbers Reference

### Common Character Devices

| Major | Device | Purpose |
|-------|--------|---------|
| 1 | /dev/mem | Physical memory |
| 1 | /dev/null | Data sink |
| 1 | /dev/zero | Zero bytes source |
| 4 | /dev/tty | Terminal |
| 5 | /dev/console | Kernel console |
| 6 | /dev/lp | Parallel port |
| 13 | /dev/input | Input devices |

Full reference: `/proc/devices` on a running Linux system

---

## Common Issues & Solutions

### Issue: "Permission denied" when creating device nodes
**Cause:** Not running with sudo

**Solution:**
```bash
# Make sure you use sudo
sudo mknod dev/console c 5 1

# Verify permissions
ls -l ~/os_lab/rootfs/dev/console
```

### Issue: "/dev/console: File exists"
**Cause:** Device node already exists

**Solution:**
```bash
# Remove and recreate
sudo rm ~/os_lab/rootfs/dev/console
sudo mknod dev/console c 5 1
```

### Issue: Init script won't execute
**Cause:** Not executable or wrong permissions

**Solution:**
```bash
# Make it executable
sudo chmod +x ~/os_lab/rootfs/init

# Verify
ls -l ~/os_lab/rootfs/init
# Should show: -rwxr-xr-x
```

### Issue: "proc ya montado" message during boot
**This is NORMAL!** It means:
- /proc was already mounted (not an error)
- OR the mount command succeeded (no error, so message printed)

### Issue: Can't write to /tmp
**Cause:** Wrong permissions on tmp directory

**Solution:**
```bash
sudo chmod 1777 ~/os_lab/rootfs/tmp

# Verify
ls -ld ~/os_lab/rootfs/tmp/
# Should show: drwxrwxrwt
                ^^^^^^^ = 1777
```

---

## What You Now Have

✓ Complete directory structure
✓ Critical device nodes (/dev/console, /dev/null)
✓ Custom init script
✓ Foundation for bootable OS

---

## Files Modified

| File | Purpose |
|------|---------|
| `~/os_lab/rootfs/dev/console` | Kernel console I/O |
| `~/os_lab/rootfs/dev/null` | Data sink |
| `~/os_lab/rootfs/init` | Startup script |
| `~/os_lab/rootfs/proc/` | Virtual filesystem mount point |
| `~/os_lab/rootfs/sys/` | Virtual filesystem mount point |
| `~/os_lab/rootfs/tmp/` | Temporary files (sticky bit) |
| `~/os_lab/rootfs/mnt/` | External storage mount point |

---

## Next Steps

→ **Phase 5: Test with chroot before deployment**

You now have a complete rootfs structure. Before you deploy it as the real boot filesystem:
1. Test it safely using chroot
2. Verify all commands work
3. Check device nodes are accessible
4. Ensure init script executes properly

This prevents boot failures!
