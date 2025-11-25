SHELL=/bin/bash
MAKEFLAGS+=--no-print-directory

# CONFIGURATION
SIM ?= icarus
TOPLEVEL_LANG = verilog

# SOURCE FILES
# Chỉ đường dẫn đến các file nguồn trong thư mục src
VERILOG_SOURCES += $(PWD)/../src/tt_um_ctw_riscv_soc.v
VERILOG_SOURCES += $(PWD)/../src/simple_cpu.v
VERILOG_SOURCES += $(PWD)/../src/spi_xip.v

# MODULE CONFIG
# Tên module Top-level của bạn (phải trùng khớp với trong file Verilog)
TOPLEVEL = tt_um_ctw_riscv_soc
# Tên file python test (không có đuôi .py)
MODULE = test

# Include Cocotb makefile
include $(shell cocotb-config --makefiles)/Makefile.sim
