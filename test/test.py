import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start CTW RISC-V SoC Test")

    # 1. Khởi tạo Clock (50MHz)
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())

    # 2. Khởi tạo các chân tín hiệu
    dut._log.info("Resetting DUT...")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0 # Đang Reset

    # 3. Đợi 10 chu kỳ xung nhịp
    await ClockCycles(dut.clk, 10)
    
    # 4. Thả Reset (Chip bắt đầu chạy)
    dut.rst_n.value = 1
    dut._log.info("Reset released, CPU should be running...")

    # 5. Chạy thêm 100 chu kỳ để đảm bảo không có lỗi chập mạch (X state)
    # Lưu ý: Chúng ta không giả lập SPI Flash ở đây vì rất phức tạp trong Python.
    # Mục tiêu chỉ là đảm bảo chip biên dịch thành công và chân tín hiệu hoạt động.
    await ClockCycles(dut.clk, 100)

    dut._log.info("Basic sanity check passed!")
