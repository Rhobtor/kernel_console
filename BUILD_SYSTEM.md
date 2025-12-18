# Build System Architecture

## Overview

Este documento explica cómo convertir el proyecto en reproducible y cómo organizar el código para que otros puedan:
1. Descargar el proyecto
2. Compilar el kernel
3. Construir el OS
4. Generar la imagen lista para grabar en SD

---

## Estructura de Directorio Recomendada

```
kernel_console/
│
├── README.md                    # Readme principal
├── PROJECT_VISION.md            # Visión del proyecto (lo que ya hiciste)
│
├── docs/
│   └── progress_logs/           # Lo que ya existe
│       ├── README.md
│       ├── Phase-01-...md
│       └── ...
│
├── scripts/                     # Scripts de automatización
│   ├── build-kernel.sh         # Compilar kernel
│   ├── build-rootfs.sh         # Construir rootfs
│   ├── build-initramfs.sh      # Empaquetar OS
│   ├── setup-environment.sh    # Configurar todo
│   └── config/                 # Archivos de configuración
│       ├── kernel.config       # Configuración del kernel
│       ├── busybox.config      # Configuración de BusyBox
│       └── boot.config         # config.txt, cmdline.txt, etc.
│
├── src/                        # Código fuente
│   ├── kernel/                 # Parches/cambios al kernel
│   │   └── console-patches/
│   ├── rootfs/                 # Scripts y archivos de rootfs
│   │   ├── init               # Script init
│   │   ├── overlay/           # Archivos adicionales
│   │   └── apps/              # Aplicaciones custom
│   └── drivers/               # Drivers custom
│
├── build/                      # Directorio temporal (NO subir a git)
│   ├── kernel/
│   ├── busybox/
│   └── rootfs/
│
├── releases/                   # Imágenes finales (NO subir a git, pero documentar cómo generarlas)
│   └── v0.1-pi4/
│       ├── kernel8-console-v1.img
│       ├── initramfs-console-v2.cpio.gz
│       └── boot-files/
│
├── .gitignore                 # Ignorar archivos grandes
└── Makefile                   # Build automatizado
```

---

## Paso 1: Crear `.gitignore`

Primero, evita subir archivos grandes y temporales:

```bash
# Crear archivo .gitignore en la raíz del proyecto
```

**Contenido necesario:**

```
# Build artifacts
build/
releases/*.img
releases/*.cpio.gz
releases/*.iso
*.o
*.ko
*.so

# Temporary files
*.swp
*.swo
*~
.tmp/
temp/

# Large binaries
busybox
vmlinux
*.elf

# System files
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.sublime-project

# Kernel builds (muy grandes)
linux/
```

---

## Paso 2: Crear Scripts Automatizados

### **scripts/setup-environment.sh**
```bash
#!/bin/bash
# Configurar entorno de compilación

echo "=== Kernel Console Build Environment Setup ==="

# 1. Verificar dependencias
echo "Verificando herramientas necesarias..."
for tool in git make gcc bc bison flex wget; do
    if ! command -v $tool &> /dev/null; then
        echo "ERROR: $tool no encontrado"
        exit 1
    fi
done

# 2. Crear directorios
mkdir -p build/{kernel,busybox,rootfs}
mkdir -p releases/v0.1-pi4

# 3. Descargar fuentes si no existen
if [ ! -d "build/kernel/linux" ]; then
    echo "Descargando kernel source..."
    cd build/kernel
    git clone --depth=1 https://github.com/raspberrypi/linux
    cd ../../
fi

if [ ! -f "build/busybox/busybox-1.36.1.tar.bz2" ]; then
    echo "Descargando BusyBox..."
    cd build/busybox
    wget https://busybox.net/downloads/busybox-1.36.1.tar.bz2
    tar xf busybox-1.36.1.tar.bz2
    cd ../../
fi

echo "✓ Entorno listo"
echo "Próximo paso: ./scripts/build-kernel.sh"
```

### **scripts/build-kernel.sh**
```bash
#!/bin/bash
# Compilar kernel para Raspberry Pi 4

set -e  # Exit on error

KERNEL_SOURCE="build/kernel/linux"
KERNEL_BUILD="build/kernel"
KERNEL_CONFIG="scripts/config/kernel.config"

echo "=== Building Kernel ==="

if [ ! -d "$KERNEL_SOURCE" ]; then
    echo "ERROR: Kernel source no encontrado"
    echo "Ejecuta primero: ./scripts/setup-environment.sh"
    exit 1
fi

cd "$KERNEL_SOURCE"

# Copiar configuración personalizada
echo "Aplicando configuración..."
cp ../../"$KERNEL_CONFIG" .config

# Compilar
echo "Compilando kernel (esto toma 30-60 minutos)..."
export KERNEL=kernel8
make -j4 Image.gz modules dtbs

# Instalar módulos
echo "Instalando módulos..."
mkdir -p ../../build/rootfs/lib/modules
make INSTALL_MOD_PATH=../../build/rootfs modules_install

# Copiar kernel compilado
cp arch/arm64/boot/Image.gz ../../releases/v0.1-pi4/kernel8-console-v1.img
cp arch/arm64/boot/dts/*.dtb ../../releases/v0.1-pi4/

echo "✓ Kernel compilado exitosamente"
cd ../../
```

### **scripts/build-rootfs.sh**
```bash
#!/bin/bash
# Construir rootfs con BusyBox

set -e

BUSYBOX_DIR="build/busybox/busybox-1.36.1"
ROOTFS_DIR="build/rootfs"
BUSYBOX_CONFIG="scripts/config/busybox.config"

echo "=== Building Rootfs ==="

if [ ! -d "$BUSYBOX_DIR" ]; then
    echo "ERROR: BusyBox source no encontrado"
    exit 1
fi

# Configurar BusyBox
cd "$BUSYBOX_DIR"
cp ../../../"$BUSYBOX_CONFIG" .config
make -j4

# Instalar
echo "Instalando BusyBox..."
make CONFIG_PREFIX=../../../"$ROOTFS_DIR" install

cd ../../../

# Crear estructura de directorios
echo "Creando estructura de directorios..."
mkdir -p "$ROOTFS_DIR"/{dev,proc,sys,tmp,mnt,etc}
chmod 1777 "$ROOTFS_DIR"/tmp

# Crear device nodes
echo "Creando device nodes..."
sudo mknod "$ROOTFS_DIR"/dev/console c 5 1
sudo mknod "$ROOTFS_DIR"/dev/null c 1 3
sudo chmod 600 "$ROOTFS_DIR"/dev/console
sudo chmod 666 "$ROOTFS_DIR"/dev/null

# Copiar init script
echo "Copiando init script..."
cp src/rootfs/init "$ROOTFS_DIR"/
sudo chmod +x "$ROOTFS_DIR"/init

echo "✓ Rootfs construido"
```

### **scripts/build-initramfs.sh**
```bash
#!/bin/bash
# Empaquetar rootfs como initramfs

set -e

ROOTFS_DIR="build/rootfs"
OUTPUT="releases/v0.1-pi4/initramfs-console-v2.cpio.gz"

echo "=== Building Initramfs ==="

if [ ! -d "$ROOTFS_DIR" ]; then
    echo "ERROR: Rootfs no encontrado"
    exit 1
fi

cd "$ROOTFS_DIR"
echo "Creando archivo CPIO..."
sudo find . | cpio -H newc -o | gzip > "../../$OUTPUT"
cd ../../

echo "✓ Initramfs creado: $OUTPUT"
ls -lh "$OUTPUT"
```

---

## Paso 3: Crear Makefile Principal

**Makefile en raíz:**

```makefile
# Kernel Console Build System

.PHONY: help setup build clean install-pi release

help:
	@echo "Kernel Console Build System"
	@echo ""
	@echo "Targets:"
	@echo "  make setup       - Configure environment & download sources"
	@echo "  make build       - Build kernel + rootfs + initramfs"
	@echo "  make clean       - Remove build artifacts"
	@echo "  make install-pi  - Instructions for installing to Pi"
	@echo "  make release     - Create release package"

setup:
	@chmod +x scripts/*.sh
	@./scripts/setup-environment.sh

build: build-kernel build-rootfs build-initramfs
	@echo "✓ Build complete!"

build-kernel:
	@./scripts/build-kernel.sh

build-rootfs:
	@./scripts/build-rootfs.sh

build-initramfs:
	@./scripts/build-initramfs.sh

clean:
	rm -rf build/
	@echo "✓ Build artifacts cleaned"

install-pi:
	@echo "Instrucciones para instalar en Raspberry Pi:"
	@echo ""
	@echo "1. Copiar archivos a la partición boot:"
	@echo "   sudo cp releases/v0.1-pi4/kernel8-console-v1.img /boot/firmware/"
	@echo "   sudo cp releases/v0.1-pi4/initramfs-console-v2.cpio.gz /boot/firmware/"
	@echo ""
	@echo "2. Actualizar configuración de firmware:"
	@echo "   sudo nano /boot/firmware/config.txt"
	@echo "   (ver scripts/config/boot.config para cambios necesarios)"
	@echo ""
	@echo "3. Reboot:"
	@echo "   sudo reboot"

release:
	@mkdir -p releases/v0.1-pi4/boot-config
	@cp scripts/config/boot.config releases/v0.1-pi4/boot-config/config.txt
	@cp scripts/config/cmdline.config releases/v0.1-pi4/boot-config/cmdline.txt
	@tar czf releases/kernel-console-v0.1-pi4.tar.gz releases/v0.1-pi4/
	@echo "✓ Release package created: releases/kernel-console-v0.1-pi4.tar.gz"
```

---

## Paso 4: Archivos de Configuración

### **scripts/config/kernel.config**
```
# Copiar la salida de tu build anterior:
# make savedefconfig
# Luego copiar ese archivo aquí
ARM64=y
CONFIG_LOCALVERSION="-console-v1"
# ... más opciones
```

### **scripts/config/busybox.config**
```
# Similar - guardar tu .config de BusyBox
CONFIG_STATIC=y
# ... más opciones
```

### **scripts/config/boot.config**
```
# /boot/firmware/config.txt

arm_64bit=1
kernel=kernel8-console-v1.img
initramfs initramfs-console-v2.cpio.gz followkernel
#auto_initramfs=1
```

---

## Paso 5: Script Init en Control de Versiones

**src/rootfs/init:**

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

---

## Cómo Funciona para Usuarios

### **Descarga y Build Automatizado:**

```bash
# Usuario descarga tu repo
git clone https://github.com/Rhobtor/kernel_console
cd kernel_console

# Setup automático (descarga fuentes, configura entorno)
make setup

# Build todo
make build

# Espera 1-2 horas...
# ✓ Listo!

# Instrucciones para instalar
make install-pi
```

### **Resultado:**

```
releases/v0.1-pi4/
├── kernel8-console-v1.img          (10-15 MB)
├── initramfs-console-v2.cpio.gz    (2-3 MB)
├── *.dtb                           (device trees)
├── boot-config/
│   ├── config.txt                 (copiar a /boot/firmware/)
│   └── cmdline.txt                (copiar a /boot/firmware/)
└── README.txt                     (instrucciones instalación)
```

---

## Control de Versiones

### **Qué SI subir a Git:**
- ✅ Scripts de compilación
- ✅ Configuraciones (.config files)
- ✅ Código fuente custom (drivers, apps)
- ✅ Init scripts
- ✅ Documentación
- ✅ Patches al kernel

### **Qué NO subir a Git:**
- ❌ Binarios compilados (kernel, busybox)
- ❌ Fuentes descargadas (linux/, busybox-1.36.1/)
- ❌ Directorios build/
- ❌ Archivos .o, .ko
- ❌ Imágenes grandes (.img, .cpio.gz)

---

## Ejemplo de Flujo de Trabajo para Próximas Fases

### **Cuando hagas Fase 9 (Input System):**

1. Creas un nuevo driver en `src/drivers/gpio-input/`
2. Modificas los scripts de build para compilarlo
3. Lo incluyes en el initramfs automáticamente
4. Subes todo a GitHub
5. Usuario descarga → `make build` → ¡Tiene input funcionando!

### **Estructura para nueva Fase:**

```
src/drivers/gpio-input/
├── Makefile
├── gpio-input.c
├── gpio-input.h
└── patch-kernel.sh    # Script para aplicar parches

scripts/build-drivers.sh    # New build script

Makefile (updated)
  ...
  build: build-kernel build-drivers build-rootfs build-initramfs
```

---

## Próximos Pasos

1. **Crea `.gitignore`** - Evita subir archivos grandes
2. **Crea `scripts/` directory** - Con los scripts que mostramos
3. **Crea `src/` directory** - Con código organizado
4. **Crea `Makefile`** - Build automatizado
5. **Documenta en README** - Cómo descargar y compilar

¿Quieres que empecemos a implementar esto ahora?
