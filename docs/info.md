## How it works

This is a minimalist RISC-V SoC (System-on-Chip) designed to fit within a small area (1x2 tiles) on the SkyWater 130nm process.

The core architecture is based on **RV32E** (Reduced Register File - 16 registers) to save area. It features:

1.  **CPU Core:** A custom multi-cycle RISC-V core implementing the RV32E instruction set.
2.  **XIP Controller:** An SPI Execute-In-Place controller that fetches instructions directly from external Flash memory.
3.  **Internal RAM:** 128 Bytes of synthesized Distributed RAM for stack and data storage.
4.  **Peripherals:**
    * **GPIO:** Mapped to address `0x40000000`. Supports basic LED output.
    * **UART TX:** Mapped to address `0x40000008` (Software bit-banging assisted).

The system clock runs at 50MHz. On reset, the CPU fetches the first instruction from the external SPI Flash at address `0x00000000`.

## How to test

To test this SoC, you need the Tiny Tapeout Demo Board with the standard QSPI Flash populated.

1.  **Firmware:** Flash the provided RISC-V firmware binary onto the QSPI Flash chip. The firmware should perform a simple counter loop and write to the GPIO outputs.
2.  **Connections:**
    * Connect LEDs to the output pins `uo[4]` to `uo[7]`.
    * Ensure the SPI Flash is connected to `uo[0]` (MOSI), `uo[1]` (CS), `uo[2]` (SCK), and `ui[0]` (MISO).
3.  **Operation:**
    * Apply power and clock.
    * Assert Reset (`rst_n` low), then release it (`rst_n` high).
    * Observe the LEDs connected to `uo[4:7]`. They should count up or display the pattern defined in the firmware.

## External hardware

* Standard Tiny Tapeout Demo Board.
* QSPI Flash Memory (containing the RISC-V machine code).
* LEDs or Logic Analyzer on GPIO outputs.

