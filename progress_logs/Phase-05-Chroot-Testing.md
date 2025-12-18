# Phase 5: Testing with Chroot

## Overview
Safely testing your custom rootfs using chroot WITHOUT affecting your actual boot process.

---

## 5.1 Mount Host Filesystems

### What You Did
```bash
cd ~/os_lab/rootfs

sudo mount --bind /dev dev
sudo mount -t proc proc proc
sudo mount -t sysfs sys sys
```

### Why This Step?

Your rootfs is empty for /dev, /proc, /sys. The kernel needs these to function. By mounting the HOST's versions, your chroot environment can access:
- Device nodes (/dev)
- Kernel information (/proc)
- Hardware information (/sys)

### Mount Commands Explained

| Command | What It Does |
|---------|--------------|
| `mount --bind /dev dev` | Bind-mount host's /dev to your rootfs's dev/ |
| `mount -t proc proc proc` | Mount proc filesystem at proc/ |
| `mount -t sysfs sys sys` | Mount sysfs at sys/ |

### Visualization

```
Before:
  rootfs/
    dev/    (empty)
    proc/   (empty)
    sys/    (empty)

Host system:
  /dev/    (device nodes)
  /proc/   (kernel info)
  /sys/    (hardware info)

After mount --bind:
  rootfs/
    dev/  → points to → /dev/
    proc/ → points to → /proc/
    sys/  → points to → /sys/
```

---

## 5.2 Enter Chroot Environment

### What You Did
```bash
sudo chroot . /init
```

### Chroot Syntax
```bash
chroot <new-root> <command>
        ^^^^^^^^^   ^^^^^^^^^
        New root    Command to execute
        directory   in new root
```

### What Happens

```
Before chroot:
  Filesystem view: /
    /home/rhobtor/
    /usr/
    /etc/
    /boot/
    etc. (entire system)

After chroot:
  Filesystem view: /
    /bin/          (from rootfs/bin/)
    /sbin/         (from rootfs/sbin/)
    /dev/          (from rootfs/dev/ bound to /dev)
    /proc/         (from rootfs/proc/)
    /sys/          (from rootfs/sys/)
    /tmp/          (from rootfs/tmp/)
    /mnt/          (from rootfs/mnt/)
    
  Cannot see: /home/, /usr/ (of host), etc.
```

### Chroot Limitations

⚠️ **Important:** Chroot is NOT a full virtual machine
- Still uses your kernel
- Still has your hardware
- `uname -a` shows your real kernel (kernel8-console-v1)
- Can break out with `mount` commands
- Better security with containers (Docker, etc.)

---

## 5.3 Expected Boot Output

### What You See

```bash
$ sudo chroot . /init
=====================================
  Init minimal de la consola (v0.3)
=====================================

Montado /proc y /sys (o ya lo estaban)

Entrando en shell BusyBox...
/ #
```

### What This Means

✓ Init script executed successfully
✓ /proc mounted (or was already mounted)
✓ /sys mounted (or was already mounted)
✓ BusyBox shell is ready
✓ You're at root (#) with full privileges

---

## 5.4 Test Commands in Chroot

### Navigation
```bash
/ # pwd
/

/ # ls
bin   dev   lib   mnt   proc  sbin  sys   tmp   usr   linuxrc  init

/ # cd /bin
/bin # ls
busybox  sh       ls       cat      grep     ... (300+ applets)
```

### Filesystem Info
```bash
/ # df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/root       58G   10G   48G  17% /
devtmpfs        1.9G     0 1.9G   0% /dev
tmpfs           1.9G   12K 1.9G   1% /run
tmpfs           1.9G     0 1.9G   0% /dev/shm
tmpfs           1.9G  704K 1.9G   1% /tmp
```

These are from your HOST system (normal in chroot)

### Check Kernel
```bash
/ # uname -a
Linux raspberrypi 6.12.60-console-v1+ #1 SMP ...
                  ^^^^^^^^^^^^^^^^
                  YOUR kernel (not chroot, still host)
```

### Check Processes
```bash
/ # ps aux
PID   USER     COMMAND
    1 root     /bin/sh           (your shell)
    2 root     [kthreadd]        (kernel threads)
    3 root     [ksoftirqd/0]
    ...
```

### List Available Commands
```bash
/ # busybox
BusyBox v1.36.1 (2024-...) multi-call binary.
Usage: busybox [-h] [COMMAND] [ARG]...
...
Currently installed applets:
  [ ar arp, ash, awk, basename, bash ...
  (300+ applets listed)
```

### Test File Operations
```bash
/ # touch test.txt
/ # ls -l test.txt
-rw-r--r--  1 root root 0 Dec 18 12:34 test.txt

/ # cat > test.txt << EOF
Hello from BusyBox!
EOF

/ # cat test.txt
Hello from BusyBox!
```

### Check Device Nodes
```bash
/ # ls -l /dev/console /dev/null
crw------- 1 root root 5, 1 /dev/console
crw-rw-rw- 1 root root 1, 3 /dev/null
```

### Try a Pipe
```bash
/ # echo "hello world" | grep world
hello world

/ # echo -e "aaa\nbbb\nccc" | sort
aaa
bbb
ccc
```

### Check Mounted Filesystems
```bash
/ # mount
rootfs on / type rootfs (rw)
proc on /proc type proc (rw,nosuid,nodev,noexec,relatime)
sysfs on /sys type sysfs (rw,nosuid,nodev,noexec,relatime)
devtmpfs on /dev type devtmpfs (rw,...)
```

---

## 5.5 Exit Chroot

### What You Did
```bash
/ # exit
$
```

Returns to your host system shell.

### Verification
```bash
pwd
# Output: /home/rhobtor/Ubuntu/kernel_console
# or wherever you were before

ls
# Now you see your host filesystem again
```

---

## 5.6 Unmount Filesystems

### What You Did
```bash
cd ~/os_lab/rootfs
sudo umount dev proc sys
```

### Why Unmount?
- Prevent "busy" errors when reusing
- Clean up mounts before next test
- Prevents conflicts during initramfs packaging

### Verify Unmounting
```bash
# Check what's mounted
mount | grep rootfs

# Should be empty (nothing from your rootfs mounted)
```

### Safe Unmount Order

**Important:** Unmount in reverse order!
```bash
sudo umount dev
sudo umount proc
sudo umount sys
```

Not:
```bash
sudo umount proc
sudo umount sys
sudo umount dev  # ← Can cause issues
```

Why? /dev might be needed for cleanup operations.

---

## Complete Test Workflow

### Step-by-Step Guide

1. **Prepare for testing:**
   ```bash
   cd ~/os_lab/rootfs
   ```

2. **Mount filesystems:**
   ```bash
   sudo mount --bind /dev dev
   sudo mount -t proc proc proc
   sudo mount -t sysfs sys sys
   ```

3. **Enter chroot:**
   ```bash
   sudo chroot . /init
   ```

4. **Run tests:**
   ```bash
   / # ls -la
   / # busybox --version
   / # echo "Testing..." | cat
   / # ps aux
   ```

5. **Exit chroot:**
   ```bash
   / # exit
   ```

6. **Cleanup mounts:**
   ```bash
   sudo umount dev proc sys
   ```

---

## Troubleshooting Chroot

### Issue: "chroot: can't change to /: Operation not permitted"
**Cause:** rootfs might be on NFS or restricted filesystem

**Solution:**
```bash
# Check where rootfs is
mount | grep rootfs

# Try from a different location
cd /tmp
sudo chroot ~/os_lab/rootfs /init
```

### Issue: "init: command not found"
**Cause:** init script not executable or shebang wrong

**Solution:**
```bash
# Make it executable
sudo chmod +x ~/os_lab/rootfs/init

# Check shebang
head -1 ~/os_lab/rootfs/init
# Should be: #!/bin/sh

# Verify /bin/sh exists
file ~/os_lab/rootfs/bin/sh
# Should show: /bin/sh -> busybox (symlink)
```

### Issue: "Can't open /dev/console"
**Cause:** Device node not created or wrong permissions

**Solution:**
```bash
# Check if device exists
ls -l ~/os_lab/rootfs/dev/console

# If missing, create it
sudo mknod ~/os_lab/rootfs/dev/console c 5 1
sudo chmod 600 ~/os_lab/rootfs/dev/console
```

### Issue: "mount: can't find proc in /etc/fstab"
**This is normal!** Chroot doesn't use fstab, you mounted manually.

### Issue: "Device or resource busy" when unmounting
**Cause:** Processes still using the mount

**Solution:**
```bash
# Find processes using mount
sudo lsof | grep rootfs

# Exit the chroot first
# (should be done already)

# Then unmount
sudo umount dev proc sys
```

---

## What You've Verified

✅ Init script executes correctly
✅ BusyBox shell is functional
✅ Device nodes work
✅ /proc and /sys mount properly
✅ File operations work
✅ Pipes and redirects work
✅ Process listing works
✅ Full command set available

---

## Important Notes

### Chroot Reality Check

- ✓ This is a safe way to test
- ✓ Uses your host kernel (kernel8-console-v1)
- ✓ Uses your host's device drivers
- ✓ Doesn't actually boot your OS
- ✗ Doesn't test kernel + OS together
- ✗ Doesn't test boot sequence
- ✗ Doesn't test all hardware initialization

### Next Phase Tests

In Phase 6 (Initramfs), you'll:
- Package this rootfs as boot-time OS
- Actually boot it with your kernel
- See kernel messages during startup
- Test the REAL boot sequence

---

## Next Steps

→ **Phase 6: Create initramfs from rootfs**

Your rootfs is verified and working! Next:
1. Package it as a compressed archive (cpio.gz)
2. Copy to boot partition
3. Configure kernel to boot it
4. Perform real boot test

This is where your OS becomes REAL and boots on the Pi!
