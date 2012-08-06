
 PARAMETER VERSION = 2.2.0


BEGIN OS
 PARAMETER OS_NAME = tpos
 PARAMETER OS_VER = 1.00.a
 PARAMETER PROC_INSTANCE = microblaze_0
 PARAMETER STDIN = axi_uart_0
 PARAMETER STDOUT = axi_uart_0
 PARAMETER BOARD_NAME = s6lx9
 PARAMETER ETHERNET = axi_ether_0
 PARAMETER GPIO = axi_gpio_3
 PARAMETER SPI = axi_spi_0
 PARAMETER LMB_MEMORY = dlmb_cntlr
 PARAMETER MAIN_MEMORY = axi_s6_ddrx_0
 PARAMETER FLASH_MEMORY = axi_spi_0
 PARAMETER INTC = axi_intc_0
 PARAMETER TIMER = axi_timer_0
 PARAMETER PERIPH_TYPE_OVERRIDES = {led heartbeat axi_gpio_3 0 1} {led red-1 axi_gpio_3 1 1} {led red-2 axi_gpio_3 2 1} {led red-3 axi_gpio_3 3 1} {phy-mdio axi_ether_0 natsemi,dp83848 30} {flash-spi axi_spi_0 micron,n25q128 0}
 PARAMETER LINUX_BOOTARGS = console=ttyUL0,115200 mtdparts=spi32766.0:16384k(all)ro debug
 PARAMETER XLBOOT_BOOT_COUNTER = 3
 PARAMETER XLBOOT_LOCBLOB_OFFSET = 0xF80000
END


BEGIN PROCESSOR
 PARAMETER DRIVER_NAME = cpu
 PARAMETER DRIVER_VER = 1.13.a
 PARAMETER HW_INSTANCE = microblaze_0
END


BEGIN DRIVER
 PARAMETER DRIVER_NAME = emaclite
 PARAMETER DRIVER_VER = 3.01.a
 PARAMETER HW_INSTANCE = axi_ether_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = gpio
 PARAMETER DRIVER_VER = 3.00.a
 PARAMETER HW_INSTANCE = axi_gpio_3
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = s6_ddrx
 PARAMETER DRIVER_VER = 1.00.a
 PARAMETER HW_INSTANCE = axi_s6_ddrx_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = spi
 PARAMETER DRIVER_VER = 3.02.a
 PARAMETER HW_INSTANCE = axi_spi_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = uartlite
 PARAMETER DRIVER_VER = 2.00.a
 PARAMETER HW_INSTANCE = axi_uart_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = tmrctr
 PARAMETER DRIVER_VER = 2.03.a
 PARAMETER HW_INSTANCE = axi_timer_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = bram
 PARAMETER DRIVER_VER = 3.00.a
 PARAMETER HW_INSTANCE = dlmb_cntlr
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = bram
 PARAMETER DRIVER_VER = 3.00.a
 PARAMETER HW_INSTANCE = ilmb_cntlr
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = intc
 PARAMETER DRIVER_VER = 2.02.a
 PARAMETER HW_INSTANCE = axi_intc_0
END


