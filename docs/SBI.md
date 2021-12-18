# OpenSBI 

Currently the system can run on QEMU 6.2.0 with OpenSBI v0.9, which has a Runtime SBI Version 0.3.

So the OpenSBI interface will be based on SBI 0.3 standard.

Document of SBI standard is listed [here](https://github.com/riscv-non-isa/riscv-sbi-doc/blob/master/riscv-sbi.adoc)


## Binary Encoding
An `ECALL` is used as the control transfer instruction instead of a `CALL` instruction.

`a7` (or `t0` on RV32E-based systems) encodes the SBI extension ID (EID), which matches how the system call ID is encoded in Linux system call ABI.

Many SBI extensions also chose to encode an additional SBI function ID (FID) in `a6`. This allows SBI extensions to encode multiple functions within the space of a single extension.

In the name of compatibility, SBI extension IDs (EIDs) and SBI function IDs (FIDs) are encoded as signed 32-bit integers. When passed in registers these follow the standard RISC-V calling convention rules.

## Function Listing

### 5. Timer Extension (EID #0x54494D45 "TIME")

This replaces legacy timer extension (EID #0x00). It follows the new calling convention defined in v0.2.

#### 5.1. Function: Set Timer (FID #0)

sets the next clock interrupt time, accept a uint64_t as the next time.

**attension**: the next interrupt time in meant to be larger then current cpu time, usually read by assembly `rdtime`.

```
struct sbiret sbi_set_timer(uint64_t stime_value)
```

### 9. System Reset Extension (EID #0x53525354 "SRST")

#### 9.1. Function: System reset (FID #0)

**attension**: requires SBI v0.3

```
struct sbiret sbi_system_reset(uint32_t reset_type, uint32_t reset_reason)
```

we use reset_type 0 for shutdown and reset_reason 0 for no reason in this project.

reset_type and reset_reason see [sbi-doc table 26](https://github.com/riscv-non-isa/riscv-sbi-doc/blob/master/riscv-sbi.adoc#table_srst_system_reset_types) and [sbi-doc table 27](https://github.com/riscv-non-isa/riscv-sbi-doc/blob/master/riscv-sbi.adoc#table_srst_system_reset_reasons)