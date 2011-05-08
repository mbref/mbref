-- ************************************************************************** --
-- *  GigE Vision Core                                                      * --
-- *------------------------------------------------------------------------* --
-- *  Module :  MAC-WRAPPER                                                 * --
-- *    File :  mac.vhd                                                     * --
-- *    Date :  2009-11-11                                                  * --
-- *     Rev :  0.1                                                         * --
-- *  Author :  MAC                                                         * --
-- *------------------------------------------------------------------------* --
-- *  Wrapper for Virtex-5 embedded tri-mode Ethernet MAC                   * --
-- *------------------------------------------------------------------------* --
-- *  0.1  |  2009-11-11  |  MAS |  Initial release                         * --
-- ************************************************************************** --

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;

--------------------------------------------------------------------------------
--  MAC-WRAPPER entity
--------------------------------------------------------------------------------

entity mac is
   port(-- Common signals
      reset         : in  std_logic;
      dcm_locked    : in  std_logic;
      mac_address   : in  std_logic_vector(47 downto 0);      --not used
      -- EMAC0 Clocking
      -- TX Client Clock output from EMAC0
      tx_clk                          : out std_logic;
      -- RX Client Clock output from EMAC0
      rx_clk                          : out std_logic;
      
      -- Client Receiver Interface - EMAC0
      rx_d                            : out std_logic_vector(7 downto 0);
      rx_dvld                         : out std_logic;
      rx_goodframe                    : out std_logic;
      rx_badframe                     : out std_logic;
      rx_framedrop                    : out std_logic;
      
      -- Client Transmitter Interface - EMAC0
      tx_d                            : in  std_logic_vector(7 downto 0);
      tx_dvld                         : in  std_logic;
      tx_ack                          : out std_logic;
      tx_firstbyte                    : in  std_logic;
      tx_underrun                     : in  std_logic;
      tx_collision                    : out std_logic;
      tx_retransmit                   : out std_logic;
       
      -- Clock Signals - EMAC0
      gtx_clk                         : in  std_logic;
      -- GMII Interface - EMAC0
      gmii_txd                        : out std_logic_vector(7 downto 0);
      gmii_tx_en                      : out std_logic;
      gmii_tx_er                      : out std_logic;
      gmii_tx_clk                     : out std_logic;
      gmii_rxd                        : in  std_logic_vector(7 downto 0);
      gmii_rx_dv                      : in  std_logic;
      gmii_rx_er                      : in  std_logic;
      gmii_rx_clk                     : in  std_logic;
      mii_tx_clk                      : in  std_logic;
      gmii_col                        : in  std_logic;
      gmii_crs                        : in  std_logic;
      -- MDIO interface to PHY
      mdc                             : out std_logic;
      mdio_in                         : in  std_logic;
      mdio_out                        : out std_logic;
      mdio_tri                        : out std_logic;

      -- Generic Host Interface
      host_clk                        : in  std_logic;
      host_opcode                     : in  std_logic_vector(1 downto 0);
      host_req                        : in  std_logic;
      host_miimsel                    : in  std_logic;
      host_addr                       : in  std_logic_vector(9 downto 0);
      host_wrdata                     : in  std_logic_vector(31 downto 0);
      host_miimrdy                    : out std_logic;
      host_rddata                     : out std_logic_vector(31 downto 0)

   );
end mac;


architecture TOP_LEVEL of mac is

-------------------------------------------------------------------------------
-- Component Declarations for lower hierarchial level entities
-------------------------------------------------------------------------------
  -- Component Declaration for the main EMAC wrapper
  component v5_emac_v1_3 is
    port(
      -- Client Receiver Interface - EMAC0
      EMAC0CLIENTRXCLIENTCLKOUT       : out std_logic;
      CLIENTEMAC0RXCLIENTCLKIN        : in  std_logic;
      EMAC0CLIENTRXD                  : out std_logic_vector(7 downto 0);
      EMAC0CLIENTRXDVLD               : out std_logic;
      EMAC0CLIENTRXDVLDMSW            : out std_logic;
      EMAC0CLIENTRXGOODFRAME          : out std_logic;
      EMAC0CLIENTRXBADFRAME           : out std_logic;
      EMAC0CLIENTRXFRAMEDROP          : out std_logic;
      EMAC0CLIENTRXSTATS              : out std_logic_vector(6 downto 0);
      EMAC0CLIENTRXSTATSVLD           : out std_logic;
      EMAC0CLIENTRXSTATSBYTEVLD       : out std_logic;

      -- Client Transmitter Interface - EMAC0
      EMAC0CLIENTTXCLIENTCLKOUT       : out std_logic;
      CLIENTEMAC0TXCLIENTCLKIN        : in  std_logic;
      CLIENTEMAC0TXD                  : in  std_logic_vector(7 downto 0);
      CLIENTEMAC0TXDVLD               : in  std_logic;
      CLIENTEMAC0TXDVLDMSW            : in  std_logic;
      EMAC0CLIENTTXACK                : out std_logic;
      CLIENTEMAC0TXFIRSTBYTE          : in  std_logic;
      CLIENTEMAC0TXUNDERRUN           : in  std_logic;
      EMAC0CLIENTTXCOLLISION          : out std_logic;
      EMAC0CLIENTTXRETRANSMIT         : out std_logic;
      CLIENTEMAC0TXIFGDELAY           : in  std_logic_vector(7 downto 0);
      EMAC0CLIENTTXSTATS              : out std_logic;
      EMAC0CLIENTTXSTATSVLD           : out std_logic;
      EMAC0CLIENTTXSTATSBYTEVLD       : out std_logic;

      -- MAC Control Interface - EMAC0
      CLIENTEMAC0PAUSEREQ             : in  std_logic;
      CLIENTEMAC0PAUSEVAL             : in  std_logic_vector(15 downto 0);
      EMAC0PHYMCLKOUT                 : out std_logic;
      PHYEMAC0MDIN                    : in  std_logic;
      EMAC0PHYMDOUT                   : out std_logic;
      EMAC0PHYMDTRI                   : out std_logic;

      -- Clock Signals - EMAC0
      GTX_CLK_0                       : in  std_logic;
      PHYEMAC0TXGMIIMIICLKIN          : in  std_logic;
      EMAC0PHYTXGMIIMIICLKOUT         : out std_logic;

      -- GMII Interface - EMAC0
      GMII_TXD_0                      : out std_logic_vector(7 downto 0);
      GMII_TX_EN_0                    : out std_logic;
      GMII_TX_ER_0                    : out std_logic;
      GMII_RXD_0                      : in  std_logic_vector(7 downto 0);
      GMII_RX_DV_0                    : in  std_logic;
      GMII_RX_ER_0                    : in  std_logic;
      GMII_RX_CLK_0                   : in  std_logic;

      
      MII_TX_CLK_0                    : in  std_logic;
      GMII_COL_0                      : in  std_logic;
      GMII_CRS_0                      : in  std_logic;

      -- Generic Host Interface
      HOSTCLK                         : in  std_logic;
      HOSTOPCODE                      : in  std_logic_vector(1 downto 0);
      HOSTREQ                         : in  std_logic;
      HOSTMIIMSEL                     : in  std_logic;
      HOSTADDR                        : in  std_logic_vector(9 downto 0);
      HOSTWRDATA                      : in  std_logic_vector(31 downto 0);
      HOSTMIIMRDY                     : out std_logic;
      HOSTRDDATA                      : out std_logic_vector(31 downto 0);
      HOSTEMAC1SEL                    : in  std_logic;

      DCM_LOCKED_0                    : in  std_logic;

      -- Asynchronous Reset
      RESET                           : in  std_logic
    );
  end component;


 
  -- Component Declaration for the GMII Physcial Interface 
  component gmii_if
    port(
      RESET                           : in  std_logic;
      -- GMII Interface
      GMII_TXD                        : out std_logic_vector(7 downto 0);
      GMII_TX_EN                      : out std_logic;
      GMII_TX_ER                      : out std_logic;
      GMII_TX_CLK                     : out std_logic;
      GMII_RXD                        : in  std_logic_vector(7 downto 0);
      GMII_RX_DV                      : in  std_logic;
      GMII_RX_ER                      : in  std_logic;
      -- MAC Interface
      TXD_FROM_MAC                    : in  std_logic_vector(7 downto 0);
      TX_EN_FROM_MAC                  : in  std_logic;
      TX_ER_FROM_MAC                  : in  std_logic;
      TX_CLK                          : in  std_logic;
      RXD_TO_MAC                      : out std_logic_vector(7 downto 0);
      RX_DV_TO_MAC                    : out std_logic;
      RX_ER_TO_MAC                    : out std_logic;
      RX_CLK                          : in  std_logic);
  end component;



-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------

    --  Power and ground signals
    signal gnd_i                          : std_logic;
    signal gnd_v48_i                      : std_logic_vector(47 downto 0);
    signal vcc_i                          : std_logic;

    -- Asynchronous reset signals
    signal reset_i                        : std_logic;

    -- EMAC0 Client Clocking Signals
    signal rx_client_clk_out_0_i          : std_logic;
    signal rx_client_clk_in_0_i           : std_logic;
    signal tx_client_clk_out_0_i          : std_logic;
    signal tx_client_clk_in_0_i           : std_logic;
    -- EMAC0 Physical Interface Clocking Signals
    signal tx_gmii_mii_clk_out_0_i        : std_logic;
    signal tx_gmii_mii_clk_in_0_i         : std_logic;
    -- EMAC0 Physical Interface Signals
    signal gmii_tx_en_0_i                 : std_logic;
    signal gmii_tx_er_0_i                 : std_logic;
    signal gmii_txd_0_i                   : std_logic_vector(7 downto 0);
    signal mii_tx_clk_0_i                 : std_logic;    
    signal gmii_rx_clk_0_i                : std_logic;
    signal gmii_rx_dv_0_r                 : std_logic;
    signal gmii_rx_er_0_r                 : std_logic;
    signal gmii_rxd_0_r                   : std_logic_vector(7 downto 0);




    -- 125MHz reference clock for EMAC0
    signal gtx_clk_ibufg_0_i              : std_logic;


-------------------------------------------------------------------------------
-- Attribute Declarations 
-------------------------------------------------------------------------------



-------------------------------------------------------------------------------
-- Main Body of Code
-------------------------------------------------------------------------------

begin

    -- Auxiliary constants
    gnd_i     <= '0';
    gnd_v48_i <= "000000000000000000000000000000000000000000000000";
    vcc_i     <= '1';

    ---------------------------------------------------------------------------
    -- Main Reset Circuitry
    ---------------------------------------------------------------------------
    reset_i <= reset;


    ---------------------------------------------------------------------------
    -- GMII circuitry for the Physical Interface of EMAC0
    ---------------------------------------------------------------------------

    gmii0 : gmii_if port map (
        RESET                         => reset_i,
        GMII_TXD                      => gmii_txd,
        GMII_TX_EN                    => gmii_tx_en,
        GMII_TX_ER                    => gmii_tx_er,
        GMII_TX_CLK                   => gmii_tx_clk,
        GMII_RXD                      => gmii_rxd,
        GMII_RX_DV                    => gmii_rx_dv,
        GMII_RX_ER                    => gmii_rx_er,
        TXD_FROM_MAC                  => gmii_txd_0_i,
        TX_EN_FROM_MAC                => gmii_tx_en_0_i,
        TX_ER_FROM_MAC                => gmii_tx_er_0_i,
        TX_CLK                        => tx_gmii_mii_clk_in_0_i,
        RXD_TO_MAC                    => gmii_rxd_0_r,
        RX_DV_TO_MAC                  => gmii_rx_dv_0_r,
        RX_ER_TO_MAC                  => gmii_rx_er_0_r,
        RX_CLK                        => gmii_rx_clk_0_i);

 
    --------------------------------------------------------------------------
    -- GTX_CLK Clock Management - 125 MHz clock frequency supplied by the user
    -- (Connected to PHYEMAC#GTXCLK of the EMAC primitive)
    --------------------------------------------------------------------------
    gtx_clk_ibufg_0_i <= gtx_clk;



    ------------------------------------------------------------------------
    -- GMII PHY side transmit clock for EMAC0
    ------------------------------------------------------------------------
    TX_GMII_MII_CLK_0_BUFG: BUFG
        port map (I => tx_gmii_mii_clk_out_0_i,
                  O => tx_gmii_mii_clk_in_0_i);
 
    
    ------------------------------------------------------------------------
    -- GMII PHY side Receiver Clock for EMAC0
    ------------------------------------------------------------------------
    gmii_rx_clk_0_i <= gmii_rx_clk;    

    -- RX and TX client clock management in 8-bit mode -------------------------

    RX_CLIENT_CLK_0_BUFG: BUFG
        port map (I => rx_client_clk_out_0_i,
                  O => rx_client_clk_in_0_i);

    TX_CLIENT_CLK_0_BUFG: BUFG
        port map (I => tx_client_clk_out_0_i,
                  O => tx_client_clk_in_0_i);

    rx_clk <= rx_client_clk_in_0_i;
    tx_clk <= tx_client_clk_in_0_i;

    ------------------------------------------------------------------------
    -- MII Transmitter Clock for EMAC0
    ------------------------------------------------------------------------
    mii_tx_clk_0_i <= mii_tx_clk;


    --------------------------------------------------------------------------
    -- Instantiate the EMAC Wrapper (v5_emac_v1_3.vhd)
    --------------------------------------------------------------------------
    v5_emac_wrapper : v5_emac_v1_3
    port map (
        -- Client Receiver Interface - EMAC0
        EMAC0CLIENTRXCLIENTCLKOUT       => rx_client_clk_out_0_i,
        CLIENTEMAC0RXCLIENTCLKIN        => rx_client_clk_in_0_i, 
        EMAC0CLIENTRXD                  => rx_d,
        EMAC0CLIENTRXDVLD               => rx_dvld,
        EMAC0CLIENTRXDVLDMSW            => open,
        EMAC0CLIENTRXGOODFRAME          => rx_goodframe,
        EMAC0CLIENTRXBADFRAME           => rx_badframe,
        EMAC0CLIENTRXFRAMEDROP          => rx_framedrop,
        EMAC0CLIENTRXSTATS              => open,
        EMAC0CLIENTRXSTATSVLD           => open,
        EMAC0CLIENTRXSTATSBYTEVLD       => open,

        -- Client Transmitter Interface - EMAC0
        EMAC0CLIENTTXCLIENTCLKOUT       => tx_client_clk_out_0_i,
        CLIENTEMAC0TXCLIENTCLKIN        => tx_client_clk_in_0_i,
        CLIENTEMAC0TXD                  => tx_d,
        CLIENTEMAC0TXDVLD               => tx_dvld,
        CLIENTEMAC0TXDVLDMSW            => gnd_i,
        EMAC0CLIENTTXACK                => tx_ack,
        CLIENTEMAC0TXFIRSTBYTE          => tx_firstbyte,
        CLIENTEMAC0TXUNDERRUN           => tx_underrun,
        EMAC0CLIENTTXCOLLISION          => tx_collision,
        EMAC0CLIENTTXRETRANSMIT         => tx_retransmit,
        CLIENTEMAC0TXIFGDELAY           => gnd_v48_i(7 downto 0),
        EMAC0CLIENTTXSTATS              => open,
        EMAC0CLIENTTXSTATSVLD           => open,
        EMAC0CLIENTTXSTATSBYTEVLD       => open,

        -- MAC Control Interface - EMAC0
        CLIENTEMAC0PAUSEREQ             => '0',
        CLIENTEMAC0PAUSEVAL             => x"0000",
        
        -- MDIO Interface - EMAC0
        EMAC0PHYMCLKOUT                 => mdc,
        PHYEMAC0MDIN                    => mdio_in,
        EMAC0PHYMDOUT                   => mdio_out,
        EMAC0PHYMDTRI                   => mdio_tri,

        -- Clock Signals - EMAC0
        GTX_CLK_0                       => gtx_clk_ibufg_0_i,

        EMAC0PHYTXGMIIMIICLKOUT         => tx_gmii_mii_clk_out_0_i,
        PHYEMAC0TXGMIIMIICLKIN          => tx_gmii_mii_clk_in_0_i,

        -- GMII Interface - EMAC0
        GMII_TXD_0                      => gmii_txd_0_i,
        GMII_TX_EN_0                    => gmii_tx_en_0_i,
        GMII_TX_ER_0                    => gmii_tx_er_0_i,
        GMII_RXD_0                      => gmii_rxd_0_r,
        GMII_RX_DV_0                    => gmii_rx_dv_0_r,
        GMII_RX_ER_0                    => gmii_rx_er_0_r,
        GMII_RX_CLK_0                   => gmii_rx_clk_0_i,

        MII_TX_CLK_0                    => mii_tx_clk_0_i,
        GMII_COL_0                      => gmii_col,
        GMII_CRS_0                      => gmii_crs,

        -- Host Interface
        HOSTCLK                         => host_clk,
        HOSTOPCODE                      => host_opcode,
        HOSTREQ                         => host_req,
        HOSTMIIMSEL                     => host_miimsel,
        HOSTADDR                        => host_addr,
        HOSTWRDATA                      => host_wrdata,
        HOSTMIIMRDY                     => host_miimrdy,
        HOSTRDDATA                      => host_rddata,
        HOSTEMAC1SEL                    => '0',

        DCM_LOCKED_0                    => dcm_locked,

        -- Asynchronous Reset
        RESET                           => reset_i
        );

end TOP_LEVEL;
