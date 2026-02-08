# ARM32 ASSEMBLY SHELL

This project is an ARM32 assembly-based shell designed to run on Linux systems using the ARM cross-compiler and QEMU emulator. The shell provides basic functionalities such as printing "Hello World!", displaying help messages, clearing the screen, and exiting. Additionally, it includes custom commands for converting decimal integers to octal and calculating the average of a set of positive numbers, up to three decimal places.

### 1. Prerequisites

You need to install the ARM cross-compiler and the QEMU emulator. On Linux/Windows Subsystem for Linux, run:

```bash
sudo apt update
sudo apt install gcc-arm-linux-gnueabi qemu-user
```

### 2. Compilation

Use the ARM cross-compiler to assemble and link the source code into an executable:

```bash
arm-linux-gnueabi-gcc -o shell shell.s
```

### 3. Running the Shell

Since the executable is built for the ARM architecture, use QEMU to run it on your host machine. You must point QEMU to the ARM library path so it can find the necessary dependencies (like `printf` and `scanf`):

```bash
qemu-arm -L /usr/arm-linux-gnueabi ./shell
```

### 4. Commands assigned for the CLI

The CLI shell supports the following commands:
- hello: Prints the message "Hello World!" to the console.
- help: Displays a list of all available commands, categorised into "Main commands" and "Custom commands," along with a brief description of each.
- exit: Terminates the shell program.
- clear: Clears the terminal screen.
- oct: Prompts the user to enter a positive decimal integer and then converts it and displays its octal representation. It also checks the input to ensure only positive integers are accepted.
- avg: Prompts the user to enter a series of positive numbers (integers or decimals up to three decimal places). The input process continues until the user types "stop". After receiving the "stop" command, it calculates and displays the average of the entered numbers, rounded to three decimal places. It also checks the input to ensure only positive numbers up to 3 decimal places are accepted.
