![](../../workflows/gds/badge.svg)

# CTW RISC-V SoC (Minimalist)

A minimalist 32-bit RISC-V System-on-Chip (SoC) designed for [Tiny Tapeout 09](https://tinytapeout.com).

This project implements a simplified RISC-V core capable of executing basic instructions, targeting a 4x2 tile configuration.

### 🔍 [View 3D Model & GDS Layout](https://gds-viewer.tinytapeout.com/?model=https://trantai200701-eng.github.io/tt09-riscv-soc/tinytapeout.oas&pdk=sky130A)

---

## Project Description

This SoC is designed to demonstrate a functional RISC-V core within the resource constraints of the Tiny Tapeout shuttle. The design focuses on:

* **Architecture:** 32-bit RISC-V (RV32I Base Integer Instruction Set - Subset).
* **Design Type:** Digital Logic / SoC.
* **Tile Size:** 4x2 Tiles (Standard Tiny Tapeout Grid).
* **Process:** 130nm.

## How it works

The core fetches instructions from memory, decodes them, and executes arithmetic, logic, and control flow operations. It communicates with the outside world via the Tiny Tapeout I/O interface.

## Pinout / I/O Map

| Pin Name | Direction | Description |
| :--- | :--- | :--- |
| `clk` | Input | System Clock |
| `rst_n` | Input | System Reset (Active Low) |
| `ui_in[7:0]` | Input | General Purpose Inputs / Data In |
| `uio_in[7:0]` | Input | Bidirectional I/O (Input path) |
| `uo_out[7:0]` | Output | General Purpose Outputs / Data Out |
| `uio_out[7:0]` | Output | Bidirectional I/O (Output path) |
| `uio_oe[7:0]` | Output | Output Enable for Bidirectional I/O |

---

## Simulation & Testing

To run the simulation and verify the design logic:

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/trantai200701-eng/tt09-riscv-soc.git](https://github.com/trantai200701-eng/tt09-riscv-soc.git)
    cd tt09-riscv-soc
    ```

2.  **Run the test (GitHub Actions):**
    The project includes automated tests configured in `.github/workflows/test.yaml`. Check the "Actions" tab to see the latest test results.

---

### License

This project is licensed under [Apache 2.0](LICENSE).
