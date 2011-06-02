-- ************************************************************************** --
-- *  PetaLinux based GigE Vision Reference Design                          * --
-- *------------------------------------------------------------------------* --
-- *  Module :  GVRD-TOP                                                    * --
-- *    File :  gvrd.vhd                                                    * --
-- *    Date :  2010-08-17                                                  * --
-- *     Rev :  0.1                                                         * --
-- *  Author :  JP                                                          * --
-- *------------------------------------------------------------------------* --
-- *  Top level of the GigE Vision camera reference design based on the     * --
-- *  ML505 board running PetaLinux operating system                        * --
-- *------------------------------------------------------------------------* --
-- *  0.1  |  2010-08-17  |  JP  |  Initial release                         * --
-- ************************************************************************** --

library ieee;
use     ieee.std_logic_1164.all;

library unisim;
use     unisim.vcomponents.all;


--------------------------------------------------------------------------------
--  GVRD-TOP entity
--------------------------------------------------------------------------------

entity gvrd is
    port   (fpga_0_xps_uart_0_sin_pin                   : in    std_logic;
            fpga_0_xps_sysace_0_sysace_clk_pin          : in    std_logic;
            fpga_0_xps_sysace_0_sysace_mpirq_pin        : in    std_logic;
            fpga_0_clk_1_sys_clk_pin                    : in    std_logic;
            fpga_0_rst_1_sys_rst_pin                    : in    std_logic;
            fpga_0_xps_gpio_3_gpio_io_pin               : inout std_logic_vector( 0     to  7);
            fpga_0_xps_gpio_4_gpio_io_pin               : inout std_logic_vector( 0     to  4);
            fpga_0_xps_gpio_1_gpio_io_pin               : inout std_logic_vector( 0     to  4);
            fpga_0_xps_gpio_2_gpio_io_pin               : inout std_logic_vector( 0     to  7);
            fpga_0_xps_sysace_0_sysace_mpd_pin          : inout std_logic_vector(15 downto  0);
            fpga_0_xps_mch_emc_0_mem_dq_pin             : inout std_logic_vector( 0     to 15);
            fpga_0_mpmc_0_ddr2_dq_pin                   : inout std_logic_vector(63 downto  0);
            fpga_0_mpmc_0_ddr2_dqs_pin                  : inout std_logic_vector( 7 downto  0);
            fpga_0_mpmc_0_ddr2_dqs_n_pin                : inout std_logic_vector( 7 downto  0);
            fpga_0_xps_uart_0_sout_pin                  : out   std_logic;
            fpga_0_xps_sysace_0_sysace_mpa_pin          : out   std_logic_vector( 6 downto  0);
            fpga_0_xps_sysace_0_sysace_cen_pin          : out   std_logic;
            fpga_0_xps_sysace_0_sysace_oen_pin          : out   std_logic;
            fpga_0_xps_sysace_0_sysace_wen_pin          : out   std_logic;
            fpga_0_xps_mch_emc_0_mem_a_pin              : out   std_logic_vector( 7     to 30);
            fpga_0_xps_mch_emc_0_mem_cen_pin            : out   std_logic;
            fpga_0_xps_mch_emc_0_mem_oen_pin            : out   std_logic;
            fpga_0_xps_mch_emc_0_mem_wen_pin            : out   std_logic;
            fpga_0_xps_mch_emc_0_mem_adv_ldn_pin        : out   std_logic;
            fpga_0_mpmc_0_ddr2_clk_pin                  : out   std_logic_vector( 1 downto  0);
            fpga_0_mpmc_0_ddr2_clk_n_pin                : out   std_logic_vector( 1 downto  0);
            fpga_0_mpmc_0_ddr2_ce_pin                   : out   std_logic_vector( 1 downto  0);
            fpga_0_mpmc_0_ddr2_cs_n_pin                 : out   std_logic_vector( 1 downto  0);
            fpga_0_mpmc_0_ddr2_odt_pin                  : out   std_logic_vector( 1 downto  0);
            fpga_0_mpmc_0_ddr2_ras_n_pin                : out   std_logic;
            fpga_0_mpmc_0_ddr2_cas_n_pin                : out   std_logic;
            fpga_0_mpmc_0_ddr2_we_n_pin                 : out   std_logic;
            fpga_0_mpmc_0_ddr2_bankaddr_pin             : out   std_logic_vector( 1 downto  0);
            fpga_0_mpmc_0_ddr2_addr_pin                 : out   std_logic_vector(12 downto  0);
            fpga_0_mpmc_0_ddr2_dm_pin                   : out   std_logic_vector( 7 downto  0);
            -- I2C BUS
            i2c_scl                                     : out   std_logic;
            i2c_sda                                     : inout std_logic;
            -- Ethernet GMII PHY
            phy_rst_n                                   : out   std_logic;
            phy_gmii_col                                : in    std_logic;
            phy_gmii_crs                                : in    std_logic;
            phy_gmii_rx_clk                             : in    std_logic;
            phy_gmii_rx_dv                              : in    std_logic;
            phy_gmii_rx_er                              : in    std_logic;
            phy_gmii_rxd                                : in    std_logic_vector( 7 downto 0);
            phy_mii_tx_clk                              : in    std_logic;
            phy_gmii_tx_clk                             : out   std_logic;
            phy_gmii_tx_en                              : out   std_logic;
            phy_gmii_tx_er                              : out   std_logic;
            phy_gmii_txd                                : out   std_logic_vector( 7 downto 0);
            phy_mdc                                     : out   std_logic;
            phy_mdio                                    : inout std_logic);
end gvrd;


--------------------------------------------------------------------------------
--  GVRD-TOP architecture
--------------------------------------------------------------------------------

architecture top of gvrd is

    -- Components --------------------------------------------------------------

    -- Microblaze CPU
    component system
        port   (fpga_0_xps_uart_0_sin_pin               : in    std_logic;
                fpga_0_xps_sysace_0_sysace_clk_pin      : in    std_logic;
                fpga_0_xps_sysace_0_sysace_mpirq_pin    : in    std_logic;
                fpga_0_clk_1_sys_clk_pin                : in    std_logic;
                fpga_0_rst_1_sys_rst_pin                : in    std_logic;
                fpga_0_xps_gpio_3_gpio_io_pin           : inout std_logic_vector( 0     to  7);
                fpga_0_xps_gpio_4_gpio_io_pin           : inout std_logic_vector( 0     to  4);
                fpga_0_xps_gpio_1_gpio_io_pin           : inout std_logic_vector( 0     to  4);
                fpga_0_xps_gpio_2_gpio_io_pin           : inout std_logic_vector( 0     to  7);
                fpga_0_xps_sysace_0_sysace_mpd_pin      : inout std_logic_vector(15 downto  0);
                fpga_0_xps_mch_emc_0_mem_dq_pin         : inout std_logic_vector( 0     to 15);
                fpga_0_mpmc_0_ddr2_dq_pin               : inout std_logic_vector(63 downto  0);
                fpga_0_mpmc_0_ddr2_dqs_pin              : inout std_logic_vector( 7 downto  0);
                fpga_0_mpmc_0_ddr2_dqs_n_pin            : inout std_logic_vector( 7 downto  0);
                fpga_0_xps_uart_0_sout_pin              : out   std_logic;
                fpga_0_xps_sysace_0_sysace_mpa_pin      : out   std_logic_vector( 6 downto  0);
                fpga_0_xps_sysace_0_sysace_cen_pin      : out   std_logic;
                fpga_0_xps_sysace_0_sysace_oen_pin      : out   std_logic;
                fpga_0_xps_sysace_0_sysace_wen_pin      : out   std_logic;
                fpga_0_xps_mch_emc_0_mem_a_pin          : out   std_logic_vector( 7     to 30);
                fpga_0_xps_mch_emc_0_mem_cen_pin        : out   std_logic;
                fpga_0_xps_mch_emc_0_mem_oen_pin        : out   std_logic;
                fpga_0_xps_mch_emc_0_mem_wen_pin        : out   std_logic;
                fpga_0_xps_mch_emc_0_mem_adv_ldn_pin    : out   std_logic;
                fpga_0_mpmc_0_ddr2_clk_pin              : out   std_logic_vector( 1 downto  0);
                fpga_0_mpmc_0_ddr2_clk_n_pin            : out   std_logic_vector( 1 downto  0);
                fpga_0_mpmc_0_ddr2_ce_pin               : out   std_logic_vector( 1 downto  0);
                fpga_0_mpmc_0_ddr2_cs_n_pin             : out   std_logic_vector( 1 downto  0);
                fpga_0_mpmc_0_ddr2_odt_pin              : out   std_logic_vector( 1 downto  0);
                fpga_0_mpmc_0_ddr2_ras_n_pin            : out   std_logic;
                fpga_0_mpmc_0_ddr2_cas_n_pin            : out   std_logic;
                fpga_0_mpmc_0_ddr2_we_n_pin             : out   std_logic;
                fpga_0_mpmc_0_ddr2_bankaddr_pin         : out   std_logic_vector( 1 downto  0);
                fpga_0_mpmc_0_ddr2_addr_pin             : out   std_logic_vector(12 downto  0);
                fpga_0_mpmc_0_ddr2_dm_pin               : out   std_logic_vector( 7 downto  0);
                -- System clock and reset
                sys_clk                                 : out   std_logic;
                sys_rst                                 : out   std_logic;
                sys_locked                              : out   std_logic;
                -- External peripheral controller
                epc_addr                                : out   std_logic_vector( 0     to 15);
                epc_wrdata                              : out   std_logic_vector( 0     to 31);
                epc_be                                  : out   std_logic_vector( 0     to  3);
                epc_cs_n                                : out   std_logic_vector( 0     to  1);
                epc_rnw                                 : out   std_logic;
                epc_rddata                              : in    std_logic_vector( 0     to 31);
                epc_rdy                                 : in    std_logic_vector( 0     to  1);
                -- Multi-port memory controller
                mpmc_initdone                           : out   std_logic;
                mpmc_addrack                            : out   std_logic;
                mpmc_addrreq                            : in    std_logic;
                mpmc_rnw                                : in    std_logic;
                mpmc_rdmodwr                            : in    std_logic;
                mpmc_size                               : in    std_logic_vector( 3 downto 0);
                mpmc_addr                               : in    std_logic_vector(31 downto 0);
                mpmc_wrfifo_almostfull                  : out   std_logic;
                mpmc_wrfifo_empty                       : out   std_logic;
                mpmc_wrfifo_flush                       : in    std_logic;
                mpmc_wrfifo_push                        : in    std_logic;
                mpmc_wrfifo_be                          : in    std_logic_vector( 3 downto 0);
                mpmc_wrfifo_data                        : in    std_logic_vector(31 downto 0);
                mpmc_rdfifo_empty                       : out   std_logic;
                mpmc_rdfifo_latency                     : out   std_logic_vector( 1 downto 0);
                mpmc_rdfifo_rdwdaddr                    : out   std_logic_vector( 3 downto 0);
                mpmc_rdfifo_data                        : out   std_logic_vector(31 downto 0);
                mpmc_rdfifo_flush                       : in    std_logic;
                mpmc_rdfifo_pop                         : in    std_logic;
                cpu_irq                                 : in    std_logic);
    end component system;

    -- Input video processor
    component video
        port (-- Global ports
              sys_clk           : in    std_logic;
              sys_rst           : in    std_logic;
              -- CPU interface
              epc_addr          : in    std_logic_vector(15 downto 0);
              epc_odata         : in    std_logic_vector(31 downto 0);
              epc_cs_n          : in    std_logic;
              epc_rnw           : in    std_logic;
              epc_idata         : out   std_logic_vector(31 downto 0);
              epc_rdy           : out   std_logic;
              -- Frame-buffer interface
              fb_clk            : in    std_logic;
              fb_frame          : out   std_logic;
              fb_dv             : out   std_logic;
              fb_data           : out   std_logic_vector(15 downto 0);
              fb_ptype          : out   std_logic_vector(31 downto 0);
              fb_size_x         : out   std_logic_vector(31 downto 0);
              fb_size_y         : out   std_logic_vector(31 downto 0);
              fb_offs_x         : out   std_logic_vector(31 downto 0);
              fb_offs_y         : out   std_logic_vector(31 downto 0);
              fb_pad_x          : out   std_logic_vector(15 downto 0);
              fb_pad_y          : out   std_logic_vector(15 downto 0));
    end component video;

    -- MPMC framebuffer
    component framebuf
        port (-- Global ports
              sys_rst           : in    std_logic;
              sys_net_up        : in    std_logic;
              sys_type          : in    std_logic_vector( 3 downto 0);
              sys_tstamp        : in    std_logic_vector(63 downto 0);
              -- Framebuffer CPU control
              sys_fb_bot        : in    std_logic_vector(31 downto 0);
              sys_fb_top        : in    std_logic_vector(31 downto 0);
              sys_fb_init       : in    std_logic;
              -- Data input interface
              din_clk           : in    std_logic;
              din_frame         : in    std_logic;
              din_dv            : in    std_logic;
              din_width         : in    std_logic_vector( 1 downto 0);
              din_data          : in    std_logic_vector(31 downto 0);
              din_ptype         : in    std_logic_vector(31 downto 0);
              din_size_x        : in    std_logic_vector(31 downto 0);
              din_size_y        : in    std_logic_vector(31 downto 0);
              din_offs_x        : in    std_logic_vector(31 downto 0);
              din_offs_y        : in    std_logic_vector(31 downto 0);
              din_pad_x         : in    std_logic_vector(15 downto 0);
              din_pad_y         : in    std_logic_vector(15 downto 0);
              -- Write control interface
              wr_rdbot          : in    std_logic_vector(31 downto 0);
              wr_d_start        : out   std_logic_vector(31 downto 0);
              wr_d_len          : out   std_logic_vector(23 downto 0);
              wr_d_hlen         : out   std_logic_vector( 3 downto 0);
              wr_d_type         : out   std_logic_vector( 3 downto 0);
              wr_d_we           : out   std_logic;
              -- Read control interface
              rd_idle           : out   std_logic;
              rd_rdbot          : out   std_logic_vector(31 downto 0);
              rd_rdlen          : out   std_logic_vector(23 downto 0);
              rd_prbot          : out   std_logic_vector(31 downto 0);
              rd_prlen          : out   std_logic_vector(23 downto 0);
              rd_d_start        : in    std_logic_vector(31 downto 0);
              rd_d_len          : in    std_logic_vector(23 downto 0);
              rd_d_hlen         : in    std_logic_vector( 3 downto 0);
              rd_d_type         : in    std_logic_vector( 3 downto 0);
              rd_d_we           : in    std_logic;
              -- GigE core data interface
              tx_full           : in    std_logic;
              tx_max_len        : in    std_logic_vector(15 downto 0);
              tx_write          : out   std_logic;
              tx_header         : out   std_logic;
              tx_data           : out   std_logic_vector(31 downto 0);
              -- GigE core packet resend interface
              rsnd_req          : in    std_logic;
              rsnd_bid          : in    std_logic_vector(15 downto 0);
              rsnd_pid_f        : in    std_logic_vector(23 downto 0);
              rsnd_pid_l        : in    std_logic_vector(23 downto 0);
              -- Multi-port memory controller
              mpmc_clk          : in    std_logic;
              mpmc_init_done    : in    std_logic;
              mpmc_addr_ack     : in    std_logic;
              mpmc_addr_req     : out   std_logic;
              mpmc_rnw          : out   std_logic;
              mpmc_rd_mod_wr    : out   std_logic;
              mpmc_size         : out   std_logic_vector( 3 downto 0);
              mpmc_addr         : out   std_logic_vector(31 downto 0);
              mpmc_wrfifo_afull : in    std_logic;
              mpmc_wrfifo_empty : in    std_logic;
              mpmc_wrfifo_flush : out   std_logic;
              mpmc_wrfifo_push  : out   std_logic;
              mpmc_wrfifo_be    : out   std_logic_vector( 3 downto 0);
              mpmc_wrfifo_data  : out   std_logic_vector(31 downto 0);
              mpmc_rdfifo_empty : in    std_logic;
              mpmc_rdfifo_lat   : in    std_logic_vector( 1 downto 0);
              mpmc_rdfifo_rdwa  : in    std_logic_vector( 3 downto 0);
              mpmc_rdfifo_data  : in    std_logic_vector(31 downto 0);
              mpmc_rdfifo_flush : out   std_logic;
              mpmc_rdfifo_pop   : out   std_logic);
    end component framebuf;

    -- GigE Vision core
    component gige
        port   (-- Global ports
                sys_rst                 : in    std_logic;
                sys_clk                 : in    std_logic;
                -- Common control signals
                sys_net_up              : out   std_logic;
                sys_uart_bypass         : out   std_logic;
                sys_gpo                 : out   std_logic_vector( 1 downto 0);
                sys_type                : out   std_logic_vector( 3 downto 0);
                sys_mac_addr            : out   std_logic_vector(47 downto 0);
                sys_time_stamp          : out   std_logic_vector(63 downto 0);
                -- MPMC framebuffer control ports
                sys_fb_init             : out   std_logic;
                sys_fb_bot              : out   std_logic_vector(31 downto 0);
                sys_fb_top              : out   std_logic_vector(31 downto 0);
                -- CPU interface
                cpu_addr                : in    std_logic_vector(15 downto 0);
                cpu_wrdata              : in    std_logic_vector(31 downto 0);
                cpu_be                  : in    std_logic_vector( 3 downto 0);
                cpu_cs_n                : in    std_logic;
                cpu_rnw                 : in    std_logic;
                cpu_rddata              : out   std_logic_vector(31 downto 0);
                cpu_rdy                 : out   std_logic;
                cpu_irq                 : out   std_logic;
                -- I2C bus
                i2c_scl                 : out   std_logic;
                i2c_sda_o               : out   std_logic;
                i2c_sda_i               : in    std_logic;
                -- SPI bus
                spi_clk                 : out   std_logic;
                spi_cs_n                : out   std_logic;
                spi_mosi                : out   std_logic;
                spi_miso                : in    std_logic;
                -- Memory controller interface
                mem_clk                 : in    std_logic;
                mem_data                : in    std_logic_vector(31 downto 0);
                mem_header              : in    std_logic;
                mem_write               : in    std_logic;
                mem_full                : out   std_logic;
                mem_max_len             : out   std_logic_vector(15 downto 0);
                rsnd_req                : out   std_logic;
                rsnd_blk_id             : out   std_logic_vector(15 downto 0);
                rsnd_first_pkt_id       : out   std_logic_vector(23 downto 0);
                rsnd_last_pkt_id        : out   std_logic_vector(23 downto 0);
                -- Data receiver output
                rx_stm_clk              : in    std_logic;
                rx_stm_data             : out   std_logic_vector(15 downto 0);
                rx_stm_be               : out   std_logic_vector( 1 downto 0);
                rx_stm_frame            : out   std_logic;
                rx_stm_blk_id           : out   std_logic_vector(15 downto 0);
                rx_stm_pkt_id           : out   std_logic_vector(23 downto 0);
                -- MAC host interface
                mac_host_req            : out   std_logic;
                mac_host_miimsel        : out   std_logic;
                mac_host_opcode         : out   std_logic_vector( 1 downto 0);
                mac_host_addr           : out   std_logic_vector( 9 downto 0);
                mac_host_wrdata         : out   std_logic_vector(31 downto 0);
                mac_host_rddata         : in    std_logic_vector(31 downto 0);
                mac_host_miimrdy        : in    std_logic;
                -- MAC TX interface
                mac_tx_clk              : in    std_logic;
                mac_tx_d                : out   std_logic_vector( 7 downto 0);
                mac_tx_dvld             : out   std_logic;
                mac_tx_firstbyte        : out   std_logic;
                mac_tx_underrun         : out   std_logic;
                mac_tx_ack              : in    std_logic;
                mac_tx_collision        : in    std_logic;
                mac_tx_retransmit       : in    std_logic;
                -- MAC RX interface
                mac_rx_clk              : in    std_logic;
                mac_rx_d                : in    std_logic_vector( 7 downto 0);
                mac_rx_dvld             : in    std_logic;
                mac_rx_goodframe        : in    std_logic;
                mac_rx_badframe         : in    std_logic;
                mac_rx_framedrop        : in    std_logic;
                -- PHY interface
                phy_rst_n               : out   std_logic);
    end component gige;

    -- Gigabit Ethernet MAC
    component mac
        port   (-- Common signals
                reset                   : in    std_logic;
                dcm_locked              : in    std_logic;
                mac_address             : in    std_logic_vector(47 downto 0);
                -- Receive client interface
                rx_clk                  : out   std_logic;
                rx_d                    : out   std_logic_vector( 7 downto 0);
                rx_dvld                 : out   std_logic;
                rx_goodframe            : out   std_logic;
                rx_badframe             : out   std_logic;
                rx_framedrop            : out   std_logic;
                -- Transmit client interface
                tx_clk                  : out   std_logic;
                tx_d                    : in    std_logic_vector( 7 downto 0);
                tx_dvld                 : in    std_logic;
                tx_ack                  : out   std_logic;
                tx_firstbyte            : in    std_logic;
                tx_underrun             : in    std_logic;
                tx_collision            : out   std_logic;
                tx_retransmit           : out   std_logic;
                -- MII/GMII interface to PHY
                gtx_clk                 : in    std_logic;
                gmii_txd                : out   std_logic_vector( 7 downto 0);
                gmii_tx_en              : out   std_logic;
                gmii_tx_er              : out   std_logic;
                gmii_tx_clk             : out   std_logic;
                mii_tx_clk              : in    std_logic;
                gmii_rxd                : in    std_logic_vector( 7 downto 0);
                gmii_rx_dv              : in    std_logic;
                gmii_rx_er              : in    std_logic;
                gmii_rx_clk             : in    std_logic;
                gmii_col                : in    std_logic;
                gmii_crs                : in    std_logic;
                -- MDIO interface to PHY
                mdc                     : out   std_logic;
                mdio_in                 : in    std_logic;
                mdio_out                : out   std_logic;
                mdio_tri                : out   std_logic;
                -- Host control interface
                host_clk                : in    std_logic;
                host_req                : in    std_logic;
                host_miimsel            : in    std_logic;
                host_opcode             : in    std_logic_vector( 1 downto 0);
                host_addr               : in    std_logic_vector( 9 downto 0);
                host_wrdata             : in    std_logic_vector(31 downto 0);
                host_rddata             : out   std_logic_vector(31 downto 0);
                host_miimrdy            : out   std_logic);
    end component mac;


    -- Signals -----------------------------------------------------------------

    -- Global system signals
    signal sys_clk              : std_logic;                        -- System clock 125 MHz
    signal sys_locked           : std_logic;                        -- System clock DCM is locked
    signal sys_rst              : std_logic;                        -- Synchronous system reset

    -- Global control signals
    signal sys_net_up           : std_logic;                        -- Network is up and running
    signal sys_type             : std_logic_vector( 3 downto 0);    -- GVSP payload type
    signal sys_mac_addr         : std_logic_vector(47 downto 0);    -- MAC address of the device
    signal sys_time_stamp       : std_logic_vector(63 downto 0);    -- Current time-stamp

    -- MPMC framebuffer control signals
    signal sys_fb_bot           : std_logic_vector(31 downto 0);  -- First framebuffer address
    signal sys_fb_top           : std_logic_vector(31 downto 0);  -- Last framebuffer address + 1
    signal sys_fb_init          : std_logic;                      -- Reload margins

    -- External bus of the CPU
    signal epc_rddata_0         : std_logic_vector(31 downto 0);    -- Data from GigE core
    signal epc_rddata_1         : std_logic_vector(31 downto 0);    -- Data from video processor
    signal epc_rddata           : std_logic_vector(31 downto 0);    -- Data from peripherals to CPU
    signal epc_wrdata           : std_logic_vector(31 downto 0);    -- Data from CPU to peripheral
    signal epc_addr             : std_logic_vector(15 downto 0);    -- Peripheral address
    signal epc_be               : std_logic_vector( 3 downto 0);    -- Byte enables
    signal epc_rnw              : std_logic;                        -- Read/write command
    signal epc_rdy              : std_logic_vector( 0 to     1);    -- Peripherals ready
    signal epc_cs_n             : std_logic_vector( 0 to     1);    -- Peripheral chip selects
    signal cpu_irq              : std_logic;                        -- Interrupt request

    -- Video processor to memory controller interface
    signal video_clk            : std_logic;
    signal video_frame          : std_logic;                        -- Data frame valid
    signal video_dv             : std_logic;                        -- Current data valid
    signal video_data           : std_logic_vector(15 downto 0);    -- Video data
    signal video_ptype          : std_logic_vector(31 downto 0);    -- Pixel type
    signal video_size_x         : std_logic_vector(31 downto 0);    -- Frame width
    signal video_size_y         : std_logic_vector(31 downto 0);    -- Frame height
    signal video_offs_x         : std_logic_vector(31 downto 0);    -- ROI horizontal offset
    signal video_offs_y         : std_logic_vector(31 downto 0);    -- ROI vertical offset
    signal video_pad_x          : std_logic_vector(15 downto 0);    -- Padding after each line in bytes
    signal video_pad_y          : std_logic_vector(15 downto 0);    -- Padding after frame in bytes

    -- Write-read control interface
    signal rw_bottom            : std_logic_vector(31 downto 0);    -- First address of area blocked for reading
    signal desc_start           : std_logic_vector(31 downto 0);    -- Beginning of the new frame
    signal desc_len             : std_logic_vector(23 downto 0);    -- Length of the new frame in dwords
    signal desc_hlen            : std_logic_vector( 3 downto 0);    -- Number of valid dwords of the frame header
    signal desc_type            : std_logic_vector( 3 downto 0);    -- Payload type
    signal desc_we              : std_logic;                        -- FIFO write enable

    -- Multi-port memory controller interface
    signal mpmc_init_done       : std_logic;
    signal mpmc_addr_ack        : std_logic;
    signal mpmc_addr_req        : std_logic;
    signal mpmc_rnw             : std_logic;
    signal mpmc_rd_mod_wr       : std_logic;
    signal mpmc_size            : std_logic_vector( 3 downto 0);
    signal mpmc_addr            : std_logic_vector(31 downto 0);
    signal mpmc_wrfifo_afull    : std_logic;
    signal mpmc_wrfifo_empty    : std_logic;
    signal mpmc_wrfifo_flush    : std_logic;
    signal mpmc_wrfifo_push     : std_logic;
    signal mpmc_wrfifo_be       : std_logic_vector( 3 downto 0);
    signal mpmc_wrfifo_data     : std_logic_vector(31 downto 0);
    signal mpmc_rdfifo_empty    : std_logic;
    signal mpmc_rdfifo_lat      : std_logic_vector( 1 downto 0);
    signal mpmc_rdfifo_rdwa     : std_logic_vector( 3 downto 0);
    signal mpmc_rdfifo_data     : std_logic_vector(31 downto 0);
    signal mpmc_rdfifo_flush    : std_logic;
    signal mpmc_rdfifo_pop      : std_logic;

    -- Memory controller to GigE core interface
    signal mem_data             : std_logic_vector(31 downto 0);    -- Data to be sent
    signal mem_header           : std_logic;                        -- Header valid
    signal mem_write            : std_logic;                        -- Write enable
    signal mem_full             : std_logic;                        -- Data FIFO is full
    signal mem_max_len          : std_logic_vector(15 downto 0);    -- Maximum packet length

    -- Packet resend interface
    signal rsnd_req             : std_logic;                        -- Resend request
    signal rsnd_blk_id          : std_logic_vector(15 downto 0);    -- Block to be resent
    signal rsnd_first_pkt_id    : std_logic_vector(23 downto 0);    -- First packet to resend
    signal rsnd_last_pkt_id     : std_logic_vector(23 downto 0);    -- Last packet to resend

    -- MAC host interface
    signal mac_host_req         : std_logic;                        -- Host access request
    signal mac_host_miimsel     : std_logic;                        -- MIIM interface select
    signal mac_host_opcode      : std_logic_vector( 1 downto 0);    -- Access opcode
    signal mac_host_addr        : std_logic_vector( 9 downto 0);    -- Address
    signal mac_host_wrdata      : std_logic_vector(31 downto 0);    -- Data to write
    signal mac_host_rddata      : std_logic_vector(31 downto 0);    -- Read data
    signal mac_host_miimrdy     : std_logic;                        -- MIIM interface ready

    -- MAC transmit interface
    signal mac_tx_clk           : std_logic;                        -- Transmit clock
    signal mac_tx_d             : std_logic_vector( 7 downto 0);    -- Data to send
    signal mac_tx_dvld          : std_logic;                        -- Data valid
    signal mac_tx_firstbyte     : std_logic;                        -- First byte has been sent
    signal mac_tx_underrun      : std_logic;                        -- Data underrun
    signal mac_tx_ack           : std_logic;                        -- Transmit acknowledge
    signal mac_tx_collision     : std_logic;                        -- Collision on half-duplex line
    signal mac_tx_retransmit    : std_logic;                        -- Retransmit last frame

    -- MAC receive interface
    signal mac_rx_clk           : std_logic;                        -- Receive clock
    signal mac_rx_d             : std_logic_vector( 7 downto 0);    -- Received data
    signal mac_rx_dvld          : std_logic;                        -- Data valid
    signal mac_rx_goodframe     : std_logic;                        -- Last frame is ok
    signal mac_rx_badframe      : std_logic;                        -- Last frame is currupted
    signal mac_rx_framedrop     : std_logic;                        -- A frame was dropped

    -- Ethernet PHY MIIM data
    signal phy_mdio_in          : std_logic;                        -- MDIO input
    signal phy_mdio_out         : std_logic;                        -- MDIO ouput
    signal phy_mdio_tri         : std_logic;                        -- MDIO tristate

    -- I2C buses signals
    signal i2c_sda_o            : std_logic;                        -- Common SDA output
    signal i2c_sda_i            : std_logic;                        -- Combined SDA input


    -- Attributes --------------------------------------------------------------

    -- CPU system
    attribute box_type : string;
    attribute box_type of system : component is "user_black_box";

begin

    -- Instantiation of components ---------------------------------------------

    -- Microblaze CPU
    SYSTEM_INST: system
        port map   (fpga_0_xps_uart_0_sin_pin            => fpga_0_xps_uart_0_sin_pin,
                    fpga_0_xps_uart_0_sout_pin           => fpga_0_xps_uart_0_sout_pin,
                    fpga_0_xps_gpio_3_gpio_io_pin        => fpga_0_xps_gpio_3_gpio_io_pin,
                    fpga_0_xps_gpio_4_gpio_io_pin        => fpga_0_xps_gpio_4_gpio_io_pin,
                    fpga_0_xps_gpio_1_gpio_io_pin        => fpga_0_xps_gpio_1_gpio_io_pin,
                    fpga_0_xps_gpio_2_gpio_io_pin        => fpga_0_xps_gpio_2_gpio_io_pin,
                    fpga_0_xps_sysace_0_sysace_mpa_pin   => fpga_0_xps_sysace_0_sysace_mpa_pin,
                    fpga_0_xps_sysace_0_sysace_clk_pin   => fpga_0_xps_sysace_0_sysace_clk_pin,
                    fpga_0_xps_sysace_0_sysace_mpirq_pin => fpga_0_xps_sysace_0_sysace_mpirq_pin,
                    fpga_0_xps_sysace_0_sysace_cen_pin   => fpga_0_xps_sysace_0_sysace_cen_pin,
                    fpga_0_xps_sysace_0_sysace_oen_pin   => fpga_0_xps_sysace_0_sysace_oen_pin,
                    fpga_0_xps_sysace_0_sysace_wen_pin   => fpga_0_xps_sysace_0_sysace_wen_pin,
                    fpga_0_xps_sysace_0_sysace_mpd_pin   => fpga_0_xps_sysace_0_sysace_mpd_pin,
                    fpga_0_xps_mch_emc_0_mem_a_pin       => fpga_0_xps_mch_emc_0_mem_a_pin,
                    fpga_0_xps_mch_emc_0_mem_cen_pin     => fpga_0_xps_mch_emc_0_mem_cen_pin,
                    fpga_0_xps_mch_emc_0_mem_oen_pin     => fpga_0_xps_mch_emc_0_mem_oen_pin,
                    fpga_0_xps_mch_emc_0_mem_wen_pin     => fpga_0_xps_mch_emc_0_mem_wen_pin,
                    fpga_0_xps_mch_emc_0_mem_adv_ldn_pin => fpga_0_xps_mch_emc_0_mem_adv_ldn_pin,
                    fpga_0_xps_mch_emc_0_mem_dq_pin      => fpga_0_xps_mch_emc_0_mem_dq_pin,
                    fpga_0_mpmc_0_ddr2_clk_pin           => fpga_0_mpmc_0_ddr2_clk_pin,
                    fpga_0_mpmc_0_ddr2_clk_n_pin         => fpga_0_mpmc_0_ddr2_clk_n_pin,
                    fpga_0_mpmc_0_ddr2_ce_pin            => fpga_0_mpmc_0_ddr2_ce_pin,
                    fpga_0_mpmc_0_ddr2_cs_n_pin          => fpga_0_mpmc_0_ddr2_cs_n_pin,
                    fpga_0_mpmc_0_ddr2_odt_pin           => fpga_0_mpmc_0_ddr2_odt_pin,
                    fpga_0_mpmc_0_ddr2_ras_n_pin         => fpga_0_mpmc_0_ddr2_ras_n_pin,
                    fpga_0_mpmc_0_ddr2_cas_n_pin         => fpga_0_mpmc_0_ddr2_cas_n_pin,
                    fpga_0_mpmc_0_ddr2_we_n_pin          => fpga_0_mpmc_0_ddr2_we_n_pin,
                    fpga_0_mpmc_0_ddr2_bankaddr_pin      => fpga_0_mpmc_0_ddr2_bankaddr_pin,
                    fpga_0_mpmc_0_ddr2_addr_pin          => fpga_0_mpmc_0_ddr2_addr_pin,
                    fpga_0_mpmc_0_ddr2_dq_pin            => fpga_0_mpmc_0_ddr2_dq_pin,
                    fpga_0_mpmc_0_ddr2_dm_pin            => fpga_0_mpmc_0_ddr2_dm_pin,
                    fpga_0_mpmc_0_ddr2_dqs_pin           => fpga_0_mpmc_0_ddr2_dqs_pin,
                    fpga_0_mpmc_0_ddr2_dqs_n_pin         => fpga_0_mpmc_0_ddr2_dqs_n_pin,
                    fpga_0_clk_1_sys_clk_pin             => fpga_0_clk_1_sys_clk_pin,
                    fpga_0_rst_1_sys_rst_pin             => fpga_0_rst_1_sys_rst_pin,
                    sys_clk                              => sys_clk,
                    sys_rst                              => sys_rst,
                    sys_locked                           => sys_locked,
                    epc_addr                             => epc_addr,
                    epc_wrdata                           => epc_wrdata,
                    epc_be                               => epc_be,
                    epc_cs_n                             => epc_cs_n,
                    epc_rnw                              => epc_rnw,
                    epc_rddata                           => epc_rddata,
                    epc_rdy                              => epc_rdy,
                    cpu_irq                              => cpu_irq,
                    mpmc_initdone                        => mpmc_init_done,
                    mpmc_addrack                         => mpmc_addr_ack,
                    mpmc_addrreq                         => mpmc_addr_req,
                    mpmc_rnw                             => mpmc_rnw,
                    mpmc_rdmodwr                         => mpmc_rd_mod_wr,
                    mpmc_size                            => mpmc_size,
                    mpmc_addr                            => mpmc_addr,
                    mpmc_wrfifo_almostfull               => mpmc_wrfifo_afull,
                    mpmc_wrfifo_empty                    => mpmc_wrfifo_empty,
                    mpmc_wrfifo_flush                    => mpmc_wrfifo_flush,
                    mpmc_wrfifo_push                     => mpmc_wrfifo_push,
                    mpmc_wrfifo_be                       => mpmc_wrfifo_be,
                    mpmc_wrfifo_data                     => mpmc_wrfifo_data,
                    mpmc_rdfifo_empty                    => mpmc_rdfifo_empty,
                    mpmc_rdfifo_latency                  => mpmc_rdfifo_lat,
                    mpmc_rdfifo_rdwdaddr                 => mpmc_rdfifo_rdwa,
                    mpmc_rdfifo_data                     => mpmc_rdfifo_data,
                    mpmc_rdfifo_flush                    => mpmc_rdfifo_flush,
                    mpmc_rdfifo_pop                      => mpmc_rdfifo_pop);

    -- Input video processor
    VIDEO_INST: video
        port map (sys_clk                                => sys_clk,
                  sys_rst                                => sys_rst,
                  epc_addr                               => epc_addr,
                  epc_odata                              => epc_wrdata,
                  epc_cs_n                               => epc_cs_n(1),
                  epc_rnw                                => epc_rnw,
                  epc_idata                              => epc_rddata_1,
                  epc_rdy                                => epc_rdy(1),
                  fb_clk                                 => video_clk,
                  fb_frame                               => video_frame,
                  fb_dv                                  => video_dv,
                  fb_data                                => video_data,
                  fb_ptype                               => video_ptype,
                  fb_size_x                              => video_size_x,
                  fb_size_y                              => video_size_y,
                  fb_offs_x                              => video_offs_x,
                  fb_offs_y                              => video_offs_y,
                  fb_pad_x                               => video_pad_x,
                  fb_pad_y                               => video_pad_y);

    -- MPMC framebuffer
    FRAMEBUF_INST: framebuf
        port map (sys_rst                                => sys_rst,
                  sys_net_up                             => sys_net_up,
                  sys_type                               => sys_type,
                  sys_tstamp                             => sys_time_stamp,
                  sys_fb_bot                             => sys_fb_bot,
                  sys_fb_top                             => sys_fb_top,
                  sys_fb_init                            => sys_fb_init,
                  din_clk                                => video_clk,
                  din_frame                              => video_frame,
                  din_dv                                 => video_dv,
                  din_width                              => "01",
                  din_data(31 downto 16)                 => x"0000",
                  din_data(15 downto  0)                 => video_data,
                  din_ptype                              => video_ptype,
                  din_size_x                             => video_size_x,
                  din_size_y                             => video_size_y,
                  din_offs_x                             => video_offs_x,
                  din_offs_y                             => video_offs_y,
                  din_pad_x                              => video_pad_x,
                  din_pad_y                              => video_pad_y,
                  wr_rdbot                               => rw_bottom,
                  wr_d_start                             => desc_start,
                  wr_d_len                               => desc_len,
                  wr_d_hlen                              => desc_hlen,
                  wr_d_type                              => desc_type,
                  wr_d_we                                => desc_we,
                  rd_idle                                => open,
                  rd_rdbot                               => open,
                  rd_rdlen                               => open,
                  rd_prbot                               => rw_bottom,
                  rd_prlen                               => open,
                  rd_d_start                             => desc_start,
                  rd_d_len                               => desc_len,
                  rd_d_hlen                              => desc_hlen,
                  rd_d_type                              => desc_type,
                  rd_d_we                                => desc_we,
                  tx_full                                => mem_full,
                  tx_max_len                             => mem_max_len,
                  tx_write                               => mem_write,
                  tx_header                              => mem_header,
                  tx_data                                => mem_data,
                  rsnd_req                               => rsnd_req,
                  rsnd_bid                               => rsnd_blk_id,
                  rsnd_pid_f                             => rsnd_first_pkt_id,
                  rsnd_pid_l                             => rsnd_last_pkt_id,
                  mpmc_clk                               => sys_clk,
                  mpmc_init_done                         => mpmc_init_done,
                  mpmc_addr_ack                          => mpmc_addr_ack,
                  mpmc_addr_req                          => mpmc_addr_req,
                  mpmc_rnw                               => mpmc_rnw,
                  mpmc_rd_mod_wr                         => mpmc_rd_mod_wr,
                  mpmc_size                              => mpmc_size,
                  mpmc_addr                              => mpmc_addr,
                  mpmc_wrfifo_afull                      => mpmc_wrfifo_afull,
                  mpmc_wrfifo_empty                      => mpmc_wrfifo_empty,
                  mpmc_wrfifo_flush                      => mpmc_wrfifo_flush,
                  mpmc_wrfifo_push                       => mpmc_wrfifo_push,
                  mpmc_wrfifo_be                         => mpmc_wrfifo_be,
                  mpmc_wrfifo_data                       => mpmc_wrfifo_data,
                  mpmc_rdfifo_empty                      => mpmc_rdfifo_empty,
                  mpmc_rdfifo_lat                        => mpmc_rdfifo_lat,
                  mpmc_rdfifo_rdwa                       => mpmc_rdfifo_rdwa,
                  mpmc_rdfifo_data                       => mpmc_rdfifo_data,
                  mpmc_rdfifo_flush                      => mpmc_rdfifo_flush,
                  mpmc_rdfifo_pop                        => mpmc_rdfifo_pop);

    -- GigE Vision core
    GIGE_INST: gige
        port map   (sys_rst                              => sys_rst,
                    sys_clk                              => sys_clk,
                    sys_net_up                           => sys_net_up,
                    sys_uart_bypass                      => open,
                    sys_gpo                              => open,
                    sys_type                             => sys_type,
                    sys_mac_addr                         => sys_mac_addr,
                    sys_time_stamp                       => sys_time_stamp,
                    sys_fb_init                          => sys_fb_init,
                    sys_fb_bot                           => sys_fb_bot,
                    sys_fb_top                           => sys_fb_top,
                    cpu_addr                             => epc_addr,
                    cpu_wrdata                           => epc_wrdata,
                    cpu_be                               => epc_be,
                    cpu_cs_n                             => epc_cs_n(0),
                    cpu_rnw                              => epc_rnw,
                    cpu_rddata                           => epc_rddata_0,
                    cpu_rdy                              => epc_rdy(0),
                    cpu_irq                              => cpu_irq,
                    i2c_scl                              => i2c_scl,
                    i2c_sda_o                            => i2c_sda_o,
                    i2c_sda_i                            => i2c_sda_i,
                    spi_clk                              => open,
                    spi_cs_n                             => open,
                    spi_mosi                             => open,
                    spi_miso                             => '0',
                    mem_clk                              => sys_clk,
                    mem_data                             => mem_data,
                    mem_header                           => mem_header,
                    mem_write                            => mem_write,
                    mem_full                             => mem_full,
                    mem_max_len                          => mem_max_len,
                    rsnd_req                             => rsnd_req,
                    rsnd_blk_id                          => rsnd_blk_id,
                    rsnd_first_pkt_id                    => rsnd_first_pkt_id,
                    rsnd_last_pkt_id                     => rsnd_last_pkt_id,
                    rx_stm_clk                           => '0',
                    rx_stm_data                          => open,
                    rx_stm_be                            => open,
                    rx_stm_frame                         => open,
                    rx_stm_blk_id                        => open,
                    rx_stm_pkt_id                        => open,
                    mac_host_req                         => mac_host_req,
                    mac_host_miimsel                     => mac_host_miimsel,
                    mac_host_opcode                      => mac_host_opcode,
                    mac_host_addr                        => mac_host_addr,
                    mac_host_wrdata                      => mac_host_wrdata,
                    mac_host_rddata                      => mac_host_rddata,
                    mac_host_miimrdy                     => mac_host_miimrdy,
                    mac_tx_clk                           => mac_tx_clk,
                    mac_tx_d                             => mac_tx_d,
                    mac_tx_dvld                          => mac_tx_dvld,
                    mac_tx_firstbyte                     => mac_tx_firstbyte,
                    mac_tx_underrun                      => mac_tx_underrun,
                    mac_tx_ack                           => mac_tx_ack,
                    mac_tx_collision                     => mac_tx_collision,
                    mac_tx_retransmit                    => mac_tx_retransmit,
                    mac_rx_clk                           => mac_rx_clk,
                    mac_rx_d                             => mac_rx_d,
                    mac_rx_dvld                          => mac_rx_dvld,
                    mac_rx_goodframe                     => mac_rx_goodframe,
                    mac_rx_badframe                      => mac_rx_badframe,
                    mac_rx_framedrop                     => mac_rx_framedrop,
                    phy_rst_n                            => phy_rst_n);

    -- Gigabit Ethernet MAC
    MAC_INST: mac
        port map   (reset                                => sys_rst,
                    dcm_locked                           => sys_locked,
                    mac_address                          => sys_mac_addr,
                    rx_clk                               => mac_rx_clk,
                    rx_d                                 => mac_rx_d,
                    rx_dvld                              => mac_rx_dvld,
                    rx_goodframe                         => mac_rx_goodframe,
                    rx_badframe                          => mac_rx_badframe,
                    rx_framedrop                         => mac_rx_framedrop,
                    tx_clk                               => mac_tx_clk,
                    tx_d                                 => mac_tx_d,
                    tx_dvld                              => mac_tx_dvld,
                    tx_ack                               => mac_tx_ack,
                    tx_firstbyte                         => mac_tx_firstbyte,
                    tx_underrun                          => mac_tx_underrun,
                    tx_collision                         => mac_tx_collision,
                    tx_retransmit                        => mac_tx_retransmit,
                    gtx_clk                              => sys_clk,
                    gmii_txd                             => phy_gmii_txd,
                    gmii_tx_en                           => phy_gmii_tx_en,
                    gmii_tx_er                           => phy_gmii_tx_er,
                    gmii_tx_clk                          => phy_gmii_tx_clk,
                    mii_tx_clk                           => phy_mii_tx_clk,
                    gmii_rxd                             => phy_gmii_rxd,
                    gmii_rx_dv                           => phy_gmii_rx_dv,
                    gmii_rx_er                           => phy_gmii_rx_er,
                    gmii_rx_clk                          => phy_gmii_rx_clk,
                    gmii_col                             => phy_gmii_col,
                    gmii_crs                             => phy_gmii_crs,
                    mdc                                  => phy_mdc,
                    mdio_in                              => phy_mdio_in,
                    mdio_out                             => phy_mdio_out,
                    mdio_tri                             => phy_mdio_tri,
                    host_clk                             => sys_clk,
                    host_req                             => mac_host_req,
                    host_miimsel                         => mac_host_miimsel,
                    host_opcode                          => mac_host_opcode,
                    host_addr                            => mac_host_addr,
                    host_wrdata                          => mac_host_wrdata,
                    host_rddata                          => mac_host_rddata,
                    host_miimrdy                         => mac_host_miimrdy);


    -- Clock generators --------------------------------------------------------

    -- Video clock
    video_clk <= sys_clk;


    -- EPC CPU input data bus --------------------------------------------------

    epc_rddata <= epc_rddata_0 when epc_cs_n(0) = '0' else
                  epc_rddata_1 when epc_cs_n(1) = '0' else
                  (others => '0');


    -- Tri-state buffers -------------------------------------------------------

    -- PHY MDIO data I/O buffer
    MDIO_IOBUF: iobuf
        port map   (o                                    => phy_mdio_in,
                    io                                   => phy_mdio,
                    i                                    => phy_mdio_out,
                    t                                    => phy_mdio_tri);

    -- I2C data I/O buffer
    IIC_SDA_IOBUF: iobuf
        port map   (o                                    => i2c_sda_i,
                    io                                   => i2c_sda,
                    i                                    => '0',
                    t                                    => i2c_sda_o);

end top;
