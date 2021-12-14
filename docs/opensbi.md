# OpenSBI 

Currently the system can run on QEMU 5.2.0 with OpenSBI v0.8, which has a Runtime SBI Version 0.2.

So the OpenSBI interface will be based on SBI 0.2 standard.

Document of SBI standard is listed [here](https://github.com/riscv-non-isa/riscv-sbi-doc/blob/master/riscv-sbi.adoc)


## Binary Encoding
An `ECALL` is used as the control transfer instruction instead of a `CALL` instruction.

`a7` (or `t0` on RV32E-based systems) encodes the SBI extension ID (EID), which matches how the system call ID is encoded in Linux system call ABI.

Many SBI extensions also chose to encode an additional SBI function ID (FID) in `a6`. This allows SBI extensions to encode multiple functions within the space of a single extension.

In the name of compatibility, SBI extension IDs (EIDs) and SBI function IDs (FIDs) are encoded as signed 32-bit integers. When passed in registers these follow the standard RISC-V calling convention rules.