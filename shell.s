.global main
.extern printf
.extern scanf
.extern stdin
.extern getchar

.data
    @ Command messages and their lengths
    prompt_msg:           .asciz "shell> "
    prompt_len=           . - prompt_msg

    exit_msg:             .asciz "\nExiting...\n\n"
    exit_len=             . - exit_msg

    hello_msg:            .asciz "\nHello World!\n\n"
    hello_len=            . - hello_msg

    help_msg:             .asciz "\nMain commands:\nhello - Prints 'Hello World!'\nhelp  - Lists available commands\nexit  - Terminates the shell\nclear - Clears the shell screen\n\nCustom commands:\noct   - Converts a decimal integer to its octal form\navg   - Calculates the average of a set of positive integers up to 3 decimal places\n\n"
    help_len=             . - help_msg

    clear_screen_seq:     .asciz "\033[2J\033[H"
    clear_screen_len=     . - clear_screen_seq

    unknown_cmd_msg:      .asciz "\nUnknown command. Retry.\n\n"
    unknown_cmd_len=      . - unknown_cmd_msg

    @ Buffer for user input
    input_buffer:         .space 256

    @ Command strings for comparison
    exit_cmd:             .asciz "exit"
    hello_cmd:            .asciz "hello"
    help_cmd:             .asciz "help"
    clear_cmd:            .asciz "clear"
    oct_cmd:              .asciz "oct"
    avg_cmd:              .asciz "avg"
    stop_cmd:             .asciz "stop"

    @ Messages and format strings for 'oct' command
    oct_prompt_msg:       .asciz "\nEnter a positive decimal integer: "
    oct_prompt_len =      . - oct_prompt_msg
    oct_result_fmt:       .asciz "\nOctal: %o\n\n"
    oct_invalid_msg:      .asciz "\nInvalid input. Only positive integers accepted.\n\n"
    oct_invalid_len =     . - oct_invalid_msg

    @ Messages and format strings for 'avg' command
    avg_prompt_msg:       .asciz "Enter number to input or 'stop' to finish: "
    avg_prompt_len =      . - avg_prompt_msg
    avg_invalid_num_msg:  .asciz "\nInvalid input. Only positive numbers up to 3 decimal places accepted.\n\n"
    avg_invalid_num_len=  . - avg_invalid_num_msg
    avg_div_zero_msg:     .asciz "\nNo numbers were entered. Average is 0.000\n\n"
    avg_div_zero_len=     . - avg_div_zero_msg
    avg_result_fmt_fp:    .asciz "\nAverage: %d.%03d\n\n"

    avg_help_msg:         .asciz "Note: Only positive numbers up to 3 decimal places accepted.\n\n"
    avg_help_len =        . - avg_help_msg

    @ Format strings for scanf
    scan_str_format:      .asciz "%s"

.text

@ Starting point of the shell program
main:
    sub sp, sp, #8        @ Allocate stack space for LR and r7
    str lr, [sp, #0]      @ Save Link Register
    str r7, [sp, #4]      @ Save r7

main_loop:
    bl print_prompt       @ Print shell prompt
    bl read_input         @ Read user input
    bl process_command    @ Process the input command
    b main_loop           @ Loop indefinitely

@ Exits the shell
exit_shell:
    ldr r7, [sp, #4]      @ Restore r7 and LR
    ldr lr, [sp, #0]
    add sp, sp, #8        @ Deallocate stack space
    mov pc, lr            @ Return from main

@ Function to print the shell prompt "shell> "
print_prompt:
    sub sp, sp, #16       @ Allocate stack space for registers
    str r0, [sp, #0]      @ Save r0-r2 and LR
    str r1, [sp, #4]
    str r2, [sp, #8]
    str lr, [sp, #12]

    mov r0, #1            @ File descriptor: stdout
    ldr r1, =prompt_msg   @ Message address
    mov r2, #prompt_len   @ Message length
    mov r7, #4            @ syscall: sys_write
    svc #0                @ Execute syscall

    ldr lr, [sp, #12]     @ Restore saved registers
    ldr r2, [sp, #8]
    ldr r1, [sp, #4]
    ldr r0, [sp, #0]
    add sp, sp, #16       @ Deallocate stack space
    mov pc, lr            @ Return

@ Function to read user input from stdin
read_input:
    sub sp, sp, #24       @ Allocate stack space for registers
    str r0, [sp, #0]      @ Save r0-r4 and LR
    str r1, [sp, #4]
    str r2, [sp, #8]
    str r3, [sp, #12]
    str r4, [sp, #16]
    str lr, [sp, #20]

    mov r0, #0            @ File descriptor: stdin
    ldr r1, =input_buffer @ Buffer address
    mov r2, #256          @ Max bytes for buffer
    mov r7, #3            @ syscall: sys_read
    svc #0                @ Execute syscall (number of bytes read in r0)

    mov r3, r0            @ Store bytes read
    sub r3, r3, #1        @ Calculate last char index
    movlt r3, #0          @ If no input is given, index set to 0
    ldrb r2, [r1, r3]     @ Load last char
    cmp r2, #10           @ Check for newline
    mov r4, #0            @ Load null terminator to r4
    beq if_newline        @ Replacing newline
    bne not_newline       @ If no newline present

exit_input:
    ldr lr, [sp, #20]     @ Restore saved registers
    ldr r4, [sp, #16]
    ldr r3, [sp, #12]
    ldr r2, [sp, #8]
    ldr r1, [sp, #4]
    ldr r0, [sp, #0]
    add sp, sp, #24       @ Deallocate stack space
    mov pc, lr            @ Return

if_newline:
    strb r4, [r1, r3]     @ Replace newline with null terminator
    b exit_input

not_newline:
    strb r4, [r1, r3]     @ Add null terminator at end of input
    bl clear_input_buffer @ Clear remaining buffer contents
    b exit_input

@ Function to process the command
process_command:
    sub sp, sp, #20       @ Allocate stack space for registers
    str r0, [sp, #0]      @ Save r0-r3 and LR
    str r1, [sp, #4]
    str r2, [sp, #8]
    str r3, [sp, #12]
    str lr, [sp, #16]

    ldr r0, =input_buffer @ Load input buffer address

    @ Following blocks compare input with various commands and branch to that function
    ldr r1, =exit_cmd
    bl string_compare
    cmp r1, #0
    beq handle_exit

    ldr r1, =hello_cmd
    bl string_compare
    cmp r1, #0
    beq handle_hello

    ldr r1, =help_cmd
    bl string_compare
    cmp r1, #0
    beq handle_help

    ldr r1, =clear_cmd
    bl string_compare
    cmp r1, #0
    beq handle_clear

    ldr r1, =oct_cmd
    bl string_compare
    cmp r1, #0
    beq handle_oct

    ldr r1, =avg_cmd
    bl string_compare
    cmp r1, #0
    beq handle_avg

    b handle_unknown      @ If no match, handle as unknown command

end_process:
    ldr lr, [sp, #16]     @ Restore saved registers
    ldr r3, [sp, #12]
    ldr r2, [sp, #8]
    ldr r1, [sp, #4]
    ldr r0, [sp, #0]
    add sp, sp, #20       @ Deallocate stack space
    mov pc, lr            @ Return

@ Handles the 'exit' command
handle_exit:
    mov r0, #1            @ Print exit message
    ldr r1, =exit_msg
    mov r2, #exit_len
    mov r7, #4
    svc #0

    ldr lr, [sp, #16]     @ Restore registers and branch to exit_shell
    ldr r3, [sp, #12]
    ldr r2, [sp, #8]
    ldr r1, [sp, #4]
    ldr r0, [sp, #0]
    add sp, sp, #20
    b exit_shell

@ Handles the 'hello' command
handle_hello:
    sub sp, sp, #16       @ Allocate stack space and save registers
    str r0, [sp, #0]
    str r1, [sp, #4]
    str r2, [sp, #8]
    str lr, [sp, #12]

    mov r0, #1            @ Print "Hello World!" message
    ldr r1, =hello_msg
    mov r2, #hello_len
    mov r7, #4
    svc #0

    ldr lr, [sp, #12]     @ Restore registers and return
    ldr r2, [sp, #8]
    ldr r1, [sp, #4]
    ldr r0, [sp, #0]
    add sp, sp, #16
    b end_process

@ Handles the 'help' command
handle_help:
    sub sp, sp, #16       @ Allocate stack space and save registers
    str r0, [sp, #0]
    str r1, [sp, #4]
    str r2, [sp, #8]
    str lr, [sp, #12]

    mov r0, #1            @ Print help message
    ldr r1, =help_msg
    ldr r2, =help_len
    mov r7, #4
    svc #0

    ldr lr, [sp, #12]     @ Restore registers and return
    ldr r2, [sp, #8]
    ldr r1, [sp, #4]
    ldr r0, [sp, #0]
    add sp, sp, #16
    b end_process

@ Handles the 'clear' command
handle_clear:
    sub sp, sp, #16       @ Allocate stack space and save registers
    str r0, [sp, #0]
    str r1, [sp, #4]
    str r2, [sp, #8]
    str lr, [sp, #12]

    mov r0, #1            @ Print ANSI escape sequence to clear screen
    ldr r1, =clear_screen_seq
    mov r2, #clear_screen_len
    mov r7, #4
    svc #0

    ldr lr, [sp, #12]     @ Restore registers and return
    ldr r2, [sp, #8]
    ldr r1, [sp, #4]
    ldr r0, [sp, #0]
    add sp, sp, #16
    b end_process

@ Handles unknown commands
handle_unknown:
    sub sp, sp, #16       @ Allocate stack space and save registers
    str r0, [sp, #0]
    str r1, [sp, #4]
    str r2, [sp, #8]
    str lr, [sp, #12]

    mov r0, #1            @ Print unknown command message
    ldr r1, =unknown_cmd_msg
    mov r2, #unknown_cmd_len
    mov r7, #4
    svc #0

    ldr lr, [sp, #12]     @ Restore registers and return
    ldr r2, [sp, #8]
    ldr r1, [sp, #4]
    ldr r0, [sp, #0]
    add sp, sp, #16
    b end_process

@ Handles the 'oct' command: converts decimal to octal
handle_oct:
    sub sp, sp, #12       @ Allocate stack space and save registers
    str lr, [sp, #0]
    str r4, [sp, #4]
    str r5, [sp, #8]

    mov r0, #1            @ Print prompt for decimal input
    ldr r1, =oct_prompt_msg
    mov r2, #oct_prompt_len
    mov r7, #4
    svc #0

    ldr r0, =scan_str_format @ Read input as a string
    ldr r1, =input_buffer
    bl scanf

    ldr r0, =input_buffer @ Initialize for scanning loop
    mov r1, #0            @ String index
    mov r2, #0            @ Result
    mov r3, #0            @ Character count (for length check)

oct_validate_loop:
    ldrb r4, [r0, r1]     @ Load byte
    cmp r4, #0            @ Null terminator?
    beq oct_convert       @ Yes, convert
    cmp r4, #'.'          @ For invalid chars: '.', '-', non-digits, branch to oct_invalid
    beq oct_invalid
    cmp r4, #'-'
    beq oct_invalid
    cmp r4, #'0'
    blt oct_invalid
    cmp r4, #'9'
    bgt oct_invalid
    add r1, r1, #1        @ Increment index
    add r3, r3, #1        @ Increment count
    b oct_validate_loop

oct_invalid:
    mov r0, #1            @ Print invalid input message
    ldr r1, =oct_invalid_msg
    mov r2, #oct_invalid_len
    mov r7, #4
    svc #0
    b oct_end

@ Converting string to integer
oct_convert:
    cmp r3, #0            @ Check if any digits were entered
    beq oct_invalid       @ If 0, it's invalid

    ldr r0, =input_buffer @ Load number (string)
    mov r1, #0            @ String index
    mov r2, #0            @ Converted integer
    mov r5, #10           @ 10 for multiplying

oct_convert_loop:
    ldrb r4, [r0, r1]     @ Load byte
    cmp r4, #0            @ Null terminator?
    beq oct_result        @ Yes, then show result
    sub r4, r4, #'0'      @ Substracting ASCII value of integer with that of 0 to get value
    mul r3, r2, r5        @ Pushing digits to the left by multiplying with 10
    mov r2, r3
    add r2, r2, r4        @ Adding the next digit to the number
    add r1, r1, #1        @ Increment index
    b oct_convert_loop

oct_result:
    mov r1, r2            @ Move converted value for printf
    ldr r0, =oct_result_fmt @ Format string for octal output
    bl printf             @ Print octal

oct_end:
    bl clear_input_buffer @ Clear input buffer
    ldr r5, [sp, #8]      @ Restore registers and return
    ldr r4, [sp, #4]
    ldr lr, [sp, #0]
    add sp, sp, #12
    b end_process

@ Handles the 'avg' command: calculates the average of positive numbers upto 3 decimal places
handle_avg:
    sub sp, sp, #28       @ Allocate stack space and save registers
    str lr, [sp, #0]
    str r4, [sp, #4]      @ r4: total sum
    str r5, [sp, #8]      @ r5: count of numbers
    str r6, [sp, #12]     @ r6: current scaled number value
    str r8, [sp, #16]     @ r8: whole part of average
    str r9, [sp, #20]     @ r9: fractional part / remainder
    str r10, [sp, #24]    @ r10: temporary for char value

    mov r4, #0            @ Initialize total sum and count
    mov r5, #0

    mov r0, #1            @ Print avg help message
    ldr r1, =avg_help_msg
    mov r2, #avg_help_len
    mov r7, #4
    svc #0

avg_loop:
    mov r0, #1            @ Prompt for number input
    ldr r1, =avg_prompt_msg
    mov r2, #avg_prompt_len
    mov r7, #4
    svc #0

    ldr r0, =scan_str_format @ Read input as string
    ldr r1, =input_buffer
    bl scanf

    ldr r0, =input_buffer @ Check if input is "stop"
    ldr r1, =stop_cmd
    bl string_compare
    cmp r1, #0
    beq avg_calculate     @ If "stop", calculate average

    ldr r0, =input_buffer @ Initialize for number scanning
    mov r1, #0            @ String index
    mov r2, #0            @ Accumulated integer part
    mov r3, #0            @ Decimal point marker (0: no dot, 1: dot found)
    mov r6, #0            @ Count of digits after decimal point
    mov r9, #10           @ 10 for multiplying

avg_input_analyze_loop:
    ldrb r10, [r0, r1]    @ Load character
    cmp r10, #0           @ Null terminator?
    beq avg_input_analyze_done @ Yes, then end scanning
    cmp r10, #'.'         @ Decimal point?
    beq avg_dot_found     @ Yes, then branch here
    cmp r10, #'0'         @ Checking invalid non-digit character by checking whether ASCII value is lesser than that of 0
    blt avg_parse_invalid @ Branch if invalid
    cmp r10, #'9'         @ Checking invalid non-digit character by checking whether ASCII value is greater than that of 9
    bgt avg_parse_invalid @ Branch if invalid
    sub r10, r10, #'0'    @ Convert ASCII to digit
    mul r8, r2, r9        @ Pushing digits to the left by multiplying
    mov r2, r8
    add r2, r2, r10       @ Adding next digit
    cmp r3, #1            @ If decimal point found, count fractional digits
    addeq r6, r6, #1      @ Counting fractional digits
    add r1, r1, #1        @ Increment index
    b avg_input_analyze_loop @ Loop

avg_dot_found:
    cmp r3, #1            @ Multiple decimal points?
    beq avg_parse_invalid @ Yes, then invalid
    mov r3, #1            @ Set decimal point marker to 1
    add r1, r1, #1        @ Increment index
    b avg_input_analyze_loop @ Back to loop

avg_input_analyze_done:
    mov r8, #1000         @ Scaling factors for 3 decimal places
    mov r9, #100
    mov r10, #10

    cmp r6, #0            @ Scale based on fractional digits count
    beq avg_scale_3       @ No fractional digits (e.g., 123 -> 123000)
    cmp r6, #1
    beq avg_scale_2       @ 1 fractional digit (e.g., 12.3 -> 12300)
    cmp r6, #2
    beq avg_scale_1       @ 2 fractional digits (e.g., 1.23 -> 1230)
    cmp r6, #3
    beq avg_scale_0       @ 3 fractional digits (e.g., 0.123 -> 123)
    b avg_parse_invalid   @ More than 3 fractional digits, it's invalid

avg_scale_3:
    mul r6, r2, r8        @ Scale by 1000
    b avg_parse_ok
avg_scale_2:
    mul r6, r2, r9        @ Scale by 100
    b avg_parse_ok
avg_scale_1:
    mul r6, r2, r10       @ Scale by 10
    b avg_parse_ok
avg_scale_0:
    mov r6, r2            @ No scaling
    b avg_parse_ok

avg_parse_ok:
    add r4, r4, r6        @ Add to total sum and increment count
    add r5, r5, #1

    bl clear_input_buffer @ Clear input buffer
    b avg_loop            @ Continue input loop

avg_parse_invalid:
    bl clear_input_buffer @ Clear input buffer

    mov r0, #1            @ Print invalid number message
    ldr r1, =avg_invalid_num_msg
    mov r2, #avg_invalid_num_len
    mov r7, #4
    svc #0
    b avg_loop            @ Continue input loop

avg_calculate:
    cmp r5, #0            @ Check if count of numbers is zero
    bne avg_divide        @ If count is not equal to 0, proceed

    mov r0, #1            @ If it is, print that no numbers were input
    ldr r1, =avg_div_zero_msg
    mov r2, #avg_div_zero_len
    mov r7, #4
    svc #0
    b avg_end

avg_divide:
    mov r0, r4            @ To, divide total sum by count, load dividend
    mov r1, r5            @ Load divisor
    bl divide_repeated_subtraction @ Returns quotient (scaled avg) in r0, remainder in r1
    mov r6, r0            @ r6 = scaled average
    mov r9, r1            @ r9 = remainder

    mov r0, #2            @ Rounding: if 2 * remainder >= divisor, round up
    mul r1, r9, r0
    mov r9, r1
    cmp r9, r5
    addge r6, r6, #1      @ Rounding up if condition met

    mov r0, r6            @ Get whole and fractional parts for printing. Load dividend
    mov r1, #1000         @ Load divisor
    bl divide_repeated_subtraction @ Returns whole part in r0, fractional in r1
    mov r9, r0            @ r9 = whole part
    mov r8, r1            @ r8 = fractional part

    ldr r0, =avg_result_fmt_fp @ Print formatted average
    mov r1, r9                 @ Whole part
    mov r2, r8                 @ Fractional part
    bl printf

avg_end:
    bl clear_input_buffer @ Clear input buffer
    ldr r10, [sp, #24]    @ Restore registers and return
    ldr r9, [sp, #20]
    ldr r8, [sp, #16]
    ldr r6, [sp, #12]
    ldr r5, [sp, #8]
    ldr r4, [sp, #4]
    ldr lr, [sp, #0]
    add sp, sp, #28
    b end_process

@ Divides r0 by r1 using repeated subtraction.
@ Input: r0 = Dividend, r1 = Divisor
@ Output: r0 = Quotient, r1 = Remainder
divide_repeated_subtraction:
    sub sp, sp, #12       @ Allocate stack space and save registers
    str r2, [sp, #0]
    str r3, [sp, #4]
    str lr, [sp, #8]

    cmp r1, #0            @ Check for division by zero
    moveq r0, #0          @ If zero, set quotient and remainder to 0
    moveq r1, #0
    beq division_end

    mov r2, #0            @ Initialize quotient

div_loop:
    cmp r0, r1            @ Compare dividend with divisor
    blt end_div_loop      @ If dividend < divisor, division complete
    sub r0, r0, r1        @ Subtract divisor
    add r2, r2, #1        @ Increment quotient
    b div_loop

end_div_loop:
    mov r1, r0            @ Move remaining dividend to remainder
    mov r0, r2            @ Move quotient to r0

division_end:
    ldr lr, [sp, #8]      @ Restore registers and return
    ldr r3, [sp, #4]
    ldr r2, [sp, #0]
    add sp, sp, #12
    mov pc, lr

@ Clears the input buffer by reading remaining characters until a newline is met
clear_input_buffer:
    sub sp, sp, #12       @ Allocate stack space and save registers
    str r0, [sp, #0]
    str r1, [sp, #4]
    str lr, [sp, #8]

    ldr r0, =stdin        @ Get stdin stream pointer
    ldr r0, [r0]
    bl getchar            @ Read first char

clear_buffer_loop:
    cmp r0, #10           @ Check for newline
    beq clear_buffer_end  @ If newline, buffer is cleared

    ldr r0, =stdin        @ Get stdin stream pointer again
    ldr r0, [r0]
    bl getchar            @ Read next character
    b clear_buffer_loop

clear_buffer_end:
    ldr lr, [sp, #8]      @ Restore registers and return
    ldr r1, [sp, #4]
    ldr r0, [sp, #0]
    add sp, sp, #12
    mov pc, lr

@ String comparison function
@ r0: pointer to string 1, r1: pointer to string 2
@ Returns: r1 = 0 if strings are equal, non-zero otherwise
string_compare:
    sub sp, sp, #16       @ Allocate stack space and save registers
    str r0, [sp, #0]
    str r2, [sp, #4]
    str r3, [sp, #8]
    str lr, [sp, #12]

string_compare_loop:
    ldrb r2, [r0], #1     @ Load byte from string 1 and increment pointer
    ldrb r3, [r1], #1     @ Load byte from string 2 and increment pointer
    cmp r2, r3            @ Compare bytes
    movne r1, #1          @ If not equal, set r1 to 1
    bne string_compare_end @ If not equal, end comparison
    cmp r2, #0            @ Check for null terminator
    bne string_compare_loop @ If not null, continue loop
    mov r1, #0            @ If all matched and null reached, strings are equal
    b string_compare_end

string_compare_end:
    ldr lr, [sp, #12]     @ Restore registers and return
    ldr r3, [sp, #8]
    ldr r2, [sp, #4]
    ldr r0, [sp, #0]
    add sp, sp, #16
    mov pc, lr

.section .note.GNU-stack,"",%progbits
