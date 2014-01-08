
 PARAMETER VERSION = 2.2.0


BEGIN OS
 PARAMETER OS_NAME = tpos
 PARAMETER OS_VER = 1.00.a
 PARAMETER PROC_INSTANCE = microblaze_0
 PARAMETER STDIN = axi_uart_0
 PARAMETER STDOUT = axi_uart_0
 PARAMETER INTC = axi_intc_0
 PARAMETER TIMER = axi_timer_0
 PARAMETER LMB_MEMORY = dlmb_cntlr
 PARAMETER MAIN_MEMORY = axi_s6_ddrx_0
 PARAMETER FLASH_MEMORY = axi_emc_0
 PARAMETER ETHERNET = axi_ether_0
 PARAMETER GPIO = axi_gpio_0
 PARAMETER IIC = axi_iic_0
 PARAMETER XLBOOT_BOOT_COUNTER = 3
 PARAMETER XLBOOT_LOCBLOB_OFFSET = 0x1F80000
 PARAMETER PERIPH_TYPE_OVERRIDES = {hard-reset-gpios axi_gpio_0 0 1} {led heartbeat axi_gpio_3 0 1} {led red-1 axi_gpio_3 1 1} {led red-2 axi_gpio_3 2 1} {led red-3 axi_gpio_3 3 1} {led red-4 axi_gpio_3 4 1} {led red-5 axi_gpio_3 5 1} {led red-6 axi_gpio_3 6 1} {led red-7 axi_gpio_3 7 1} {phy axi_ether_0 1 natsemi,dp83865} {rtc-iic axi_iic_0 0x68 dallas,ds3232 fpga_0_RTC_Int_pin} {compatible -append mbref_reg_0 generic-uio} {compatible -append mbref_mio_0 generic-uio}
 PARAMETER LINUX_BOOTARGS = console=ttyUL0,115200 ubi.mtd=2 root=ubi0:root rootfstype=ubifs rw mtdparts=ae000000.flash:16384k(bpi),4096k(kernel),11776k(rootfs),384k(u-boot-xl)ro,128k(env) debug
 PARAMETER BOARD_NAME = s6lx150t
 PARAMETER GENERIC_UIO_LIST = (mbref_mio_0,mbref_reg_0)
END


BEGIN PROCESSOR
 PARAMETER DRIVER_NAME = cpu
 PARAMETER DRIVER_VER = 1.13.a
 PARAMETER HW_INSTANCE = microblaze_0
END


BEGIN DRIVER
 PARAMETER DRIVER_NAME = emc
 PARAMETER DRIVER_VER = 3.01.a
 PARAMETER HW_INSTANCE = axi_emc_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = emaclite
 PARAMETER DRIVER_VER = 3.01.a
 PARAMETER HW_INSTANCE = axi_ether_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = gpio
 PARAMETER DRIVER_VER = 3.00.a
 PARAMETER HW_INSTANCE = axi_gpio_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = gpio
 PARAMETER DRIVER_VER = 3.00.a
 PARAMETER HW_INSTANCE = axi_gpio_1
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = gpio
 PARAMETER DRIVER_VER = 3.00.a
 PARAMETER HW_INSTANCE = axi_gpio_2
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = gpio
 PARAMETER DRIVER_VER = 3.00.a
 PARAMETER HW_INSTANCE = axi_gpio_3
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = iic
 PARAMETER DRIVER_VER = 2.03.a
 PARAMETER HW_INSTANCE = axi_iic_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = intc
 PARAMETER DRIVER_VER = 2.02.a
 PARAMETER HW_INSTANCE = axi_intc_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = s6_ddrx
 PARAMETER DRIVER_VER = 1.00.a
 PARAMETER HW_INSTANCE = axi_s6_ddrx_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = tmrctr
 PARAMETER DRIVER_VER = 2.03.a
 PARAMETER HW_INSTANCE = axi_timer_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = uartlite
 PARAMETER DRIVER_VER = 2.00.a
 PARAMETER HW_INSTANCE = axi_uart_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = uartlite
 PARAMETER DRIVER_VER = 2.00.a
 PARAMETER HW_INSTANCE = axi_uart_1
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
 PARAMETER DRIVER_NAME = axi_mbref_mio
 PARAMETER DRIVER_VER = 1.00.a
 PARAMETER HW_INSTANCE = mbref_mio_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = axi_mbref_reg
 PARAMETER DRIVER_VER = 1.00.a
 PARAMETER HW_INSTANCE = mbref_reg_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = uartlite
 PARAMETER DRIVER_VER = 2.00.a
 PARAMETER HW_INSTANCE = mdm_0
END


