-- ************************************************************************** --
-- *  GigE Vision Reference Design                                          * --
-- *------------------------------------------------------------------------* --
-- *  Module :  VIDEO-SYN                                                   * --
-- *    File :  video.vhd                                                   * --
-- *    Date :  2009-07-13                                                  * --
-- *     Rev :  0.4                                                         * --
-- *  Author :  JP                                                          * --
-- *------------------------------------------------------------------------* --
-- *  Test pattern generator                                                * --
-- *------------------------------------------------------------------------* --
-- *  0.1  |  2008-02-27  |  JP  |  Initial release                         * --
-- *  0.2  |  2008-04-24  |  JP  |  Added fb_clk signal to framebuffer i/f  * --
-- *  0.3  |  2009-01-09  |  JP  |  Removed video input part, extended      * --
-- *       |              |      |  features of the test pattern generator  * --
-- *  0.4  |  2009-07-13  |  JP  |  Modified video output enable            * --
-- ************************************************************************** --

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library unisim;
use     unisim.vcomponents.all;


--------------------------------------------------------------------------------
--  VIDEO-SYN entity
--------------------------------------------------------------------------------

entity video is
    port (-- Global ports
          sys_clk       : in    std_logic;                      -- System clock
          sys_rst       : in    std_logic;                      -- System reset
          -- CPU interface
          epc_addr      : in    std_logic_vector(15 downto 0);  -- Register address
          epc_odata     : in    std_logic_vector(31 downto 0);  -- Data from CPU
          epc_cs_n      : in    std_logic;                      -- Chip select
          epc_rnw       : in    std_logic;                      -- Read/write
          epc_idata     : out   std_logic_vector(31 downto 0);  -- Data for CPU
          epc_rdy       : out   std_logic;                      -- Data ready
          -- Framebuffer interface
          fb_clk        : in    std_logic;                      -- Interface clock
          fb_frame      : out   std_logic;                      -- Frame valid
          fb_dv         : out   std_logic;                      -- Data valid
          fb_data       : out   std_logic_vector(15 downto 0);  -- Pixel data
          fb_ptype      : out   std_logic_vector(31 downto 0);  -- Pixel type
          fb_size_x     : out   std_logic_vector(31 downto 0);  -- Frame width
          fb_size_y     : out   std_logic_vector(31 downto 0);  -- Frame height
          fb_offs_x     : out   std_logic_vector(31 downto 0);  -- ROI horizontal offset
          fb_offs_y     : out   std_logic_vector(31 downto 0);  -- ROI vertical offset
          fb_pad_x      : out   std_logic_vector(15 downto 0);  -- Line padding in bytes
          fb_pad_y      : out   std_logic_vector(15 downto 0)); -- Frame padding in bytes
end video;


--------------------------------------------------------------------------------
--  VIDEO-SYN architecture
--------------------------------------------------------------------------------

architecture syn of video is

    -- Constants ---------------------------------------------------------------

    -- Global control constants
    constant AWIDTH         : natural                               := 4;   -- Valid width of a register address

    -- Addresses of control/status registers
    constant ADDR_GCSR      : std_logic_vector(AWIDTH-1 downto 0)   := "0000";
    constant ADDR_WIDTH     : std_logic_vector(AWIDTH-1 downto 0)   := "0001";
    constant ADDR_HEIGHT    : std_logic_vector(AWIDTH-1 downto 0)   := "0010";
    constant ADDR_OFFS_X    : std_logic_vector(AWIDTH-1 downto 0)   := "0011";
    constant ADDR_OFFS_Y    : std_logic_vector(AWIDTH-1 downto 0)   := "0100";
    constant ADDR_PADDING   : std_logic_vector(AWIDTH-1 downto 0)   := "0101";
    constant ADDR_PIXFMT    : std_logic_vector(AWIDTH-1 downto 0)   := "0110";
    constant ADDR_GAP_X     : std_logic_vector(AWIDTH-1 downto 0)   := "0111";
    constant ADDR_GAP_Y     : std_logic_vector(AWIDTH-1 downto 0)   := "1000";


    -- Signals -----------------------------------------------------------------

    -- CPU interface
    signal wr_rdy       : std_logic;                                    -- Write ready
    signal wr_blk       : std_logic;                                    -- Write access finished
    signal rd_rdy       : std_logic;                                    -- Read ready
    signal rd_blk       : std_logic;                                    -- Read access finished

    -- Control and status registers
    signal reg_grab_en  : std_logic                     := '0';         -- Image acquisition enable
    signal reg_width    : std_logic_vector(31 downto 0) := x"000002F0"; -- Image width
    signal reg_height   : std_logic_vector(31 downto 0) := x"000001E0"; -- Image height
    signal reg_offs_x   : std_logic_vector(31 downto 0) := x"00000000"; -- AOI horizontal offset
    signal reg_offs_y   : std_logic_vector(31 downto 0) := x"00000000"; -- AOI vertical offset
    signal reg_pad_x    : std_logic_vector(15 downto 0) := x"0000";     -- Line padding
    signal reg_pad_y    : std_logic_vector(15 downto 0) := x"0000";     -- Frame padding
    signal reg_pixfmt   : std_logic_vector(31 downto 0) := x"01080001"; -- Pixel format
    signal reg_gap_x    : std_logic_vector(31 downto 0) := x"000004DF"; -- Additional gap between lines
    signal reg_gap_y    : std_logic_vector(31 downto 0) := x"00000090"; -- Additional gap between frames

    -- Test pattern generator
    signal tst_data     : std_logic_vector(15 downto 0);                -- Pixel data
    signal tst_frame    : std_logic;                                    -- Frame valid
    signal tst_line     : std_logic;                                    -- Line valid
    signal tst_hcnt     : unsigned        (15 downto 0);                -- Column counter
    signal tst_vcnt     : unsigned        (15 downto 0);                -- Line counter
    signal tst_shift    : unsigned        ( 7 downto 0);                -- Pixel value offset
    signal tst_hstart   : unsigned        (15 downto 0);                -- First clock cycle of a line
    signal tst_hend     : unsigned        (15 downto 0);                -- Last clock cycle of a line
    signal tst_hmax     : unsigned        (15 downto 0);                -- Number of clocks per line - 1
    signal tst_vstart   : unsigned        (15 downto 0);                -- First line of a frame
    signal tst_vend     : unsigned        (15 downto 0);                -- Last line of a frame
    signal tst_vmax     : unsigned        (15 downto 0);                -- Number of lines per frame - 1

    -- Data output control registers
    signal fb_grab_en_r : std_logic;                                    -- Acquisition enable in fb_clk domain
    signal fb_grab_en_rr: std_logic;                                    -- Second register stage
    signal fb_rst       : std_logic;                                    -- Reset in fb_clk domain
    signal fb_out_en    : std_logic;                                    -- Acquisition enable

begin

    -- CPU interface -----------------------------------------------------------

    -- Ready
    epc_rdy <= wr_rdy or rd_rdy;

    -- Write access
    CPU_WRITE_PROC: process (sys_clk)
    begin
        if rising_edge(sys_clk) then
            if (sys_rst = '1') then
                reg_grab_en  <= '0';
                reg_width    <= x"000002F0";
                reg_height   <= x"000001E0";
                reg_offs_x   <= x"00000000";
                reg_offs_y   <= x"00000000";
                reg_pad_x    <= x"0000";
                reg_pad_y    <= x"0000";
                reg_pixfmt   <= x"01080001";
                reg_gap_x    <= x"000004DF";
                reg_gap_y    <= x"00000090";
                wr_rdy       <= '0';
                wr_blk       <= '0';
            else
                if (epc_cs_n = '0' and epc_rnw = '0' and wr_blk = '0') then
                    case epc_addr(AWIDTH+1 downto 2) is
                        when ADDR_GCSR      =>  reg_grab_en <= epc_odata(0);
                        when ADDR_WIDTH     =>  reg_width   <= epc_odata;
                        when ADDR_HEIGHT    =>  reg_height  <= epc_odata;
                        when ADDR_OFFS_X    =>  reg_offs_x  <= epc_odata;
                        when ADDR_OFFS_Y    =>  reg_offs_y  <= epc_odata;
                        when ADDR_PADDING   =>  reg_pad_x   <= epc_odata(31 downto 16);
                                                reg_pad_y   <= epc_odata(15 downto  0);
                        when ADDR_PIXFMT    =>  reg_pixfmt  <= epc_odata;
                        when ADDR_GAP_X     =>  reg_gap_x   <= epc_odata;
                        when ADDR_GAP_Y     =>  reg_gap_y   <= epc_odata;
                        when others         =>  null;
                    end case;
                    wr_rdy <= '1';
                    wr_blk <= '1';
                else
                    wr_rdy <= '0';
                    if (epc_cs_n = '1') then
                        wr_blk <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process CPU_WRITE_PROC;

    -- Read access
    CPU_READ_PROC: process (sys_clk)
    begin
        if rising_edge(sys_clk) then
            if (sys_rst = '1') then
                rd_rdy    <= '0';
                rd_blk    <= '0';
                epc_idata <= (others => '0');
            else
                if (epc_cs_n = '0' and epc_rnw = '1' and rd_blk = '0') then
                    case epc_addr(AWIDTH+1 downto 2) is
                        when ADDR_GCSR      =>  epc_idata <= x"0000000" & "000" & reg_grab_en;
                        when ADDR_WIDTH     =>  epc_idata <= reg_width;
                        when ADDR_HEIGHT    =>  epc_idata <= reg_height;
                        when ADDR_OFFS_X    =>  epc_idata <= reg_offs_x;
                        when ADDR_OFFS_Y    =>  epc_idata <= reg_offs_y;
                        when ADDR_PADDING   =>  epc_idata <= reg_pad_x & reg_pad_y;
                        when ADDR_PIXFMT    =>  epc_idata <= reg_pixfmt;
                        when ADDR_GAP_X     =>  epc_idata <= reg_gap_x;
                        when ADDR_GAP_Y     =>  epc_idata <= reg_gap_y;
                        when others         =>  epc_idata <= (others => '0');
                    end case;
                    rd_rdy <= '1';
                    rd_blk <= '1';
                else
                    rd_rdy <= '0';
                    if (epc_cs_n = '1') then
                        rd_blk <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process CPU_READ_PROC;


    -- Test pattern generator --------------------------------------------------

    -- Synchronous reset in fb_clk domain
    RESET_SYNC_PROC: process (fb_clk)
    begin
        if rising_edge(fb_clk) then
            fb_rst <= sys_rst;
        end if;
    end process RESET_SYNC_PROC;

    -- Generator
    TEST_GEN_PROC: process (fb_clk)
    begin
        if rising_edge(fb_clk) then
            if (fb_rst = '1') then
                tst_data  <= (others => '0');
                tst_frame <= '0';
                tst_line  <= '0';
                tst_hcnt  <= (others => '0');
                tst_vcnt  <= (others => '0');
                tst_shift <= (others => '0');
                tst_vmax  <= (others => '0');
                tst_hmax  <= (others => '0');
                tst_hend  <= (others => '0');
            else
                -- Horizontal parameters
                tst_hstart <= unsigned(reg_offs_x(15 downto 0));
                tst_hend   <= unsigned(reg_width (16 downto 1)) + tst_hstart;
                tst_hmax   <= unsigned(reg_gap_x (15 downto 0)) + tst_hend;
                -- Vertical parameters
                tst_vstart <= unsigned(reg_offs_y(15 downto 0));
                tst_vend   <= unsigned(reg_height(15 downto 0)) + tst_vstart;
                tst_vmax   <= unsigned(reg_gap_y (15 downto 0)) + tst_vend;

                -- Column and row counters
                if (tst_hcnt /= tst_hmax) then
                    tst_hcnt <= tst_hcnt + 1;
                else
                    tst_hcnt <= (others => '0');
                    if (tst_vcnt /= tst_vmax) then
                        tst_vcnt <= tst_vcnt + 1;
                    else
                        tst_vcnt  <= (others => '0');
                        tst_shift <= tst_shift + 1;
                    end if;
                end if;

                -- Line enable
                if (tst_hcnt = tst_hstart) then     tst_line <= '1';    end if;
                if (tst_hcnt = tst_hend)   then     tst_line <= '0';    end if;

                -- Frame enable
                if (tst_vcnt = tst_vstart) then     tst_frame <= '1';   end if;
                if (tst_vcnt = tst_vend)   then     tst_frame <= '0';   end if;

                -- Pixel data
                tst_data <= std_logic_vector((tst_hcnt(6 downto 0) & "0") + tst_shift) &
                            std_logic_vector((tst_hcnt(6 downto 0) & "1") + tst_shift);
            end if;
        end if;
    end process TEST_GEN_PROC;


    -- Image data output -------------------------------------------------------

    -- Image parameters
    fb_size_x <= reg_width;
    fb_size_y <= reg_height;
    fb_offs_x <= reg_offs_x;
    fb_offs_y <= reg_offs_y;
    fb_pad_x  <= reg_pad_x;
    fb_pad_y  <= reg_pad_y;
    fb_ptype  <= reg_pixfmt;

    -- Synchronization to video clock
    REG_SYNC_PROC: process (fb_clk)
    begin
        if rising_edge(fb_clk) then
            fb_grab_en_r  <= reg_grab_en;
            fb_grab_en_rr <= fb_grab_en_r;
        end if;
    end process REG_SYNC_PROC;

    -- Test pattern data
    DATA_OUT_PROC: process (fb_clk)
    begin
        if rising_edge(fb_clk) then
            if (fb_rst = '1') then
                fb_out_en <= '0';
                fb_data   <= (others => '0');
                fb_frame  <= '0';
                fb_dv     <= '0';
            else
                -- Output enable
                if (tst_frame = '0') then
                    fb_out_en <= fb_grab_en_rr;
                end if;

                -- Video data output
                if (fb_out_en = '1') then
                    fb_data  <= tst_data;
                    fb_frame <= tst_frame;
                    fb_dv    <= tst_line;
                else
                    fb_data  <= (others => '0');
                    fb_frame <= '0';
                    fb_dv    <= '0';
                end if;
            end if;
        end if;
    end process DATA_OUT_PROC;

end syn;
