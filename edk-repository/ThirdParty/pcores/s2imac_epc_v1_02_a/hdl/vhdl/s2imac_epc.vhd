-------------------------------------------------------------------------------
-- s2imac_epc.vhd - entity/architecture pair
-------------------------------------------------------------------------------
-- ************************************************************************
-- ** DISCLAIMER OF LIABILITY                                            **
-- **                                                                    **
-- ** This file contains proprietary and confidential information of     **
-- ** Xilinx, Inc. ("Xilinx"), that is distributed under a license       **
-- ** from Xilinx, and may be used, copied and/or disclosed only         **
-- ** pursuant to the terms of a valid license agreement with Xilinx.    **
-- **                                                                    **
-- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION              **
-- ** ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER         **
-- ** EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT                **
-- ** LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,          **
-- ** MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx      **
-- ** does not warrant that functions included in the Materials will     **
-- ** meet the requirements of Licensee, or that the operation of the    **
-- ** Materials will be uninterrupted or error-free, or that defects     **
-- ** in the Materials will be corrected. Furthermore, Xilinx does       **
-- ** not warrant or make any representations regarding use, or the      **
-- ** results of the use, of the Materials in terms of correctness,      **
-- ** accuracy, reliability or otherwise.                                **
-- **                                                                    **
-- ** Xilinx products are not designed or intended to be fail-safe,      **
-- ** or for use in any application requiring fail-safe performance,     **
-- ** such as life-support or safety devices or systems, Class III       **
-- ** medical devices, nuclear facilities, applications related to       **
-- ** the deployment of airbags, or any other applications that could    **
-- ** lead to death, personal injury or severe property or               **
-- ** environmental damage (individually and collectively, "critical     **
-- ** applications"). Customer assumes the sole risk and liability       **
-- ** of any use of Xilinx products in critical applications,            **
-- ** subject only to applicable laws and regulations governing          **
-- ** limitations on product liability.                                  **
-- **                                                                    **
-- ** Copyright 2005, 2006, 2008, 2009 Xilinx, Inc.                      **
-- ** All rights reserved.                                               **
-- **                                                                    **
-- ** This disclaimer and copyright notice must be retained as part      **
-- ** of this file at all times.                                         **
-- ************************************************************************
-- 
-------------------------------------------------------------------------------
-- File          : s2imac_epc.vhd
-- Company       : Xilinx
-- Version       : v1.02.a
-- Description   : External Peripheral Controller for PLB bus
-- Standard      : VHDL-93
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Structure:
--             s2imac_epc.vhd
--               -plbv46_slave_single
--               -epc_core.vhd
--               -ipic_if_decode.vhd
--               -sync_cntl.vhd
--               -async_cntl.vhd
--                  -- async_counters.vhd
--                  -- async_statemachine.vhd
--               -address_gen.vhd
--               -data_steer.vhd
--               -access_mux.vhd
-------------------------------------------------------------------------------
-- Author   : SK
-- History  :
--
--  SK          08-18-2008 -- Upgraded to v1_01_a version
-- ^^^^^^
--            The core is updated for proc_common_v3_00_a and plb_slave_single-
--            _v1_01_a libraries.CR467963 and CR480619 are fixed.
-- ~~~~~~
--
--  SK        05-10-2006      -- First version
-- ^^^^^^
--            First version of XPS EPC.
-- ~~~~~~
--
--  SK        06-19-2009      -- Updated to close the CR 525042
-- ^^^^^^
--            The chip select signal and address strobe signal logic is update
--            in synchronous multiplexing mode.
-- ~~~~~~
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x"
--      reset signals:                          "rst", "rst_n"
--      generics:                               "C_*"
--      user defined types:                     "*_TYPE"
--      state machine next state:               "*_ns"
--      state machine current state:            "*_cs"
--      combinatorial signals:                  "*_cmb"
--      pipelined or register delay signals:    "*_d#"
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce"
--      internal version of output port         "*_i"
--      device pins:                            "*_pin"
--      ports:                                  - Names begin with Uppercase
--      processes:                              "*_PROCESS"
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;

use IEEE.std_logic_arith.conv_std_logic_vector;

            

library proc_common_v3_00_a;

use proc_common_v3_00_a.ipif_pkg.INTEGER_ARRAY_TYPE;

use proc_common_v3_00_a.ipif_pkg.SLV64_ARRAY_TYPE;

use proc_common_v3_00_a.ipif_pkg.calc_num_ce;

 

library plbv46_slave_single_v1_01_a;

 

library s2imac_epc_v1_02_a;




-------------------------------------------------------------------------------
--                     Definition of Generics
-------------------------------------------------------------------------------
-- C_BASEADDR               -- User logic base address
-- C_HIGHADDR               -- User logic high address
-- C_SPLB_AWIDTH            -- PLBv46 address bus width
-- C_SPLB_DWIDTH            -- PLBv46 data bus width
-- C_FAMILY                 -- Default family
-- C_SPLB_P2P               -- Selects point-to-point or shared plb topology
-- C_SPLB_MID_WIDTH         -- PLB Master ID Bus Width
-- C_SPLB_NUM_MASTERS       -- Number of PLB Masters
-- C_SPLB_NATIVE_DWIDTH     -- Width of the slave data bus
   ------------------------------------------------------
-- C_SPLB_CLK_PERIOD_PS      -  The clock period of PLB Clock in picoseconds
-- C_PRH_CLK_PERIOD_PS      -  The clock period of peripheral clock in
--                             picoseconds
   ------------------------------------------------------
-- C_INTERRUPT_PRESENT      -  Support Interrupt
-- C_NUM_PERIPHERALS        -  Number of external devices connected to PLB EPC
-- C_PRH_MAX_AWIDTH         -  Maximum of address bus width of all peripherals
-- C_PRH_MAX_DWIDTH         -  Maximum of data bus width of all peripherals
-- C_PRH_MAX_ADWIDTH        -  Maximum of data bus width of all peripherals
--                             and address bus width of peripherals employing
--                             multiplexed address/data bus
-- C_PRH_CLK_SUPPORT        -  Indication of whether the synchronous interface
--                             operates on peripheral clock or on PLB clock
-- C_PRH_BURST_SUPPORT      -  Indicates if the PLB EPC supports burst
-- C_PRH(0:3)_BASEADDR      -  External peripheral (0:3) base address
-- C_PRH(0:3)_HIGHADDR      -  External peripheral (0:3) high address
-- C_PRH(0:3)_FIFO_ACCESS   -  Indicates if the support for accessing FIFO
--                             like structure within external device is
--                             required
-- C_PRH(0:3)_FIFO_OFFSET   -  Byte offset of FIFO from the base address
--                             assigned to peripheral
-- C_PRH(0:3)_AWIDTH        -  External peripheral (0:3) address bus width
-- C_PRH(0:3)_DWIDTH        -  External peripheral (0:3) data bus width
-- C_PRH(0:3)_DWIDTH_MATCH  -  Indication of whether external peripheral (0:3)
--                             supports multiple access cycle on the
--                             peripheral interface for a single PLB cycle
--                             when the peripheral data bus width is less than
--                             that of PLB bus data width
-- C_PRH(0:3)_SYNC          -  Indicates if the external device (0:3) uses
--                             synchronous or asynchronous interface
-- C_PRH(0:3)_BUS_MULTIPLEX -  Indicates if the external device (0:3) uses a
--                             multiplexed or non-multiplexed device
-- C_PRH(0:3)_ADDR_TSU      -  External device (0:3) address setup time with
--                             respect  to rising edge of address strobe
--                             (multiplexed address and data bus) or falling
--                             edge of  read/write signal (non-multiplexed
--                             address/data bus)
-- C_PRH(0:3)_ADDR_TH       -  External device (0:3) address hold time with
--                             respect to rising edge of address strobe
--                             (multiplexed address and data bus) or rising
--                             edge of read/write signal (non-multiplexed
--                             address/data bus)
-- C_PRH(0:3)_ADS_WIDTH     -  Minimum pulse width of address strobe
-- C_PRH(0:3)_CSN_TSU       -  External device (0:3) chip select setup time
--                             with  respect to falling edge of read/write
--                             signal
-- C_PRH(0:3)_CSN_TH        -  External device (0:3) chip select hold time with
--                             respect to rising edge of read/write signal
-- C_PRH(0:3)_WRN_WIDTH     -  External device (0:3) write signal minimum
--                             pulse width
-- C_PRH(0:3)_WR_CYCLE      -  External device (0:3) write cycle time
-- C_PRH(0:3)_DATA_TSU      -  External device (0:3) data bus setup with
--                             respect to rising edge of write signal
-- C_PRH(0:3)_DATA_TH       -  External device (0:3) data bus hold  with
--                             respect to rising edge of write signal
-- C_PRH(0:3)_RDN_WIDTH     -  External device (0:3) read signal minimum
--                             pulse width
-- C_PRH(0:3)_RD_CYCLE      -  External device (0:3) read cycle time
-- C_PRH(0:3)_DATA_TOUT     -  External device (0:3) data bus validity with
--                             respect to falling edge of read signal
-- C_PRH(0:3)_DATA_TINV     -  External device (0:3) data bus high impedence
--                             with respect to rising edge of read signal
-- C_PRH(0:3)_RDY_TOUT      -  External device (0:3) device ready validity from
--                             falling edge of read/write signal
-- C_PRH(0:3)_RDY_WIDTH     -  Maximum wait period for external device (0:3)
--                             ready signal assertion

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--                  Definition of Ports
-------------------------------------------------------------------------------

------------------------------------------
-- PLB_ABus          -- Each master is required to provide a valid 32-bit
--                   -- address when its request signal is asserted. The PLB
--                   -- will then arbitrate the requests and allow the highest
--                   -- priority master’s address to be gated onto the PLB_ABus
-- PLB_PAValid       -- This signal is asserted by the PLB arbiter in response
--                   -- to the assertion of Mn_request and to indicate
--                   -- that there is a valid primary address and transfer
--                   -- qualifiers on the PLB outputs
-- PLB_masterID      -- These signals indicate to the slaves the identification
--                   -- of the master of the current transfer
-- PLB_RNW           -- This signal is driven by the master and is used to
--                   -- indicate whether the request is for a read or a write
--                   -- transfer
-- PLB_BE            -- These signals are driven by the master. For a non-line
--                   -- and non-burst transfer they identify which
--                   -- bytes of the target being addressed are to be read
--                   -- from or written to. Each bit corresponds to a byte
--                   -- lane on the read or write data bus
-- PLB_size          -- The PLB_size(0:3) signals are driven by the master
--                   -- to indicate the size of the requested transfer.
-- PLB_type          -- The Mn_type signals are driven by the master and are
--                   -- used to indicate to the slave, via the PLB_type
--                   -- signals, the type of transfer being requested
-- PLB_wrDBus        -- This data bus is used to transfer data between a
--                   -- master and a slave during a PLB write transfer
------------------------------------------
-- == SLAVE RESPONSE SIGNALS ==
------------------------------------------
-- Sl_addrAck        -- This signal is asserted to indicate that the
--                   -- slave has acknowledged the address and will
--                   -- latch the address
-- Sl_SSize          -- The Sl_SSize(0:1) signals are outputs of all
--                   -- non 32-bit PLB slaves. These signals are
--                   -- activated by the slave with the assertion of
--                   -- PLB_PAValid or SAValid and a valid slave
--                   -- address decode and must remain negated at
--                   -- all other times.
-- Sl_wait           -- This signal is asserted to indicate that the
--                   -- slave has recognized the PLB address as a valid address
-- Sl_rearbitrate    -- This signal is asserted to indicate that the
--                   -- slave is unable to perform the currently
--                   -- requested transfer and require the PLB arbiter
--                   -- to re-arbitrate the bus
-- Sl_wrDAck         -- This signal is driven by the slave for a write
--                   -- transfer to indicate that the data currently on the
--                   -- PLB_wrDBus bus is no longer required by the slave
--                   -- i.e. data is latched
-- Sl_wrComp         -- This signal is asserted by the slave to
--                   -- indicate the end of the current write transfer.
-- Sl_rdDBus         -- Slave read bus
-- Sl_rdDAck         -- This signal is driven by the slave to indicate
--                   -- that the data on the Sl_rdDBus bus is valid and
--                   -- must be latched at the end of the current clock cycle
-- Sl_rdComp         -- This signal is driven by the slave and is used
--                   -- to indicate to the PLB arbiter that the read
--                   -- transfer is either complete, or will be complete
--                   -- by the end of the next clock cycle
-- Sl_MBusy          -- These signals are driven by the slave and
--                   -- are used to indicate that the slave is either
--                   -- busy performing a read or a write transfer, or
--                   -- has a read or write transfer pending
-- Sl_MWrErr         -- These signals are driven by the slave and
--                   -- are used to indicate that the slave has encountered an
--                   -- error during a write transfer that was initiated
--                   -- by this master
-- Sl_MRdErr         -- These signals are driven by the slave and are
--                   -- used to indicate that the slave has encountered an
--                   -- error during a read transfer that was initiated
--                   -- by this master
-----------------------------------------------------
-- PERIPHERAL INTERFACE
-----------------------------------------------------
-- PRH_Clk              -- Peripheral interface clock
-- PRH_Rst              -- Peripheral interface reset
-- PRH_Int              -- Peripheral interface interrupt
-- PRH_CS_n             -- Peripheral interface chip select
-- PRH_Addr             -- Peripheral interface address bus
-- PRH_ADS              -- Peripheral interface address strobe
-- PRH_BE               -- Peripheral interface byte enables
-- PRH_RNW              -- Peripheral interface read/write control for
--                      -- synchronous interface
-- PRH_Rd_n             -- Peripheral interface read strobe for asynchronous
--                      -- interface
-- PRH_Wr_n             -- Peripheral interface write strobe for asynchronous
--                      -- interface
-- PRH_Burst            -- Peripheral interface burst indication signal
-- PRH_Rdy              -- Peripheral interface device ready signal
-- PRH_Data_I           -- Peripheral interface input data bus
-- PRH_Data_O           -- Peripehral interface output data bus
-- PRH_Data_T           -- 3-state control for peripheral interface output data
--                      -- bus
-----------------------------------------------------
-- SYSTEM SIGNALS
-----------------------------------------------------
-- SPLB_Clk             -- System clock
-- SPLB_Rst             -- System Reset (active high)
-- IP2INTC_Irpt         -- S2IMAC Interrupt to interrupt controller
-------------------------------------------------------------------------------

entity s2imac_epc is
  generic
  (
      C_SPLB_CLK_PERIOD_PS  : integer := 10000;
      C_PRH_CLK_PERIOD_PS   : integer := 20000;
      -----------------------------------------
      -- PLBv46 slave single block generics
      C_FAMILY                  : string                        := "virtex5";
      C_SPLB_AWIDTH             : integer range 32 to 32        := 32;
      C_SPLB_DWIDTH             : integer range 32 to 128       := 32;
      C_SPLB_P2P                : integer                       := 0;
      C_SPLB_MID_WIDTH          : integer range 0 to 4          := 1;
      C_SPLB_NUM_MASTERS        : integer range 1 to 16         := 1;
      C_SPLB_NATIVE_DWIDTH      : integer range 32 to 32        := 32;
      C_SPLB_SUPPORT_BURSTS     : integer range 0 to 0          := 0;--default
      -----------------------------------------
      C_INTERRUPT_PRESENT   : integer range 0 to 1 := 0;
      C_NUM_PERIPHERALS     : integer range 1 to 4 := 1;
      C_PRH_MAX_AWIDTH      : integer range 3 to 32:= 32;
      C_PRH_MAX_DWIDTH      : integer range 8 to 32:= 32;
      C_PRH_MAX_ADWIDTH     : integer range 8 to 32:= 32;
      C_PRH_CLK_SUPPORT     : integer range 0 to 1 := 0;
      C_PRH_BURST_SUPPORT   : integer              := 0;
      -----------------------------------------
      C_PRH0_BASEADDR       : std_logic_vector := X"FFFF_FFFF";
      C_PRH0_HIGHADDR       : std_logic_vector := X"0000_0000";

      C_PRH0_FIFO_ACCESS    : integer range 0 to 1:= 0;
      C_PRH0_FIFO_OFFSET    : integer := 0;
      C_PRH0_AWIDTH         : integer range 3 to 32:= 32;
      C_PRH0_DWIDTH         : integer range 8 to 32 := 32;
      C_PRH0_DWIDTH_MATCH   : integer range 0 to 1:= 0;
      C_PRH0_SYNC           : integer range 0 to 1:= 1;
      C_PRH0_BUS_MULTIPLEX  : integer range 0 to 1:= 0;
      C_PRH0_ADDR_TSU       : integer := 0;
      C_PRH0_ADDR_TH        : integer := 0;
      C_PRH0_ADS_WIDTH      : integer := 0;
      C_PRH0_CSN_TSU        : integer := 0;
      C_PRH0_CSN_TH         : integer := 0;
      C_PRH0_WRN_WIDTH      : integer := 0;
      C_PRH0_WR_CYCLE       : integer := 0;
      C_PRH0_DATA_TSU       : integer := 0;
      C_PRH0_DATA_TH        : integer := 0;
      C_PRH0_RDN_WIDTH      : integer := 0;
      C_PRH0_RD_CYCLE       : integer := 0;
      C_PRH0_DATA_TOUT      : integer := 0;
      C_PRH0_DATA_TINV      : integer := 0;
      C_PRH0_RDY_TOUT       : integer := 0;
      C_PRH0_RDY_WIDTH      : integer := 0;

      -----------------------------------------
      C_PRH1_BASEADDR       : std_logic_vector := X"FFFF_FFFF";
      C_PRH1_HIGHADDR       : std_logic_vector := X"0000_0000";

      C_PRH1_FIFO_ACCESS    : integer range 0 to 1:= 0;
      C_PRH1_FIFO_OFFSET    : integer := 0;
      C_PRH1_AWIDTH         : integer range 3 to 32:= 32;
      C_PRH1_DWIDTH         : integer range 8 to 32 := 32;
      C_PRH1_DWIDTH_MATCH   : integer range 0 to 1:= 0;
      C_PRH1_SYNC           : integer range 0 to 1:= 1;
      C_PRH1_BUS_MULTIPLEX  : integer range 0 to 1:= 0;
      C_PRH1_ADDR_TSU       : integer := 0;
      C_PRH1_ADDR_TH        : integer := 0;
      C_PRH1_ADS_WIDTH      : integer := 0;
      C_PRH1_CSN_TSU        : integer := 0;
      C_PRH1_CSN_TH         : integer := 0;
      C_PRH1_WRN_WIDTH      : integer := 0;
      C_PRH1_WR_CYCLE       : integer := 0;
      C_PRH1_DATA_TSU       : integer := 0;
      C_PRH1_DATA_TH        : integer := 0;
      C_PRH1_RDN_WIDTH      : integer := 0;
      C_PRH1_RD_CYCLE       : integer := 0;
      C_PRH1_DATA_TOUT      : integer := 0;
      C_PRH1_DATA_TINV      : integer := 0;
      C_PRH1_RDY_TOUT       : integer := 0;
      C_PRH1_RDY_WIDTH      : integer := 0;

      -----------------------------------------
      C_PRH2_BASEADDR       : std_logic_vector := X"FFFF_FFFF";
      C_PRH2_HIGHADDR       : std_logic_vector := X"0000_0000";

      C_PRH2_FIFO_ACCESS    : integer range 0 to 1:= 0;
      C_PRH2_FIFO_OFFSET    : integer := 0;
      C_PRH2_AWIDTH         : integer range 3 to 32:= 32;
      C_PRH2_DWIDTH         : integer range 8 to 32 := 32;
      C_PRH2_DWIDTH_MATCH   : integer range 0 to 1:= 0;
      C_PRH2_SYNC           : integer range 0 to 1:= 1;
      C_PRH2_BUS_MULTIPLEX  : integer range 0 to 1:= 0;
      C_PRH2_ADDR_TSU       : integer := 0;
      C_PRH2_ADDR_TH        : integer := 0;
      C_PRH2_ADS_WIDTH      : integer := 0;
      C_PRH2_CSN_TSU        : integer := 0;
      C_PRH2_CSN_TH         : integer := 0;
      C_PRH2_WRN_WIDTH      : integer := 0;
      C_PRH2_WR_CYCLE       : integer := 0;
      C_PRH2_DATA_TSU       : integer := 0;
      C_PRH2_DATA_TH        : integer := 0;
      C_PRH2_RDN_WIDTH      : integer := 0;
      C_PRH2_RD_CYCLE       : integer := 0;
      C_PRH2_DATA_TOUT      : integer := 0;
      C_PRH2_DATA_TINV      : integer := 0;
      C_PRH2_RDY_TOUT       : integer := 0;
      C_PRH2_RDY_WIDTH      : integer := 0;

      -----------------------------------------
      C_PRH3_BASEADDR       : std_logic_vector := X"FFFF_FFFF";
      C_PRH3_HIGHADDR       : std_logic_vector := X"0000_0000";

      C_PRH3_FIFO_ACCESS    : integer range 0 to 1:= 0;
      C_PRH3_FIFO_OFFSET    : integer := 0;
      C_PRH3_AWIDTH         : integer range 3 to 32:= 32;
      C_PRH3_DWIDTH         : integer range 8 to 32 := 32;
      C_PRH3_DWIDTH_MATCH   : integer range 0 to 1:= 0;
      C_PRH3_SYNC           : integer range 0 to 1:= 1;
      C_PRH3_BUS_MULTIPLEX  : integer range 0 to 1:= 0;
      C_PRH3_ADDR_TSU       : integer := 0;
      C_PRH3_ADDR_TH        : integer := 0;
      C_PRH3_ADS_WIDTH      : integer := 0;
      C_PRH3_CSN_TSU        : integer := 0;
      C_PRH3_CSN_TH         : integer := 0;
      C_PRH3_WRN_WIDTH      : integer := 0;
      C_PRH3_WR_CYCLE       : integer := 0;
      C_PRH3_DATA_TSU       : integer := 0;
      C_PRH3_DATA_TH        : integer := 0;
      C_PRH3_RDN_WIDTH      : integer := 0;
      C_PRH3_RD_CYCLE       : integer := 0;
      C_PRH3_DATA_TOUT      : integer := 0;
      C_PRH3_DATA_TINV      : integer := 0;
      C_PRH3_RDY_TOUT       : integer := 0;
      C_PRH3_RDY_WIDTH      : integer := 0
      -----------------------------------------
  );
  port
  (
    -- System interface
    --PLBv46 SLAVE SINGLE INTERFACE
    SPLB_Clk                : in  std_logic;
    SPLB_Rst                : in  std_logic;
    -- Bus slave signals
    PLB_ABus                : in  std_logic_vector(0 to C_SPLB_AWIDTH-1);
    PLB_PAValid             : in  std_logic;
    PLB_masterID            : in  std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
    PLB_RNW                 : in  std_logic;
    PLB_BE                  : in  std_logic_vector(0 to (C_SPLB_DWIDTH/8)-1);
    PLB_size                : in  std_logic_vector(0 to 3);
    PLB_type                : in  std_logic_vector(0 to 2);
    PLB_wrDBus              : in  std_logic_vector(0 to C_SPLB_DWIDTH-1);

    -- Unused Bus slave signals
    PLB_UABus               : in  std_logic_vector(0 to 31);
    PLB_SAValid             : in  std_logic;
    PLB_rdPrim              : in  std_logic;
    PLB_wrPrim              : in  std_logic;
    PLB_abort               : in  std_logic;
    PLB_busLock             : in  std_logic;
    PLB_MSize               : in  std_logic_vector(0 to 1);
    PLB_lockErr             : in  std_logic;
    PLB_wrBurst             : in  std_logic;
    PLB_rdBurst             : in  std_logic;
    PLB_wrPendReq           : in  std_logic;
    PLB_rdPendReq           : in  std_logic;
    PLB_wrPendPri           : in  std_logic_vector(0 to 1);
    PLB_rdPendPri           : in  std_logic_vector(0 to 1);
    PLB_reqPri              : in  std_logic_vector(0 to 1);
    PLB_TAttribute          : in  std_logic_vector(0 to 15);

    --slave response signals to PLB
    Sl_addrAck              : out std_logic;
    Sl_SSize                : out std_logic_vector(0 to 1);
    Sl_wait                 : out std_logic;
    Sl_rearbitrate          : out std_logic;
    Sl_wrDAck               : out std_logic;
    Sl_wrComp               : out std_logic;
    Sl_rdDBus               : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
    Sl_rdDAck               : out std_logic;
    Sl_rdComp               : out std_logic;
    Sl_MBusy                : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MWrErr               : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MRdErr               : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);

    -- Unused Slave Response Signals
    Sl_wrBTerm              : out std_logic;
    Sl_rdWdAddr             : out std_logic_vector(0 to 3);
    Sl_rdBTerm              : out std_logic;
    Sl_MIRQ                 : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);

    -- Interrupt---------------------------------------------------------------
    IP2INTC_Irpt            : out std_logic;

      -- Peripheral interface
    PRH_Clk                 : in std_logic;
    PRH_Rst                 : in std_logic;
    PRH_Int                 : in std_logic;

    PRH_CS_n                : out std_logic_vector(0 to C_NUM_PERIPHERALS-1);
    PRH_Addr                : out std_logic_vector(0 to C_PRH_MAX_AWIDTH-1);
    PRH_ADS                 : out std_logic;
    PRH_BE                  : out std_logic_vector(0 to C_PRH_MAX_DWIDTH/8-1);
    PRH_RNW                 : out std_logic;
    PRH_Rd_n                : out std_logic;
    PRH_Wr_n                : out std_logic;
    PRH_Burst               : out std_logic;

    PRH_Rdy                 : in std_logic_vector(0 to C_NUM_PERIPHERALS-1);

    PRH_Data_I              : in std_logic_vector(0 to C_PRH_MAX_ADWIDTH-1);
    PRH_Data_O              : out std_logic_vector(0 to C_PRH_MAX_ADWIDTH-1);
    PRH_Data_T              : out std_logic_vector(0 to C_PRH_MAX_ADWIDTH-1)
  );

-------------------------------------------------------------------------------
-- Attributes
-------------------------------------------------------------------------------

  -- Fan-Out attributes for XST

  ATTRIBUTE MAX_FANOUT                           : string;
  ATTRIBUTE MAX_FANOUT   of SPLB_Clk             : signal is "10000";
  ATTRIBUTE MAX_FANOUT   of SPLB_Rst             : signal is "10000";
  ATTRIBUTE MAX_FANOUT   of PRH_Clk              : signal is "10000";
  ATTRIBUTE MAX_FANOUT   of PRH_Rst              : signal is "10000";

  -----------------------------------------------------------------
  -- Start of PSFUtil MPD attributes
  -----------------------------------------------------------------

  ATTRIBUTE SIGIS                                : string;
  ATTRIBUTE SIGIS of SPLB_Clk                    : signal is "Clk";
  ATTRIBUTE SIGIS of SPLB_Rst                    : signal is "Rst";
  ATTRIBUTE SIGIS of PRH_Clk                     : signal is "Clk";
  ATTRIBUTE SIGIS of PRH_Rst                     : signal is "Rst";
  ATTRIBUTE SIGIS of IP2INTC_Irpt                : signal is "INTR_LEVEL_HIGH";

  ATTRIBUTE XRANGE                               : string;
  ATTRIBUTE XRANGE of C_NUM_PERIPHERALS          : constant is "(1:4)";
  ATTRIBUTE XRANGE of C_PRH_BURST_SUPPORT        : constant is "(0,1)";
  ATTRIBUTE XRANGE of C_PRH_CLK_SUPPORT          : constant is "(0,1)";
  ATTRIBUTE XRANGE of C_PRH0_DWIDTH_MATCH        : constant is "(0,1)";
  ATTRIBUTE XRANGE of C_PRH1_DWIDTH_MATCH        : constant is "(0,1)";
  ATTRIBUTE XRANGE of C_PRH2_DWIDTH_MATCH        : constant is "(0,1)";
  ATTRIBUTE XRANGE of C_PRH3_DWIDTH_MATCH        : constant is "(0,1)";
  ATTRIBUTE XRANGE of C_PRH0_BUS_MULTIPLEX       : constant is "(0,1)";
  ATTRIBUTE XRANGE of C_PRH1_BUS_MULTIPLEX       : constant is "(0,1)";
  ATTRIBUTE XRANGE of C_PRH2_BUS_MULTIPLEX       : constant is "(0,1)";
  ATTRIBUTE XRANGE of C_PRH3_BUS_MULTIPLEX       : constant is "(0,1)";
  ATTRIBUTE XRANGE of C_PRH0_SYNC                : constant is "(0,1)";
  ATTRIBUTE XRANGE of C_PRH1_SYNC                : constant is "(0,1)";
  ATTRIBUTE XRANGE of C_PRH2_SYNC                : constant is "(0,1)";
  ATTRIBUTE XRANGE of C_PRH3_SYNC                : constant is "(0,1)";

  ATTRIBUTE XRANGE of C_PRH0_DWIDTH              : constant is "(8,16,32)";
  ATTRIBUTE XRANGE of C_PRH1_DWIDTH              : constant is "(8,16,32)";
  ATTRIBUTE XRANGE of C_PRH2_DWIDTH              : constant is "(8,16,32)";
  ATTRIBUTE XRANGE of C_PRH3_DWIDTH              : constant is "(8,16,32)";
  ATTRIBUTE XRANGE of C_PRH_MAX_AWIDTH           : constant is "(3:32)";
  ATTRIBUTE XRANGE of C_PRH_MAX_DWIDTH           : constant is "(8,16,32)";
  ATTRIBUTE XRANGE of C_PRH_MAX_ADWIDTH          : constant is "(8:32)";

  -----------------------------------------------------------------
  -- end of PSFUtil MPD attributes
  -----------------------------------------------------------------
end entity s2imac_epc;

-------------------------------------------------------------------------------
-- Architecture Section
-------------------------------------------------------------------------------

architecture imp of s2imac_epc is

-------------------------------------------------------------------------------
-- Function Declarations
-------------------------------------------------------------------------------
-- NAME: get_effective_val
-------------------------------------------------------------------------------
-- Description: Given two possible values that can be taken by an item and a
--              generic setting that affects the actual value taken by the
--              item, this function  returns the effective value taken by the
--              item depending on the value of the generic. This function
--              is used to calculate the effective data bus width based on
--              data bus width matching generic (C_PRHx_DWIDTH_MATCH) and
--              effective clock period of peripheral clock based on peripheral
--              clock support generic (C_PRH_CLK_SUPPORT)
-------------------------------------------------------------------------------
function get_effective_val(generic_val : integer;
                           value_1     : integer;
                           value_2     : integer)
                           return integer is
    variable effective_val : integer;
begin
    if generic_val = 0 then
        effective_val := value_1;
    else
        effective_val := value_2;
    end if;

return effective_val;
end function get_effective_val;
-------------------------------------------------------------------------------
-- NAME: get_ard_integer_array
-------------------------------------------------------------------------------
-- Description: Given an integer N, and an unconstrained INTEGER_ARRAY return
--              a constrained array of size N with the first N elements of the
--              input array. This function is used to construct IPIF generic
--              ARD_ID_ARRAY, ARD_DWIDTH_ARRAY, ARD_NUM_CE_ARRAY etc.
-------------------------------------------------------------------------------
function get_ard_integer_array( num_peripherals : integer;
                                prh_parameter   : INTEGER_ARRAY_TYPE )
                                return INTEGER_ARRAY_TYPE is

variable integer_array : INTEGER_ARRAY_TYPE(0 to num_peripherals-1);

begin
       for i in 0 to (num_peripherals - 1) loop
         integer_array(i) := prh_parameter(i);
       end loop;

return integer_array;
end function get_ard_integer_array;

-------------------------------------------------------------------------------
-- NAME: get_ard_address_range_array
-------------------------------------------------------------------------------
-- Description: Given an integer N, and an unconstrained INTEGER_ARRAY return
--              a constrained array of size N*2 with the first N*2 elements of
--              the input array. This function is used to construct IPIF
--              generic ARD_ADDR_RANGE_ARRAY
-------------------------------------------------------------------------------
function get_ard_addr_range_array ( num_peripherals      : integer;
                                    prh_addr_range_array : SLV64_ARRAY_TYPE)
                                    return SLV64_ARRAY_TYPE is

variable addr_range_array : SLV64_ARRAY_TYPE(0 to ((num_peripherals * 2) -1));

begin

    for i in 0 to (num_peripherals - 1) loop
       addr_range_array(i*2) := prh_addr_range_array(i*2);
       addr_range_array((i*2)+1) := prh_addr_range_array((i*2)+1);
    end loop;

return addr_range_array;

end function get_ard_addr_range_array;
-------------------------------------------------------------------------------
-- Type Declarations
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
constant MAX_PERIPHERALS : integer := 4;
constant ZERO_ADDR_PAD   : std_logic_vector(0 to 64-C_SPLB_AWIDTH-1)
                         := (others => '0');

constant PRH_ADDR_RANGE_ARRAY : SLV64_ARRAY_TYPE :=
         (
          ZERO_ADDR_PAD & C_PRH0_BASEADDR,
          ZERO_ADDR_PAD & C_PRH0_HIGHADDR,
          ZERO_ADDR_PAD & C_PRH1_BASEADDR,
          ZERO_ADDR_PAD & C_PRH1_HIGHADDR,
          ZERO_ADDR_PAD & C_PRH2_BASEADDR,
          ZERO_ADDR_PAD & C_PRH2_HIGHADDR,
          ZERO_ADDR_PAD & C_PRH3_BASEADDR,
          ZERO_ADDR_PAD & C_PRH3_HIGHADDR
          );

constant ARD_ADDR_RANGE_ARRAY : SLV64_ARRAY_TYPE :=
                                get_ard_addr_range_array(
                                                         C_NUM_PERIPHERALS,
                                                         PRH_ADDR_RANGE_ARRAY
                                                         );

constant PRH_NUM_CE_ARRAY : INTEGER_ARRAY_TYPE(0 to MAX_PERIPHERALS-1) :=
                            (others => 1);

constant ARD_NUM_CE_ARRAY : INTEGER_ARRAY_TYPE :=
                            get_ard_integer_array(
                                                  C_NUM_PERIPHERALS,
                                                  PRH_NUM_CE_ARRAY
                                                  );

constant PRH_DWIDTH_ARRAY : INTEGER_ARRAY_TYPE :=
    (
    get_effective_val(C_PRH0_DWIDTH_MATCH,C_PRH0_DWIDTH,C_SPLB_NATIVE_DWIDTH),
    get_effective_val(C_PRH1_DWIDTH_MATCH,C_PRH1_DWIDTH,C_SPLB_NATIVE_DWIDTH),
    get_effective_val(C_PRH2_DWIDTH_MATCH,C_PRH2_DWIDTH,C_SPLB_NATIVE_DWIDTH),
    get_effective_val(C_PRH3_DWIDTH_MATCH,C_PRH3_DWIDTH,C_SPLB_NATIVE_DWIDTH)
    );

constant NUM_ARD : integer := (ARD_ADDR_RANGE_ARRAY'LENGTH/2);
constant NUM_CE : integer := calc_num_ce(ARD_NUM_CE_ARRAY);

constant PRH0_FIFO_OFFSET : std_logic_vector(0 to C_SPLB_AWIDTH-1) :=
         conv_std_logic_vector(C_PRH0_FIFO_OFFSET,C_SPLB_AWIDTH);
constant PRH1_FIFO_OFFSET : std_logic_vector(0 to C_SPLB_AWIDTH-1) :=
         conv_std_logic_vector(C_PRH1_FIFO_OFFSET,C_SPLB_AWIDTH);
constant PRH2_FIFO_OFFSET : std_logic_vector(0 to C_SPLB_AWIDTH-1) :=
         conv_std_logic_vector(C_PRH2_FIFO_OFFSET,C_SPLB_AWIDTH);
constant PRH3_FIFO_OFFSET : std_logic_vector(0 to C_SPLB_AWIDTH-1) :=
         conv_std_logic_vector(C_PRH3_FIFO_OFFSET,C_SPLB_AWIDTH);


constant PRH0_FIFO_ADDRESS : std_logic_vector(0 to C_SPLB_AWIDTH-1) :=
         C_PRH0_BASEADDR or PRH0_FIFO_OFFSET;
constant PRH1_FIFO_ADDRESS : std_logic_vector(0 to C_SPLB_AWIDTH-1) :=
         C_PRH1_BASEADDR or PRH1_FIFO_OFFSET;
constant PRH2_FIFO_ADDRESS : std_logic_vector(0 to C_SPLB_AWIDTH-1) :=
         C_PRH2_BASEADDR or PRH2_FIFO_OFFSET;
constant PRH3_FIFO_ADDRESS : std_logic_vector(0 to C_SPLB_AWIDTH-1) :=
         C_PRH3_BASEADDR or PRH3_FIFO_OFFSET;

constant LOCAL_CLK_PERIOD_PS : integer :=
  get_effective_val(C_PRH_CLK_SUPPORT,C_SPLB_CLK_PERIOD_PS,C_PRH_CLK_PERIOD_PS);

-------------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------
--bus2ip signals
signal bus2ip_clk       : std_logic;
signal bus2ip_reset     : std_logic;

signal bus2ip_cs        : std_logic_vector(0 to (ARD_ADDR_RANGE_ARRAY'LENGTH/2)-1);
signal bus2ip_rdce      : std_logic_vector(0 to NUM_CE-1);
signal bus2ip_wrce      : std_logic_vector(0 to NUM_CE-1);
signal bus2ip_addr      : std_logic_vector(0 to C_SPLB_AWIDTH - 1);
signal bus2ip_rnw       : std_logic;
signal bus2ip_be        : std_logic_vector(0 to (C_SPLB_NATIVE_DWIDTH / 8) - 1);
signal bus2ip_data      : std_logic_vector(0 to C_SPLB_NATIVE_DWIDTH - 1);

-- ip2bus signals
signal ip2bus_data      : std_logic_vector(0 to C_SPLB_NATIVE_DWIDTH - 1);
signal ip2bus_wrack     : std_logic;
signal ip2bus_rdack     : std_logic;
signal ip2bus_error     : std_logic;
-- local clock and reset signals
signal local_clk        : std_logic;
signal local_rst        : std_logic;
-- local signals
signal dev_bus2ip_cs    : std_logic_vector(0 to C_NUM_PERIPHERALS-1);
signal dev_bus2ip_rdce  : std_logic_vector(0 to C_NUM_PERIPHERALS-1);
signal dev_bus2ip_wrce  : std_logic_vector(0 to C_NUM_PERIPHERALS-1);
signal dev_bus2ip_addr  : std_logic_vector(0 to C_PRH_MAX_AWIDTH-1);

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------

begin

-------------------------------------------------------------------------------
-- NAME: NO_LCLK_LRST_GEN
-------------------------------------------------------------------------------
-- Description: When the C_PRH_CLK_SUPPORT is disabled use PLB clock and
--              PLB reset as the local clock and local reset respectively.
--              The syncrhonous control logic operates on local clock.
-------------------------------------------------------------------------------
NO_LCLK_LRST_GEN: if  C_PRH_CLK_SUPPORT = 0 generate
  local_clk <= bus2ip_clk;
  local_rst <= bus2ip_reset;
end generate NO_LCLK_LRST_GEN;
-------------------------------------------------------------------------------
-- NAME: LCLK_LRST_GEN
-------------------------------------------------------------------------------
-- Description: When the C_PRH_CLK_SUPPORT is enabled use external peripheral
--              clock and peripheral reset as the local clock and local reset
--              respectively. The syncrhonous control logic operates on local
--              clock.
-------------------------------------------------------------------------------
LCLK_LRST_GEN: if  C_PRH_CLK_SUPPORT /= 0 generate
  local_clk <= PRH_Clk;
  local_rst <= PRH_Rst;
end generate LCLK_LRST_GEN;
-------------------------------------------------------------------------------

----------------------------------
-- INSTANTIATE PLBv46 SLAVE SINGLE
----------------------------------
   PLBv46_IPIF_I : entity plbv46_slave_single_v1_01_a.plbv46_slave_single
     generic map
      (
       C_BUS2CORE_CLK_RATIO        => 1,
       C_INCLUDE_DPHASE_TIMER      => 1,
       C_ARD_ADDR_RANGE_ARRAY      => ARD_ADDR_RANGE_ARRAY,
       C_ARD_NUM_CE_ARRAY          => ARD_NUM_CE_ARRAY,
       C_SPLB_P2P                  => C_SPLB_P2P,
       C_SPLB_MID_WIDTH            => C_SPLB_MID_WIDTH,
       C_SPLB_NUM_MASTERS          => C_SPLB_NUM_MASTERS,
       C_SPLB_AWIDTH               => C_SPLB_AWIDTH,
       C_SPLB_DWIDTH               => C_SPLB_DWIDTH,
       C_SIPIF_DWIDTH              => C_SPLB_NATIVE_DWIDTH,
       C_FAMILY                    => C_FAMILY
      )
     port map
      (
      -- System signals ---------------------------------------------------
      SPLB_Clk                     => SPLB_Clk,
      SPLB_Rst                     => SPLB_Rst,
      -- Bus Slave signals ------------------------------------------------
      PLB_ABus                     => PLB_ABus,
      PLB_UABus                    => PLB_UABus,
      PLB_PAValid                  => PLB_PAValid,
      PLB_SAValid                  => PLB_SAValid,
      PLB_rdPrim                   => PLB_rdPrim,
      PLB_wrPrim                   => PLB_wrPrim,
      PLB_masterID                 => PLB_masterID,
      PLB_abort                    => PLB_abort,
      PLB_busLock                  => PLB_busLock,
      PLB_RNW                      => PLB_RNW,
      PLB_BE                       => PLB_BE,
      PLB_MSize                    => PLB_MSize,
      PLB_size                     => PLB_size,
      PLB_type                     => PLB_type,
      PLB_lockErr                  => PLB_lockErr,
      PLB_wrDBus                   => PLB_wrDBus,
      PLB_wrBurst                  => PLB_wrBurst,
      PLB_rdBurst                  => PLB_rdBurst,
      PLB_wrPendReq                => PLB_wrPendReq,
      PLB_rdPendReq                => PLB_rdPendReq,
      PLB_wrPendPri                => PLB_wrPendPri,
      PLB_rdPendPri                => PLB_rdPendPri,
      PLB_reqPri                   => PLB_reqPri,
      PLB_TAttribute               => PLB_TAttribute,
      -- Slave Response Signals -------------------------------------------
      Sl_addrAck                   => Sl_addrAck,
      Sl_SSize                     => Sl_SSize,
      Sl_wait                      => Sl_wait,
      Sl_rearbitrate               => Sl_rearbitrate,
      Sl_wrDAck                    => Sl_wrDAck,
      Sl_wrComp                    => Sl_wrComp,
      Sl_wrBTerm                   => Sl_wrBTerm,
      Sl_rdDBus                    => Sl_rdDBus,
      Sl_rdWdAddr                  => Sl_rdWdAddr,
      Sl_rdDAck                    => Sl_rdDAck,
      Sl_rdComp                    => Sl_rdComp,
      Sl_rdBTerm                   => Sl_rdBTerm,
      Sl_MBusy                     => Sl_MBusy,
      Sl_MWrErr                    => Sl_MWrErr,
      Sl_MRdErr                    => Sl_MRdErr,
      Sl_MIRQ                      => Sl_MIRQ,
      -- IP Interconnect (IPIC) port signals ------------------------------
      Bus2IP_Clk                   => bus2ip_clk,
      Bus2IP_Reset                 => bus2ip_reset,

      Bus2IP_CS                    => bus2IP_CS,
      Bus2IP_RdCE                  => bus2IP_RdCE,
      Bus2IP_WrCE                  => bus2IP_WrCE,
      Bus2IP_Addr                  => bus2ip_addr,
      Bus2IP_RNW                   => bus2ip_rnw,
      Bus2IP_BE                    => bus2ip_be,
      Bus2IP_Data                  => bus2ip_data,
      -- ip2bus signals ---------------------------------------------------
      IP2Bus_Data                  => ip2bus_data,
      IP2Bus_WrAck                 => ip2bus_wrack,
      IP2Bus_RdAck                 => ip2bus_rdack,
      IP2Bus_Error                 => ip2bus_error

      );

EPC_CORE_I : entity s2imac_epc_v1_02_a.epc_core
  generic map
  (
      C_SPLB_CLK_PERIOD_PS         =>  C_SPLB_CLK_PERIOD_PS,
      LOCAL_CLK_PERIOD_PS          =>  LOCAL_CLK_PERIOD_PS,
            ----------------       -------------------------
      C_SPLB_AWIDTH                =>  C_SPLB_AWIDTH,
      C_SPLB_NATIVE_DWIDTH         =>  C_SPLB_NATIVE_DWIDTH,
      C_SPLB_DWIDTH                =>  C_SPLB_DWIDTH,
      C_FAMILY                     =>  C_FAMILY,
            ----------------       -------------------------
      C_INTERRUPT_PRESENT          =>  C_INTERRUPT_PRESENT,
      C_NUM_PERIPHERALS            =>  C_NUM_PERIPHERALS,
      C_PRH_MAX_AWIDTH             =>  C_PRH_MAX_AWIDTH,
      C_PRH_MAX_DWIDTH             =>  C_PRH_MAX_DWIDTH,
      C_PRH_MAX_ADWIDTH            =>  C_PRH_MAX_ADWIDTH,
      C_PRH_CLK_SUPPORT            =>  C_PRH_CLK_SUPPORT,
      C_PRH_BURST_SUPPORT          =>  C_PRH_BURST_SUPPORT,
            ----------------       -------------------------
      C_PRH0_FIFO_ACCESS           =>  C_PRH0_FIFO_ACCESS,
      C_PRH0_AWIDTH                =>  C_PRH0_AWIDTH,
      C_PRH0_DWIDTH                =>  C_PRH0_DWIDTH,
      C_PRH0_DWIDTH_MATCH          =>  C_PRH0_DWIDTH_MATCH,
      C_PRH0_SYNC                  =>  C_PRH0_SYNC,
      C_PRH0_BUS_MULTIPLEX         =>  C_PRH0_BUS_MULTIPLEX,
      C_PRH0_ADDR_TSU              =>  C_PRH0_ADDR_TSU,
      C_PRH0_ADDR_TH               =>  C_PRH0_ADDR_TH,
      C_PRH0_ADS_WIDTH             =>  C_PRH0_ADS_WIDTH,
      C_PRH0_CSN_TSU               =>  C_PRH0_CSN_TSU,
      C_PRH0_CSN_TH                =>  C_PRH0_CSN_TH,
      C_PRH0_WRN_WIDTH             =>  C_PRH0_WRN_WIDTH,
      C_PRH0_WR_CYCLE              =>  C_PRH0_WR_CYCLE,
      C_PRH0_DATA_TSU              =>  C_PRH0_DATA_TSU,
      C_PRH0_DATA_TH               =>  C_PRH0_DATA_TH,
      C_PRH0_RDN_WIDTH             =>  C_PRH0_RDN_WIDTH,
      C_PRH0_RD_CYCLE              =>  C_PRH0_RD_CYCLE,
      C_PRH0_DATA_TOUT             =>  C_PRH0_DATA_TOUT,
      C_PRH0_DATA_TINV             =>  C_PRH0_DATA_TINV,
      C_PRH0_RDY_TOUT              =>  C_PRH0_RDY_TOUT,
      C_PRH0_RDY_WIDTH             =>  C_PRH0_RDY_WIDTH,
            ----------------       -------------------------
      C_PRH1_FIFO_ACCESS           =>  C_PRH1_FIFO_ACCESS,
      C_PRH1_AWIDTH                =>  C_PRH1_AWIDTH,
      C_PRH1_DWIDTH                =>  C_PRH1_DWIDTH,
      C_PRH1_DWIDTH_MATCH          =>  C_PRH1_DWIDTH_MATCH,
      C_PRH1_SYNC                  =>  C_PRH1_SYNC,
      C_PRH1_BUS_MULTIPLEX         =>  C_PRH1_BUS_MULTIPLEX,
      C_PRH1_ADDR_TSU              =>  C_PRH1_ADDR_TSU,
      C_PRH1_ADDR_TH               =>  C_PRH1_ADDR_TH,
      C_PRH1_ADS_WIDTH             =>  C_PRH1_ADS_WIDTH,
      C_PRH1_CSN_TSU               =>  C_PRH1_CSN_TSU,
      C_PRH1_CSN_TH                =>  C_PRH1_CSN_TH,
      C_PRH1_WRN_WIDTH             =>  C_PRH1_WRN_WIDTH,
      C_PRH1_WR_CYCLE              =>  C_PRH1_WR_CYCLE,
      C_PRH1_DATA_TSU              =>  C_PRH1_DATA_TSU,
      C_PRH1_DATA_TH               =>  C_PRH1_DATA_TH,
      C_PRH1_RDN_WIDTH             =>  C_PRH1_RDN_WIDTH,
      C_PRH1_RD_CYCLE              =>  C_PRH1_RD_CYCLE,
      C_PRH1_DATA_TOUT             =>  C_PRH1_DATA_TOUT,
      C_PRH1_DATA_TINV             =>  C_PRH1_DATA_TINV,
      C_PRH1_RDY_TOUT              =>  C_PRH1_RDY_TOUT,
      C_PRH1_RDY_WIDTH             =>  C_PRH1_RDY_WIDTH,
            ----------------       -------------------------
      C_PRH2_FIFO_ACCESS           =>  C_PRH2_FIFO_ACCESS,
      C_PRH2_AWIDTH                =>  C_PRH2_AWIDTH,
      C_PRH2_DWIDTH                =>  C_PRH2_DWIDTH,
      C_PRH2_DWIDTH_MATCH          =>  C_PRH2_DWIDTH_MATCH,
      C_PRH2_SYNC                  =>  C_PRH2_SYNC,
      C_PRH2_BUS_MULTIPLEX         =>  C_PRH2_BUS_MULTIPLEX,
      C_PRH2_ADDR_TSU              =>  C_PRH2_ADDR_TSU,
      C_PRH2_ADDR_TH               =>  C_PRH2_ADDR_TH,
      C_PRH2_ADS_WIDTH             =>  C_PRH2_ADS_WIDTH,
      C_PRH2_CSN_TSU               =>  C_PRH2_CSN_TSU,
      C_PRH2_CSN_TH                =>  C_PRH2_CSN_TH,
      C_PRH2_WRN_WIDTH             =>  C_PRH2_WRN_WIDTH,
      C_PRH2_WR_CYCLE              =>  C_PRH2_WR_CYCLE,
      C_PRH2_DATA_TSU              =>  C_PRH2_DATA_TSU,
      C_PRH2_DATA_TH               =>  C_PRH2_DATA_TH,
      C_PRH2_RDN_WIDTH             =>  C_PRH2_RDN_WIDTH,
      C_PRH2_RD_CYCLE              =>  C_PRH2_RD_CYCLE,
      C_PRH2_DATA_TOUT             =>  C_PRH2_DATA_TOUT,
      C_PRH2_DATA_TINV             =>  C_PRH2_DATA_TINV,
      C_PRH2_RDY_TOUT              =>  C_PRH2_RDY_TOUT,
      C_PRH2_RDY_WIDTH             =>  C_PRH2_RDY_WIDTH,
            ----------------       -------------------------
      C_PRH3_FIFO_ACCESS           =>  C_PRH3_FIFO_ACCESS,
      C_PRH3_AWIDTH                =>  C_PRH3_AWIDTH,
      C_PRH3_DWIDTH                =>  C_PRH3_DWIDTH,
      C_PRH3_DWIDTH_MATCH          =>  C_PRH3_DWIDTH_MATCH,
      C_PRH3_SYNC                  =>  C_PRH3_SYNC,
      C_PRH3_BUS_MULTIPLEX         =>  C_PRH3_BUS_MULTIPLEX,
      C_PRH3_ADDR_TSU              =>  C_PRH3_ADDR_TSU,
      C_PRH3_ADDR_TH               =>  C_PRH3_ADDR_TH,
      C_PRH3_ADS_WIDTH             =>  C_PRH3_ADS_WIDTH,
      C_PRH3_CSN_TSU               =>  C_PRH3_CSN_TSU,
      C_PRH3_CSN_TH                =>  C_PRH3_CSN_TH,
      C_PRH3_WRN_WIDTH             =>  C_PRH3_WRN_WIDTH,
      C_PRH3_WR_CYCLE              =>  C_PRH3_WR_CYCLE,
      C_PRH3_DATA_TSU              =>  C_PRH3_DATA_TSU,
      C_PRH3_DATA_TH               =>  C_PRH3_DATA_TH,
      C_PRH3_RDN_WIDTH             =>  C_PRH3_RDN_WIDTH,
      C_PRH3_RD_CYCLE              =>  C_PRH3_RD_CYCLE,
      C_PRH3_DATA_TOUT             =>  C_PRH3_DATA_TOUT,
      C_PRH3_DATA_TINV             =>  C_PRH3_DATA_TINV,
      C_PRH3_RDY_TOUT              =>  C_PRH3_RDY_TOUT,
      C_PRH3_RDY_WIDTH             =>  C_PRH3_RDY_WIDTH,
            ----------------       -------------------------
      MAX_PERIPHERALS              =>  MAX_PERIPHERALS,
      PRH0_FIFO_ADDRESS            =>  PRH0_FIFO_ADDRESS,
      PRH1_FIFO_ADDRESS            =>  PRH1_FIFO_ADDRESS,
      PRH2_FIFO_ADDRESS            =>  PRH2_FIFO_ADDRESS,
      PRH3_FIFO_ADDRESS            =>  PRH3_FIFO_ADDRESS
            ----------------       -------------------------
  )

  port map (
      -- IP Interconnect (IPIC) port signals ----------
      Bus2IP_Clk                  => bus2ip_clk,
      Bus2IP_Rst                  => bus2ip_reset,
      Bus2IP_CS                   => dev_bus2ip_cs,
      Bus2IP_RdCE                 => dev_bus2ip_rdce,
      Bus2IP_WrCE                 => dev_bus2ip_wrce,
      Bus2IP_Addr                 => dev_bus2ip_addr,
      Bus2IP_RNW                  => bus2ip_rnw,
      Bus2IP_BE                   => bus2ip_be,
      Bus2IP_Data                 => bus2ip_data,
      -- ip2bus signals ---------------------------------------------------
      IP2Bus_Data                 => ip2bus_data,
      IP2Bus_WrAck                => ip2bus_wrack,
      IP2Bus_RdAck                => ip2bus_rdack,
      IP2Bus_Error                => ip2bus_error,
            ----------------       -------------------------
      Local_Clk                   => local_clk,
      Local_Rst                   => local_rst,
      PRH_CS_n                    => PRH_CS_n,
      PRH_Addr                    => PRH_Addr,
      PRH_ADS                     => PRH_ADS,
      PRH_BE                      => PRH_BE,
      PRH_RNW                     => PRH_RNW,
      PRH_Rd_n                    => PRH_Rd_n,
      PRH_Wr_n                    => PRH_Wr_n,
      PRH_Burst                   => PRH_Burst,
      PRH_Rdy                     => PRH_Rdy,
      PRH_Data_I                  => PRH_Data_I,
      PRH_Data_O                  => PRH_Data_O,
      PRH_Data_T                  => PRH_Data_T
);


dev_bus2ip_cs <= bus2ip_cs((NUM_ARD - C_NUM_PERIPHERALS) to (NUM_ARD -1));

-- Fix the number of CEs per device as one
dev_bus2ip_rdce <= bus2ip_rdce((NUM_CE - C_NUM_PERIPHERALS) to (NUM_CE -1));
dev_bus2ip_wrce <= bus2ip_wrce((NUM_CE - C_NUM_PERIPHERALS) to (NUM_CE -1));

dev_bus2ip_addr <= bus2ip_addr(C_SPLB_AWIDTH-C_PRH_MAX_AWIDTH to C_SPLB_AWIDTH-1);

-------------------------------------------------------------------------------
-- NAME: REMOVE_INTERRUPT
-------------------------------------------------------------------------------
-- Description: Assigning IP2INTC_Irpt signal to zero's when interrupt is not
--              present.
-------------------------------------------------------------------------------
REMOVE_INTERRUPT : if (C_INTERRUPT_PRESENT = 0) generate
  IP2INTC_Irpt <= '0';
end generate REMOVE_INTERRUPT;
-------------------------------------------------------------------------------
-- NAME: PASSTHROUGH_INTERRUPT
-------------------------------------------------------------------------------
-- Description: Simply passthrough peripheral interrupt to IP2INTC_Irpt signal
--              when interrupt is present.
-------------------------------------------------------------------------------
PASSTHROUGH_INTERRUPT : if (C_INTERRUPT_PRESENT = 1) generate
  IP2INTC_Irpt <= PRH_Int;
end generate PASSTHROUGH_INTERRUPT;
-------------------------------------------------------------------------------

end architecture imp;
--------------------------------end of file------------------------------------
