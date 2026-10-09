-- AES3 クロック生成モジュール
-- 48kHz/96kHz サンプリングレート検出

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity aes3_clock_gen is
  generic (
    CLOCK_FREQ : integer := 50_000_000  -- クロック周波数 (Hz)
  );
  port (
    clk       : in  std_logic;              -- メインクロック
    rst_n     : in  std_logic;              -- リセット (アクティブロー)
    bit_clk   : out std_logic;              -- ビットクロック
    frame_clk : out std_logic;              -- フレームクロック
    sample_rate : out std_logic_vector(1 downto 0)  -- 00=48kHz, 01=96kHz
  );
end entity aes3_clock_gen;

architecture rtl of aes3_clock_gen is
  
  -- 48kHz: bit_clk = 9.216 MHz (192 * 48kHz)
  -- 96kHz: bit_clk = 18.432 MHz (192 * 96kHz)
  
  constant DIV_48K : integer := CLOCK_FREQ / 9_216_000;  -- 約5 (50MHz/9.216MHz)
  constant DIV_96K : integer := CLOCK_FREQ / 18_432_000; -- 約2 (50MHz/18.432MHz)
  
  signal clk_div_cnt : std_logic_vector(3 downto 0);
  signal bit_clk_reg : std_logic;
  signal frame_cnt : std_logic_vector(7 downto 0);
  signal frame_clk_reg : std_logic;
  signal rate_sel : std_logic; -- 0=48kHz, 1=96kHz
  signal div_val : integer range 0 to 5;
  
begin
  
  -- サンプリングレート選択 (この実装では固定、実装時に適応化)
  rate_sel <= '0'; -- 48kHz (ハードコード)
  sample_rate <= "00" when rate_sel = '0' else "01";
  
  -- 除数値の選択
  div_val <= DIV_48K when rate_sel = '0' else DIV_96K;
  
  -- ビットクロック生成
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      clk_div_cnt <= (others => '0');
      bit_clk_reg <= '0';
    elsif rising_edge(clk) then
      if clk_div_cnt = div_val - 1 then
        clk_div_cnt <= (others => '0');
        bit_clk_reg <= not bit_clk_reg;
      else
        clk_div_cnt <= clk_div_cnt + 1;
      end if;
    end if;
  end process;
  
  bit_clk <= bit_clk_reg;
  
  -- フレームクロック生成 (ビットクロックの1/192)
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      frame_cnt <= (others => '0');
      frame_clk_reg <= '0';
    elsif rising_edge(clk) then
      if bit_clk_reg = '1' and clk_div_cnt = 0 then  -- ビットクロックの立ち上がり
        if frame_cnt = 191 then
          frame_cnt <= (others => '0');
          frame_clk_reg <= not frame_clk_reg;
        else
          frame_cnt <= frame_cnt + 1;
        end if;
      end if;
    end if;
  end process;
  
  frame_clk <= frame_clk_reg;

end architecture rtl;
