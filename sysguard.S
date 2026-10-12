.global _start

.section .text
_start:
menu_loop:
    adr x1, clear_screen
    mov x2, #clear_screen_len
    bl write_stdout
    adr x1, banner
    mov x2, #banner_len
    bl write_stdout

    mov x0, #0
    adr x1, input_buf
    mov x2, #32
    mov x8, #63
    svc #0
    cmp x0, #0
    ble exit_program
    adr x1, input_buf
    ldrb w2, [x1]
    cmp w2, #'1'
    b.eq system_info
    cmp w2, #'2'
    b.eq process_monitor
    cmp w2, #'3'
    b.eq permission_audit
    cmp w2, #'4'
    b.eq save_report
    cmp w2, #'0'
    b.eq exit_program
    adr x1, invalid_msg
    mov x2, #invalid_msg_len
    bl write_stdout
    bl pause_enter
    b menu_loop

system_info:
    adr x1, system_title
    mov x2, #system_title_len
    bl write_stdout
    adr x0, uts_buf
    mov x8, #160
    svc #0
    cmp x0, #0
    blt uname_error
    adr x1, label_kernel
    mov x2, #label_kernel_len
    bl write_stdout
    adr x1, uts_buf
    mov x2, #65
    bl write_field
    adr x1, label_node
    mov x2, #label_node_len
    bl write_stdout
    adr x1, uts_buf
    add x1, x1, #65
    mov x2, #65
    bl write_field
    adr x1, label_release
    mov x2, #label_release_len
    bl write_stdout
    adr x1, uts_buf
    add x1, x1, #130
    mov x2, #65
    bl write_field
    adr x1, label_version
    mov x2, #label_version_len
    bl write_stdout
    adr x1, uts_buf
    add x1, x1, #195
    mov x2, #65
    bl write_field
    adr x1, label_arch
    mov x2, #label_arch_len
    bl write_stdout
    adr x1, uts_buf
    add x1, x1, #260
    mov x2, #65
    bl write_field
    adr x1, label_pid
    mov x2, #label_pid_len
    bl write_stdout
    mov x8, #172
    svc #0
    bl print_u64
    adr x1, newline
    mov x2, #1
    bl write_stdout
    b finish_module
uname_error:
    adr x1, err_uname
    mov x2, #err_uname_len
    bl write_stdout
    b finish_module

process_monitor:
    adr x1, process_title
    mov x2, #process_title_len
    bl write_stdout
    adr x1, proc_status_path
    bl read_file_path
    b finish_module

permission_audit:
    adr x1, audit_title
    mov x2, #audit_title_len
    bl write_stdout
    adr x1, audit_status_label
    mov x2, #audit_status_label_len
    bl write_stdout
    adr x1, proc_status_path
    bl check_file
    adr x1, audit_mem_label
    mov x2, #audit_mem_label_len
    bl write_stdout
    adr x1, proc_meminfo_path
    bl check_file
    adr x1, audit_route_label
    mov x2, #audit_route_label_len
    bl write_stdout
    adr x1, proc_route_path
    bl check_file
    adr x1, audit_note
    mov x2, #audit_note_len
    bl write_stdout
    b finish_module

save_report:
    adr x1, report_title
    mov x2, #report_title_len
    bl write_stdout
    // openat(AT_FDCWD, "sysguard-report.txt", O_WRONLY|O_CREAT|O_TRUNC, 0600)
    mov x0, #-100
    adr x1, report_path
    mov x2, #577
    mov x3, #384
    mov x8, #56
    svc #0
    cmp x0, #0
    blt report_error
    mov x19, x0
    adr x1, report_header
    mov x2, #report_header_len
    bl write_report
    adr x0, uts_buf
    mov x8, #160
    svc #0
    cmp x0, #0
    blt report_uname_error
    adr x1, report_kernel
    mov x2, #report_kernel_len
    bl write_report
    adr x1, uts_buf
    mov x2, #65
    bl write_report_field
    adr x1, report_release
    mov x2, #report_release_len
    bl write_report
    adr x1, uts_buf
    add x1, x1, #130
    mov x2, #65
    bl write_report_field
    adr x1, report_arch
    mov x2, #report_arch_len
    bl write_report
    adr x1, uts_buf
    add x1, x1, #260
    mov x2, #65
    bl write_report_field
    mov x0, x19
    mov x8, #57
    svc #0
    adr x1, report_ok
    mov x2, #report_ok_len
    bl write_stdout
    b finish_module
report_uname_error:
    mov x0, x19
    mov x8, #57
    svc #0
report_error:
    adr x1, report_fail
    mov x2, #report_fail_len
    bl write_stdout
    b finish_module

// write_stdout: x1=buffer, x2=len
write_stdout:
    mov x0, #1
    mov x8, #64
    svc #0
    ret

// write_field: x1=field start, x2=max bytes; write until NUL or max
write_field:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x3, x1
    mov x4, x2
1:
    cbz x4, 2f
    ldrb w5, [x3]
    cbz w5, 2f
    add x3, x3, #1
    sub x4, x4, #1
    b 1b
2:
    sub x2, x3, x1
    bl write_stdout
    adr x1, newline
    mov x2, #1
    bl write_stdout
    ldp x29, x30, [sp], #16
    ret

// read_file_path: x1=path; opens and writes file contents to stdout
read_file_path:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x0, #-100
    mov x2, #0
    mov x8, #56
    svc #0
    cmp x0, #0
    blt file_read_error
    mov x19, x0
3:
    mov x0, x19
    adr x1, file_buf
    mov x2, #1024
    mov x8, #63
    svc #0
    cmp x0, #0
    ble 4f
    mov x2, x0
    adr x1, file_buf
    bl write_stdout
    b 3b
4:
    mov x0, x19
    mov x8, #57
    svc #0
    ldp x29, x30, [sp], #16
    ret
file_read_error:
    adr x1, file_unavailable
    mov x2, #file_unavailable_len
    bl write_stdout
    ldp x29, x30, [sp], #16
    ret

// check_file: x1=path, prints accessible/unavailable; closes if opened
check_file:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x0, #-100
    mov x2, #0
    mov x8, #56
    svc #0
    cmp x0, #0
    blt 5f
    mov x19, x0
    adr x1, accessible
    mov x2, #accessible_len
    bl write_stdout
    mov x0, x19
    mov x8, #57
    svc #0
    ldp x29, x30, [sp], #16
    ret
5:
    adr x1, unavailable
    mov x2, #unavailable_len
    bl write_stdout
    ldp x29, x30, [sp], #16
    ret

// report writes use x19 as fd
write_report:
    mov x0, x19
    mov x8, #64
    svc #0
    ret
write_report_field:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x3, x1
    mov x4, x2
6:
    cbz x4, 7f
    ldrb w5, [x3]
    cbz w5, 7f
    add x3, x3, #1
    sub x4, x4, #1
    b 6b
7:
    sub x2, x3, x1
    bl write_report
    adr x1, newline
    mov x2, #1
    bl write_report
    ldp x29, x30, [sp], #16
    ret

// prints unsigned x0 as decimal using stack buffer
print_u64:
    sub sp, sp, #48
    mov x1, sp
    add x1, x1, #40
    mov w2, #10
    mov x3, x0
    cbnz x3, 8f
    sub x1, x1, #1
    mov w4, #'0'
    strb w4, [x1]
    b 10f
8:
    udiv x4, x3, x2
    msub x5, x4, x2, x3
    add w5, w5, #'0'
    sub x1, x1, #1
    strb w5, [x1]
    mov x3, x4
    cbnz x3, 8b
10:
    add x2, sp, #40
    sub x2, x2, x1
    mov x0, #1
    mov x8, #64
    svc #0
    add sp, sp, #48
    ret

pause_enter:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    adr x1, press_enter
    mov x2, #press_enter_len
    bl write_stdout
    // Read one line from stdin; preserve return address across write_stdout.
    mov x0, #0
    adr x1, input_buf
    mov x2, #32
    mov x8, #63
    svc #0
    ldp x29, x30, [sp], #16
    ret

finish_module:
    bl pause_enter
    b menu_loop

exit_program:
    adr x1, goodbye
    mov x2, #goodbye_len
    bl write_stdout
    mov x0, #0
    mov x8, #93
    svc #0

.section .rodata
clear_screen: .ascii "\033[2J\033[H"
.set clear_screen_len, . - clear_screen
banner:
    .ascii "\033[1;32m"
    .ascii "  ____  _   _ ____   ____ _   _ ____  \n"
    .ascii " / ___|| | | / ___| / ___| | | |  _ \\n"
    .ascii " \\___ \\| | | \\___ \\| |   | | | | |_) |\n"
    .ascii "  ___) | |_| |___) | |___| |_| |  __/ \n"
    .ascii " |____/ \\__, |____/ \\____|\\__,_|_|    \n"
    .ascii "         |___/                            \n"
    .ascii "\033[0m  SYS GUARD ASM | AArch64 / Android\n"
    .ascii "------------------------------------------\n"
    .ascii " [1] System Info\n"
    .ascii " [2] Process Monitor (self status)\n"
    .ascii " [3] Permission Audit\n"
    .ascii " [4] Save System Report\n"
    .ascii " [0] Exit\n"
    .ascii " Select: "
banner_end:
.set banner_len, banner_end - banner
system_title: .ascii "\n\033[1;32m[ SYSTEM INFORMATION ]\033[0m\n"
.set system_title_len, . - system_title
process_title: .ascii "\n\033[1;32m[ PROCESS MONITOR: CURRENT PROCESS ]\033[0m\n"
.set process_title_len, . - process_title
audit_title: .ascii "\n\033[1;32m[ LOCAL PERMISSION AUDIT ]\033[0m\n"
.set audit_title_len, . - audit_title
report_title: .ascii "\n[REPORT] Saving sysguard-report.txt...\n"
.set report_title_len, . - report_title
label_kernel: .ascii "Kernel: "
.set label_kernel_len, . - label_kernel
label_node: .ascii "Node: "
.set label_node_len, . - label_node
label_release: .ascii "Release: "
.set label_release_len, . - label_release
label_version: .ascii "Version: "
.set label_version_len, . - label_version
label_arch: .ascii "Architecture: "
.set label_arch_len, . - label_arch
label_pid: .ascii "PID: "
.set label_pid_len, . - label_pid
newline: .ascii "\n"
.set newline_len, . - newline
err_uname: .ascii "[!] uname syscall failed.\n"
.set err_uname_len, . - err_uname
invalid_msg: .ascii "\n[!] Invalid option.\n"
.set invalid_msg_len, . - invalid_msg
press_enter: .ascii "\nPress Enter to return to menu..."
.set press_enter_len, . - press_enter
goodbye: .ascii "\n\033[1;32mSysGuard closed. Stay safe.\033[0m\n"
.set goodbye_len, . - goodbye
file_unavailable: .ascii "[!] File unavailable or access denied.\n"
.set file_unavailable_len, . - file_unavailable
accessible: .ascii "ACCESSIBLE\n"
.set accessible_len, . - accessible
unavailable: .ascii "NOT ACCESSIBLE\n"
.set unavailable_len, . - unavailable
audit_status_label: .ascii "/proc/self/status: "
.set audit_status_label_len, . - audit_status_label
audit_mem_label: .ascii "/proc/meminfo: "
.set audit_mem_label_len, . - audit_mem_label
audit_route_label: .ascii "/proc/net/route: "
.set audit_route_label_len, . - audit_route_label
audit_note: .ascii "\nNote: results reflect this Termux app's permissions only.\n"
.set audit_note_len, . - audit_note
report_header: .ascii "SYS GUARD ASM - SYSTEM REPORT\n=============================\n"
.set report_header_len, . - report_header
report_kernel: .ascii "Kernel: "
.set report_kernel_len, . - report_kernel
report_release: .ascii "Release: "
.set report_release_len, . - report_release
report_arch: .ascii "Architecture: "
.set report_arch_len, . - report_arch
report_ok: .ascii "[+] Report saved to sysguard-report.txt\n"
.set report_ok_len, . - report_ok
report_fail: .ascii "[!] Could not create report file.\n"
.set report_fail_len, . - report_fail
proc_status_path: .asciz "/proc/self/status"
proc_meminfo_path: .asciz "/proc/meminfo"
proc_route_path: .asciz "/proc/net/route"
report_path: .asciz "sysguard-report.txt"

.section .bss
.balign 16
input_buf: .skip 32
uts_buf: .skip 390
file_buf: .skip 1024
