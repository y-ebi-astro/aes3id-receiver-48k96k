-- AES3 デコーダ
-- 192ビットフレームから24ビットオーディオとAUXデータを抽出

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity aes3_decoder is
  port (
    clk           : in  std_logic;                     -- メインクロック
    rst_n         : in  std_logic;                     -- リセット
    frame_complete : in  std_logic;                     -- フレーム完成
    shift_reg     : in  std_logic_vector(191 downto 0); -- シフトレジスタ
    ch_a_data     : out std_logic_vector(23 downto 0); -- チャネルA オーディオデータ
    ch_b_data     : out std_logic_vector(23 downto 0); -- チャネルB オーディオデータ
    ch_a_aux      : out std_logic_vector(3 downto 0);  -- チャネルA AUX
    ch_b_aux      : out std_logic_vector(3 downto 0);  -- チャネルB AUX
    ch_a_valid    : out std_logic;                     -- チャネルA 有効
    ch_b_valid    : out std_logic                      -- チャネルB 有効
  );
end entity aes3_decoder;

architecture rtl of aes3_decoder is
  
  -- フレーム構造 (192ビット)
  -- チャネルA (96ビット) | チャネルB (96ビット)
  -- 各チャネル: 24bit Audio + 4bit AUX + V + U + C + P
  
  signal ch_a_data_reg : std_logic_vector(23 downto 0);
  signal ch_b_data_reg : std_logic_vector(23 downto 0);
  signal ch_a_aux_reg : std_logic_vector(3 downto 0);
  signal ch_b_aux_reg : std_logic_vector(3 downto 0);
  signal ch_a_valid_reg : std_logic;
  signal ch_b_valid_reg : std_logic;
  
begin
  
  -- フレーム解析
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      ch_a_data_reg <= (others => '0');
      ch_b_data_reg <= (others => '0');
      ch_a_aux_reg <= (others => '0');
      ch_b_aux_reg <= (others => '0');
      ch_a_valid_reg <= '0';
      ch_b_valid_reg <= '0';
    elsif rising_edge(clk) then
      if frame_complete = '1' then
        -- チャネルA: ビット95～72 (オーディオ24ビット)
        ch_a_data_reg <= shift_reg(95 downto 72);
        -- チャネルA: ビット71～68 (AUX 4ビット)
        ch_a_aux_reg <= shift_reg(71 downto 68);
        -- チャネルA Validity ビット 66
        ch_a_valid_reg <= not shift_reg(66);  -- 0=有効
        
        -- チャネルB: ビット191～168 (オーディオ24ビット)
        ch_b_data_reg <= shift_reg(191 downto 168);
        -- チャネルB: ビット167～164 (AUX 4ビット)
        ch_b_aux_reg <= shift_reg(167 downto 164);
        -- チャネルB Validity ビット 162
        ch_b_valid_reg <= not shift_reg(162);  -- 0=有効
      end if;
    end if;
  end process;
  
  ch_a_data <= ch_a_data_reg;
  ch_b_data <= ch_b_data_reg;
  ch_a_aux <= ch_a_aux_reg;
  ch_b_aux <= ch_b_aux_reg;
  ch_a_valid <= ch_a_valid_reg;
  ch_b_valid <= ch_b_valid_reg;

end architecture rtl;
