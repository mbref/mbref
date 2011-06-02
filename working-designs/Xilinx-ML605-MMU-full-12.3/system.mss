
 PARAMETER VERSION = 2.2.0


BEGIN OS
 PARAMETER OS_NAME = tpos
 PARAMETER OS_VER = 1.00.a
 PARAMETER PROC_INSTANCE = microblaze_0
 PARAMETER stdin = xps_uart_0
 PARAMETER stdout = xps_uart_0
 PARAMETER intc = xps_intc_0
 PARAMETER timer = xps_timer_0
 PARAMETER lmb_memory = dlmb_cntlr
 PARAMETER main_memory = mpmc_0
 PARAMETER flash_memory = xps_mch_emc_0
 PARAMETER sysace = xps_sysace_0
 PARAMETER ethernet = xps_ether_0
 PARAMETER gpio = xps_gpio_3
 PARAMETER linux_bootargs = console=ttyS0,115200 root=/dev/mtdblock2 rw rootfstype=jffs2 mtdparts=ae000000.flash:16384k(bpi),4096k(kernel),11776k(rootfs),384k(u-boot-xl)ro,128k(env) debug
 PARAMETER board_name = ml605
 PARAMETER periph_type_overrides = {hard-reset-gpios xps_gpio_0 0 1} {led heartbeat xps_gpio_3 0 1} {led green-1 xps_gpio_3 1 1} {led green-2 xps_gpio_3 2 1} {led green-3 xps_gpio_3 3 1} {led green-4 xps_gpio_3 4 1} {led green-5 xps_gpio_3 5 1} {led green-6 xps_gpio_3 6 1} {led green-7 xps_gpio_3 7 1}
 PARAMETER xlboot_boot_counter = 3
 PARAMETER xlboot_locblob_offset = 0x1F80000
 PARAMETER iic = xps_iic_0
 PARAMETER microblaze_exception_vectors = ((XEXC_NONE,XNullHandler,0),(XEXC_NONE,XNullHandler,0),(XEXC_NONE,XNullHandler,0),(XEXC_NONE,XNullHandler,0),(XEXC_NONE,XNullHandler,0),(XEXC_NONE,XNullHandler,0),(XEXC_NONE,XNullHandler,0),(XEXC_NONE,XNullHandler,0))
END


BEGIN PROCESSOR
 PARAMETER DRIVER_NAME = cpu
 PARAMETER DRIVER_VER = 1.13.a
 PARAMETER HW_INSTANCE = microblaze_0
 PARAMETER COMPILER = mb-gcc
 PARAMETER ARCHIVER = mb-ar
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
 PARAMETER DRIVER_NAME = generic
 PARAMETER DRIVER_VER = 1.00.a
 PARAMETER HW_INSTANCE = lmb_bram
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = gpio
 PARAMETER DRIVER_VER = 3.00.a
 PARAMETER HW_INSTANCE = xps_gpio_3
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = gpio
 PARAMETER DRIVER_VER = 3.00.a
 PARAMETER HW_INSTANCE = xps_gpio_4
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
 PARAMETER DRIVER_NAME = emc
 PARAMETER DRIVER_VER = 3.01.a
 PARAMETER HW_INSTANCE = xps_mch_emc_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = pcie
 PARAMETER DRIVER_VER = 4.01.a
 PARAMETER HW_INSTANCE = PCIe_Bridge
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = mpmc
 PARAMETER DRIVER_VER = 4.01.a
 PARAMETER HW_INSTANCE = mpmc_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = sysace
 PARAMETER DRIVER_VER = 2.00.a
 PARAMETER HW_INSTANCE = xps_sysace_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = lltemac
 PARAMETER DRIVER_VER = 3.00.a
 PARAMETER HW_INSTANCE = xps_ether_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = tmrctr
 PARAMETER DRIVER_VER = 2.01.a
 PARAMETER HW_INSTANCE = xps_timer_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = uartns550
 PARAMETER DRIVER_VER = 2.00.a
 PARAMETER HW_INSTANCE = xps_uart_0
 PARAMETER CLOCK_HZ = 100000000
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = generic
 PARAMETER DRIVER_VER = 1.00.a
 PARAMETER HW_INSTANCE = xps_mch_emc_0_CE_inverter
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = generic
 PARAMETER DRIVER_VER = 1.00.a
 PARAMETER HW_INSTANCE = PCIe_Diff_Clk
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = dmacentral
 PARAMETER DRIVER_VER = 2.00.a
 PARAMETER HW_INSTANCE = xps_central_dma_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = generic
 PARAMETER DRIVER_VER = 1.00.a
 PARAMETER HW_INSTANCE = clock_generator_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = uartlite
 PARAMETER DRIVER_VER = 2.00.a
 PARAMETER HW_INSTANCE = mdm_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = generic
 PARAMETER DRIVER_VER = 1.00.a
 PARAMETER HW_INSTANCE = proc_sys_reset_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = intc
 PARAMETER DRIVER_VER = 2.01.a
 PARAMETER HW_INSTANCE = xps_intc_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = gpio
 PARAMETER DRIVER_VER = 3.00.a
 PARAMETER HW_INSTANCE = xps_gpio_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = iic
 PARAMETER DRIVER_VER = 2.01.a
 PARAMETER HW_INSTANCE = xps_iic_0
END


