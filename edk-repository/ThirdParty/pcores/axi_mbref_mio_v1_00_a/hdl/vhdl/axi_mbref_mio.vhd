------------------------------------------------------------------------------
-- axi_mbref_mio.vhd - entity/architecture pair
------------------------------------------------------------------------------
-- IMPORTANT:
-- DO NOT MODIFY THIS FILE EXCEPT IN THE DESIGNATED SECTIONS.
--
-- SEARCH FOR --USER TO DETERMINE WHERE CHANGES ARE ALLOWED.
--
-- TYPICALLY, THE ONLY ACCEPTABLE CHANGES INVOLVE ADDING NEW
-- PORTS AND GENERICS THAT GET PASSED THROUGH TO THE INSTANTIATION
-- OF THE USER_LOGIC ENTITY.
------------------------------------------------------------------------------
--
-- ***************************************************************************
-- ** Copyright (c) 2012 Li-Pro.Net, Stephan Linz <linz@li-pro.net>         **
-- **                                                                       **
-- ** This program is free software; you can redistribute it and/or         **
-- ** modify it under the terms of the GNU General Public License as        **
-- ** published by the Free Software Foundation; either version 2 of        **
-- ** the License, or (at your option) any later version.                   **
-- **                                                                       **
-- ** This program is distributed in the hope that it will be useful,       **
-- ** but WITHOUT ANY WARRANTY; without even the implied warranty of        **
-- ** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the          **
-- ** GNU General Public License for more details.                          **
-- **                                                                       **
-- ** You should have received a copy of the GNU General Public License     **
-- ** along with this program; if not, write to the Free Software           **
-- ** Foundation, Inc., 59 Temple Place, Suite 330, Boston,                 **
-- ** MA 02111-1307 USA                                                     **
-- **                                                                       **
-- ***************************************************************************
--
-- ***************************************************************************
-- ** Copyright (c) 1995-2011 Xilinx, Inc.  All rights reserved.            **
-- **                                                                       **
-- ** Xilinx, Inc.                                                          **
-- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"         **
-- ** AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND       **
-- ** SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,        **
-- ** OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,        **
-- ** APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION           **
-- ** THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,     **
-- ** AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE      **
-- ** FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY              **
-- ** WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE               **
-- ** IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR        **
-- ** REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF       **
-- ** INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       **
-- ** FOR A PARTICULAR PURPOSE.                                             **
-- **                                                                       **
-- ***************************************************************************
--
------------------------------------------------------------------------------
-- Filename:          axi_mbref_mio.vhd
-- Version:           1.00.a
-- Description:       Top level design, instantiates library components and user logic.
-- Date:              Mon Feb 13 19:49:43 2012 (by Create and Import Peripheral Wizard)
-- VHDL Standard:     VHDL'93
------------------------------------------------------------------------------
-- Naming Conventions:
--   active low signals:                    "*_n"
--   clock signals:                         "clk", "clk_div#", "clk_#x"
--   reset signals:                         "rst", "rst_n"
--   generics:                              "C_*"
--   user defined types:                    "*_TYPE"
--   state machine next state:              "*_ns"
--   state machine current state:           "*_cs"
--   combinatorial signals:                 "*_com"
--   pipelined or register delay signals:   "*_d#"
--   counter signals:                       "*cnt*"
--   clock enable signals:                  "*_ce"
--   internal version of output port:       "*_i"
--   device pins:                           "*_pin"
--   ports:                                 "- Names begin with Uppercase"
--   processes:                             "*_PROCESS"
--   component instantiations:              "<ENTITY_>I_<#|FUNC>"
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.ipif_pkg.all;

library axi_slave_burst_v1_00_a;
use axi_slave_burst_v1_00_a.axi_slave_burst;

library axi_mbref_mio_v1_00_a;
use axi_mbref_mio_v1_00_a.user_logic;

------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------
-- Definition of Generics:
--   C_S_AXI_DATA_WIDTH           -- 
--   C_S_AXI_ADDR_WIDTH           -- 
--   C_S_AXI_ID_WIDTH             -- 
--   C_RDATA_FIFO_DEPTH           -- 
--   C_INCLUDE_TIMEOUT_CNT        -- 
--   C_TIMEOUT_CNTR_VAL           -- 
--   C_ALIGN_BE_RDADDR            -- 
--   C_S_AXI_SUPPORTS_WRITE       -- 
--   C_S_AXI_SUPPORTS_READ        -- 
--   C_FAMILY                     -- 
--   C_S_AXI_MEM0_BASEADDR        -- User memory space 0 base address
--   C_S_AXI_MEM0_HIGHADDR        -- User memory space 0 high address
--   C_S_AXI_MEM1_BASEADDR        -- User memory space 1 base address
--   C_S_AXI_MEM1_HIGHADDR        -- User memory space 1 high address
--   C_S_AXI_MEM2_BASEADDR        -- User memory space 2 base address
--   C_S_AXI_MEM2_HIGHADDR        -- User memory space 2 high address
--   C_S_AXI_MEM3_BASEADDR        -- User memory space 3 base address
--   C_S_AXI_MEM3_HIGHADDR        -- User memory space 3 high address
--
-- Definition of Ports:
--   S_AXI_ACLK                   -- 
--   S_AXI_ARESETN                -- 
--   S_AXI_AWADDR                 -- 
--   S_AXI_AWVALID                -- 
--   S_AXI_WDATA                  -- 
--   S_AXI_WSTRB                  -- 
--   S_AXI_WVALID                 -- 
--   S_AXI_BREADY                 -- 
--   S_AXI_ARADDR                 -- 
--   S_AXI_ARVALID                -- 
--   S_AXI_RREADY                 -- 
--   S_AXI_ARREADY                -- 
--   S_AXI_RDATA                  -- 
--   S_AXI_RRESP                  -- 
--   S_AXI_RVALID                 -- 
--   S_AXI_WREADY                 -- 
--   S_AXI_BRESP                  -- 
--   S_AXI_BVALID                 -- 
--   S_AXI_AWREADY                -- 
--   S_AXI_AWID                   -- 
--   S_AXI_AWLEN                  -- 
--   S_AXI_AWSIZE                 -- 
--   S_AXI_AWBURST                -- 
--   S_AXI_AWLOCK                 -- 
--   S_AXI_AWCACHE                -- 
--   S_AXI_AWPROT                 -- 
--   S_AXI_WLAST                  -- 
--   S_AXI_BID                    -- 
--   S_AXI_ARID                   -- 
--   S_AXI_ARLEN                  -- 
--   S_AXI_ARSIZE                 -- 
--   S_AXI_ARBURST                -- 
--   S_AXI_ARLOCK                 -- 
--   S_AXI_ARCACHE                -- 
--   S_AXI_ARPROT                 -- 
--   S_AXI_RID                    -- 
--   S_AXI_RLAST                  -- 
------------------------------------------------------------------------------

entity axi_mbref_mio is
  generic
  (
    -- ADD USER GENERICS BELOW THIS LINE ---------------
    --USER generics added here
    -- ADD USER GENERICS ABOVE THIS LINE ---------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol parameters, do not add to or delete
    C_S_AXI_DATA_WIDTH             : integer              := 32;
    C_S_AXI_ADDR_WIDTH             : integer              := 32;
    C_S_AXI_ID_WIDTH               : integer              := 4;
    C_RDATA_FIFO_DEPTH             : integer              := 0;
    C_INCLUDE_TIMEOUT_CNT          : integer              := 1;
    C_TIMEOUT_CNTR_VAL             : integer              := 8;
    C_ALIGN_BE_RDADDR              : integer              := 0;
    C_S_AXI_SUPPORTS_WRITE         : integer              := 1;
    C_S_AXI_SUPPORTS_READ          : integer              := 1;
    C_FAMILY                       : string               := "virtex6";
    C_S_AXI_MEM0_BASEADDR          : std_logic_vector     := X"FFFFFFFF";
    C_S_AXI_MEM0_HIGHADDR          : std_logic_vector     := X"00000000";
    C_S_AXI_MEM1_BASEADDR          : std_logic_vector     := X"FFFFFFFF";
    C_S_AXI_MEM1_HIGHADDR          : std_logic_vector     := X"00000000";
    C_S_AXI_MEM2_BASEADDR          : std_logic_vector     := X"FFFFFFFF";
    C_S_AXI_MEM2_HIGHADDR          : std_logic_vector     := X"00000000";
    C_S_AXI_MEM3_BASEADDR          : std_logic_vector     := X"FFFFFFFF";
    C_S_AXI_MEM3_HIGHADDR          : std_logic_vector     := X"00000000"
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );
  port
  (
    -- ADD USER PORTS BELOW THIS LINE ------------------
    --USER ports added here
    -- ADD USER PORTS ABOVE THIS LINE ------------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete
    S_AXI_ACLK                     : in  std_logic;
    S_AXI_ARESETN                  : in  std_logic;
    S_AXI_AWADDR                   : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_AWVALID                  : in  std_logic;
    S_AXI_WDATA                    : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_WSTRB                    : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    S_AXI_WVALID                   : in  std_logic;
    S_AXI_BREADY                   : in  std_logic;
    S_AXI_ARADDR                   : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ARVALID                  : in  std_logic;
    S_AXI_RREADY                   : in  std_logic;
    S_AXI_ARREADY                  : out std_logic;
    S_AXI_RDATA                    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP                    : out std_logic_vector(1 downto 0);
    S_AXI_RVALID                   : out std_logic;
    S_AXI_WREADY                   : out std_logic;
    S_AXI_BRESP                    : out std_logic_vector(1 downto 0);
    S_AXI_BVALID                   : out std_logic;
    S_AXI_AWREADY                  : out std_logic;
    S_AXI_AWID                     : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_AWLEN                    : in  std_logic_vector(7 downto 0);
    S_AXI_AWSIZE                   : in  std_logic_vector(2 downto 0);
    S_AXI_AWBURST                  : in  std_logic_vector(1 downto 0);
    S_AXI_AWLOCK                   : in  std_logic;
    S_AXI_AWCACHE                  : in  std_logic_vector(3 downto 0);
    S_AXI_AWPROT                   : in  std_logic_vector(2 downto 0);
    S_AXI_WLAST                    : in  std_logic;
    S_AXI_BID                      : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_ARID                     : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_ARLEN                    : in  std_logic_vector(7 downto 0);
    S_AXI_ARSIZE                   : in  std_logic_vector(2 downto 0);
    S_AXI_ARBURST                  : in  std_logic_vector(1 downto 0);
    S_AXI_ARLOCK                   : in  std_logic;
    S_AXI_ARCACHE                  : in  std_logic_vector(3 downto 0);
    S_AXI_ARPROT                   : in  std_logic_vector(2 downto 0);
    S_AXI_RID                      : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_RLAST                    : out std_logic
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );

  attribute MAX_FANOUT : string;
  attribute SIGIS : string;
  attribute MAX_FANOUT of S_AXI_ACLK       : signal is "10000";
  attribute MAX_FANOUT of S_AXI_ARESETN       : signal is "10000";
  attribute SIGIS of S_AXI_ACLK       : signal is "Clk";
  attribute SIGIS of S_AXI_ARESETN       : signal is "Rst";
end entity axi_mbref_mio;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of axi_mbref_mio is

  constant USER_SLV_DWIDTH                : integer              := C_S_AXI_DATA_WIDTH;

  constant IPIF_SLV_DWIDTH                : integer              := C_S_AXI_DATA_WIDTH;

  constant ZERO_ADDR_PAD                  : std_logic_vector(0 to 31) := (others => '0');

  constant IPIF_ARD_ADDR_RANGE_ARRAY      : SLV64_ARRAY_TYPE     := 
    (
      ZERO_ADDR_PAD & C_S_AXI_MEM0_BASEADDR,-- user logic memory space 0 base address
      ZERO_ADDR_PAD & C_S_AXI_MEM0_HIGHADDR,-- user logic memory space 0 high address
      ZERO_ADDR_PAD & C_S_AXI_MEM1_BASEADDR,-- user logic memory space 1 base address
      ZERO_ADDR_PAD & C_S_AXI_MEM1_HIGHADDR,-- user logic memory space 1 high address
      ZERO_ADDR_PAD & C_S_AXI_MEM2_BASEADDR,-- user logic memory space 2 base address
      ZERO_ADDR_PAD & C_S_AXI_MEM2_HIGHADDR,-- user logic memory space 2 high address
      ZERO_ADDR_PAD & C_S_AXI_MEM3_BASEADDR,-- user logic memory space 3 base address
      ZERO_ADDR_PAD & C_S_AXI_MEM3_HIGHADDR -- user logic memory space 3 high address
    );

  constant USER_NUM_MEM                   : integer              := 4;

  constant IPIF_ARD_NUM_CE_ARRAY          : INTEGER_ARRAY_TYPE   := 
    (
      0  => 1,                            -- number of ce for user logic memory space 0 (always 1 chip enable)
      1  => 1,                            -- number of ce for user logic memory space 1 (always 1 chip enable)
      2  => 1,                            -- number of ce for user logic memory space 2 (always 1 chip enable)
      3  => 1                             -- number of ce for user logic memory space 3 (always 1 chip enable)
    );

  ------------------------------------------
  -- Width of the slave address bus (32 only)
  ------------------------------------------
  constant USER_SLV_AWIDTH                : integer              := C_S_AXI_ADDR_WIDTH;

  ------------------------------------------
  -- Index for CS/CE
  ------------------------------------------
  constant USER_MEM0_CS_INDEX             : integer              := 0;

  constant USER_CS_INDEX                  : integer              := USER_MEM0_CS_INDEX;

  ------------------------------------------
  -- IP Interconnect (IPIC) signal declarations
  ------------------------------------------
  signal ipif_Bus2IP_Clk                : std_logic;
  signal ipif_Bus2IP_Resetn             : std_logic;
  signal ipif_Bus2IP_Addr               : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal ipif_Bus2IP_RNW                : std_logic;
  signal ipif_Bus2IP_BE                 : std_logic_vector(IPIF_SLV_DWIDTH/8-1 downto 0);
  signal ipif_Bus2IP_CS                 : std_logic_vector((IPIF_ARD_ADDR_RANGE_ARRAY'LENGTH)/2-1 downto 0);
  signal ipif_Bus2IP_RdCE               : std_logic_vector(calc_num_ce(IPIF_ARD_NUM_CE_ARRAY)-1 downto 0);
  signal ipif_Bus2IP_WrCE               : std_logic_vector(calc_num_ce(IPIF_ARD_NUM_CE_ARRAY)-1 downto 0);
  signal ipif_Bus2IP_Data               : std_logic_vector(IPIF_SLV_DWIDTH-1 downto 0);
  signal ipif_Bus2IP_Burst              : std_logic;
  signal ipif_Bus2IP_BurstLength        : std_logic_vector(7 downto 0);
  signal ipif_Bus2IP_WrReq              : std_logic;
  signal ipif_Bus2IP_RdReq              : std_logic;
  signal ipif_IP2Bus_AddrAck            : std_logic;
  signal ipif_IP2Bus_RdAck              : std_logic;
  signal ipif_IP2Bus_WrAck              : std_logic;
  signal ipif_IP2Bus_Error              : std_logic;
  signal ipif_IP2Bus_Data               : std_logic_vector(IPIF_SLV_DWIDTH-1 downto 0);
  signal ipif_Type_of_xfer              : std_logic;
  signal user_Bus2IP_BurstLength        : std_logic_vector(7 downto 0)   := (others => '0');
  signal user_IP2Bus_AddrAck            : std_logic;
  signal user_IP2Bus_Data               : std_logic_vector(USER_SLV_DWIDTH-1 downto 0);
  signal user_IP2Bus_RdAck              : std_logic;
  signal user_IP2Bus_WrAck              : std_logic;
  signal user_IP2Bus_Error              : std_logic;
  signal user_Type_of_xfer              : std_logic;

begin

  ------------------------------------------
  -- instantiate axi_slave_burst
  ------------------------------------------
  AXI_SLAVE_BURST_I : entity axi_slave_burst_v1_00_a.axi_slave_burst
    generic map
    (
      C_S_AXI_DATA_WIDTH             => IPIF_SLV_DWIDTH,
      C_S_AXI_ADDR_WIDTH             => C_S_AXI_ADDR_WIDTH,
      C_S_AXI_ID_WIDTH               => C_S_AXI_ID_WIDTH,
      C_RDATA_FIFO_DEPTH             => C_RDATA_FIFO_DEPTH,
      C_INCLUDE_TIMEOUT_CNT          => C_INCLUDE_TIMEOUT_CNT,
      C_TIMEOUT_CNTR_VAL             => C_TIMEOUT_CNTR_VAL,
      C_ALIGN_BE_RDADDR              => C_ALIGN_BE_RDADDR,
      C_S_AXI_SUPPORTS_WRITE         => C_S_AXI_SUPPORTS_WRITE,
      C_S_AXI_SUPPORTS_READ          => C_S_AXI_SUPPORTS_READ,
      C_ARD_ADDR_RANGE_ARRAY         => IPIF_ARD_ADDR_RANGE_ARRAY,
      C_ARD_NUM_CE_ARRAY             => IPIF_ARD_NUM_CE_ARRAY,
      C_FAMILY                       => C_FAMILY
    )
    port map
    (
      S_AXI_ACLK                     => S_AXI_ACLK,
      S_AXI_ARESETN                  => S_AXI_ARESETN,
      S_AXI_AWADDR                   => S_AXI_AWADDR,
      S_AXI_AWVALID                  => S_AXI_AWVALID,
      S_AXI_WDATA                    => S_AXI_WDATA,
      S_AXI_WSTRB                    => S_AXI_WSTRB,
      S_AXI_WVALID                   => S_AXI_WVALID,
      S_AXI_BREADY                   => S_AXI_BREADY,
      S_AXI_ARADDR                   => S_AXI_ARADDR,
      S_AXI_ARVALID                  => S_AXI_ARVALID,
      S_AXI_RREADY                   => S_AXI_RREADY,
      S_AXI_ARREADY                  => S_AXI_ARREADY,
      S_AXI_RDATA                    => S_AXI_RDATA,
      S_AXI_RRESP                    => S_AXI_RRESP,
      S_AXI_RVALID                   => S_AXI_RVALID,
      S_AXI_WREADY                   => S_AXI_WREADY,
      S_AXI_BRESP                    => S_AXI_BRESP,
      S_AXI_BVALID                   => S_AXI_BVALID,
      S_AXI_AWREADY                  => S_AXI_AWREADY,
      S_AXI_AWID                     => S_AXI_AWID,
      S_AXI_AWLEN                    => S_AXI_AWLEN,
      S_AXI_AWSIZE                   => S_AXI_AWSIZE,
      S_AXI_AWBURST                  => S_AXI_AWBURST,
      S_AXI_AWLOCK                   => S_AXI_AWLOCK,
      S_AXI_AWCACHE                  => S_AXI_AWCACHE,
      S_AXI_AWPROT                   => S_AXI_AWPROT,
      S_AXI_WLAST                    => S_AXI_WLAST,
      S_AXI_BID                      => S_AXI_BID,
      S_AXI_ARID                     => S_AXI_ARID,
      S_AXI_ARLEN                    => S_AXI_ARLEN,
      S_AXI_ARSIZE                   => S_AXI_ARSIZE,
      S_AXI_ARBURST                  => S_AXI_ARBURST,
      S_AXI_ARLOCK                   => S_AXI_ARLOCK,
      S_AXI_ARCACHE                  => S_AXI_ARCACHE,
      S_AXI_ARPROT                   => S_AXI_ARPROT,
      S_AXI_RID                      => S_AXI_RID,
      S_AXI_RLAST                    => S_AXI_RLAST,
      Bus2IP_Clk                     => ipif_Bus2IP_Clk,
      Bus2IP_Resetn                  => ipif_Bus2IP_Resetn,
      Bus2IP_Addr                    => ipif_Bus2IP_Addr,
      Bus2IP_RNW                     => ipif_Bus2IP_RNW,
      Bus2IP_BE                      => ipif_Bus2IP_BE,
      Bus2IP_CS                      => ipif_Bus2IP_CS,
      Bus2IP_RdCE                    => ipif_Bus2IP_RdCE,
      Bus2IP_WrCE                    => ipif_Bus2IP_WrCE,
      Bus2IP_Data                    => ipif_Bus2IP_Data,
      Bus2IP_Burst                   => ipif_Bus2IP_Burst,
      Bus2IP_BurstLength             => ipif_Bus2IP_BurstLength,
      Bus2IP_WrReq                   => ipif_Bus2IP_WrReq,
      Bus2IP_RdReq                   => ipif_Bus2IP_RdReq,
      IP2Bus_AddrAck                 => ipif_IP2Bus_AddrAck,
      IP2Bus_RdAck                   => ipif_IP2Bus_RdAck,
      IP2Bus_WrAck                   => ipif_IP2Bus_WrAck,
      IP2Bus_Error                   => ipif_IP2Bus_Error,
      IP2Bus_Data                    => ipif_IP2Bus_Data,
      Type_of_xfer                   => ipif_Type_of_xfer
    );

  ------------------------------------------
  -- instantiate User Logic
  ------------------------------------------
  USER_LOGIC_I : entity axi_mbref_mio_v1_00_a.user_logic
    generic map
    (
      -- MAP USER GENERICS BELOW THIS LINE ---------------
      --USER generics mapped here
      -- MAP USER GENERICS ABOVE THIS LINE ---------------

      C_SLV_AWIDTH                   => USER_SLV_AWIDTH,
      C_SLV_DWIDTH                   => USER_SLV_DWIDTH,
      C_NUM_MEM                      => USER_NUM_MEM
    )
    port map
    (
      -- MAP USER PORTS BELOW THIS LINE ------------------
      --USER ports mapped here
      -- MAP USER PORTS ABOVE THIS LINE ------------------

      Bus2IP_Clk                     => ipif_Bus2IP_Clk,
      Bus2IP_Resetn                  => ipif_Bus2IP_Resetn,
      Bus2IP_Addr                    => ipif_Bus2IP_Addr,
      Bus2IP_CS                      => ipif_Bus2IP_CS(USER_NUM_MEM-1 downto 0),
      Bus2IP_RNW                     => ipif_Bus2IP_RNW,
      Bus2IP_Data                    => ipif_Bus2IP_Data,
      Bus2IP_BE                      => ipif_Bus2IP_BE,
      Bus2IP_RdCE                    => ipif_Bus2IP_RdCE,
      Bus2IP_WrCE                    => ipif_Bus2IP_WrCE,
      Bus2IP_Burst                   => ipif_Bus2IP_Burst,
      Bus2IP_BurstLength             => user_Bus2IP_BurstLength,
      Bus2IP_RdReq                   => ipif_Bus2IP_RdReq,
      Bus2IP_WrReq                   => ipif_Bus2IP_WrReq,
      IP2Bus_AddrAck                 => user_IP2Bus_AddrAck,
      IP2Bus_Data                    => user_IP2Bus_Data,
      IP2Bus_RdAck                   => user_IP2Bus_RdAck,
      IP2Bus_WrAck                   => user_IP2Bus_WrAck,
      IP2Bus_Error                   => user_IP2Bus_Error,
      Type_of_xfer                   => user_Type_of_xfer
    );

  ------------------------------------------
  -- connect internal signals
  ------------------------------------------
  IP2BUS_DATA_MUX_PROC : process( ipif_Bus2IP_CS, user_IP2Bus_Data ) is
  begin

    case ipif_Bus2IP_CS is
      when "1000" => ipif_IP2Bus_Data <= user_IP2Bus_Data;
      when "0100" => ipif_IP2Bus_Data <= user_IP2Bus_Data;
      when "0010" => ipif_IP2Bus_Data <= user_IP2Bus_Data;
      when "0001" => ipif_IP2Bus_Data <= user_IP2Bus_Data;
      when others => ipif_IP2Bus_Data <= (others => '0');
    end case;

  end process IP2BUS_DATA_MUX_PROC;

  ipif_IP2Bus_AddrAck <= user_IP2Bus_AddrAck;
  ipif_IP2Bus_WrAck <= user_IP2Bus_WrAck;
  ipif_IP2Bus_RdAck <= user_IP2Bus_RdAck;
  ipif_IP2Bus_Error <= user_IP2Bus_Error;

  user_Bus2IP_BurstLength(7 downto 0)<= ipif_Bus2IP_BurstLength(7 downto 0);

end IMP;
