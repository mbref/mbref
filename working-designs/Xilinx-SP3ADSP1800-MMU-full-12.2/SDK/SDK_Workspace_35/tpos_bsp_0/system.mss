
 PARAMETER VERSION = 2.2.0


BEGIN OS
 PARAMETER OS_NAME = tpos
 PARAMETER OS_VER = 1.00.a
 PARAMETER PROC_INSTANCE = microblaze_0
 PARAMETER STDIN = xps_uart_0
 PARAMETER STDOUT = xps_uart_0
 PARAMETER BOARD_NAME = sp3adsp1800
 PARAMETER LINUX_BOOTARGS = console=ttyS0,115200 debug
 PARAMETER PERIPH_TYPE_OVERRIDES = {hard-reset-gpios xps_gpio_0 0 1} {led heartbeat xps_gpio_3 0 1} {led green-1 xps_gpio_3 1 1} {led green-2 xps_gpio_3 2 1} {led green-3 xps_gpio_3 3 1} {led green-4 xps_gpio_3 4 1} {led green-5 xps_gpio_3 5 1} {led green-6 xps_gpio_3 6 1} {led green-7 xps_gpio_3 7 1}
 PARAMETER ETHERNET = xps_ether_0
 PARAMETER GPIO = xps_gpio_3
 PARAMETER FLASH_MEMORY = xps_mch_emc_0
 PARAMETER MAIN_MEMORY = mpmc_0
 PARAMETER LMB_MEMORY = dlmb_cntlr
 PARAMETER INTC = xps_intc_0
 PARAMETER TIMER = xps_timer_0
END


BEGIN PROCESSOR
 PARAMETER DRIVER_NAME = cpu
 PARAMETER DRIVER_VER = 1.12.b
 PARAMETER HW_INSTANCE = microblaze_0
END


BEGIN DRIVER
 PARAMETER DRIVER_NAME = bram
 PARAMETER DRIVER_VER = 2.00.a
 PARAMETER HW_INSTANCE = dlmb_cntlr
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = bram
 PARAMETER DRIVER_VER = 2.00.a
 PARAMETER HW_INSTANCE = ilmb_cntlr
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = uartlite
 PARAMETER DRIVER_VER = 2.00.a
 PARAMETER HW_INSTANCE = mdm_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = mpmc
 PARAMETER DRIVER_VER = 4.00.a
 PARAMETER HW_INSTANCE = mpmc_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = lltemac
 PARAMETER DRIVER_VER = 3.00.a
 PARAMETER HW_INSTANCE = xps_ether_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = gpio
 PARAMETER DRIVER_VER = 3.00.a
 PARAMETER HW_INSTANCE = xps_gpio_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = gpio
 PARAMETER DRIVER_VER = 3.00.a
 PARAMETER HW_INSTANCE = xps_gpio_1
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = gpio
 PARAMETER DRIVER_VER = 3.00.a
 PARAMETER HW_INSTANCE = xps_gpio_2
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = gpio
 PARAMETER DRIVER_VER = 3.00.a
 PARAMETER HW_INSTANCE = xps_gpio_3
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = intc
 PARAMETER DRIVER_VER = 2.01.a
 PARAMETER HW_INSTANCE = xps_intc_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = emc
 PARAMETER DRIVER_VER = 3.00.a
 PARAMETER HW_INSTANCE = xps_mch_emc_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = tmrctr
 PARAMETER DRIVER_VER = 2.00.a
 PARAMETER HW_INSTANCE = xps_timer_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = uartns550
 PARAMETER DRIVER_VER = 2.00.a
 PARAMETER HW_INSTANCE = xps_uart_0
END


