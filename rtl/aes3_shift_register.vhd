-- AES3 シフトレジスタ
-- シリアルデータをパラレルに変換 (192ビット)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity aes3_shift_register is
  port (
    clk               : in  std_logic;                    -- メインクロック
    rst_n             : in  std_logic;                    -- リセット
    bit_clk           : in  std_logic;                    -- ビットクロック
    aes3_in           : in  std_logic;                    -- AES3入力
    preamble_detected : in  std_logic;                    -- プリアンブル検出
    shift_reg         : out std_logic_vector(191 downto 0); -- シフトレジスタ
    bit_count         : out std_logic_vector(7 downto 0); -- ビットカウント
    frame_complete    : out std_logic                     -- フレーム完成
  );
end entity aes3_shift_register;

architecture rtl of aes3_shift_register is
  
  signal shift_reg_int : std_logic_vector(191 downto 0);
  signal bit_cnt : std_logic_vector(7 downto 0);
  signal frame_complete_int : std_logic;
  signal sync_aes3 : std_logic_vector(2 downto 0);
  signal prev_bit_clk : std_logic;
  signal bit_clk_edge : std_logic;
  
begin
  
  -- 入力同期化
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      sync_aes3 <= (others => '0');
      prev_bit_clk <= '0';
    elsif rising_edge(clk) then
      sync_aes3 <= sync_aes3(1 downto 0) & aes3_in;
      prev_bit_clk <= bit_clk;
    end if;
  end process;
  
  -- ビットクロックの立ち上がり検出
  bit_clk_edge <= bit_clk and not prev_bit_clk;
  
  -- シフトレジスタとカウンター
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      shift_reg_int <= (others => '0');
      bit_cnt <= (others => '0');
      frame_complete_int <= '0';
    elsif rising_edge(clk) then
      frame_complete_int <= '0';
      
      if preamble_detected = '1' then
        -- プリアンブル検出でリセット
        shift_reg_int <= (others => '0');
        bit_cnt <= (others => '0');
      elsif bit_clk_edge = '1' then
        -- シフトレジスタ左シフト
        shift_reg_int <= shift_reg_int(190 downto 0) & sync_aes3(2);
        
        -- ビットカウント
        if bit_cnt = 191 then
          -- 192ビット完成
          bit_cnt <= (others => '0');
          frame_complete_int <= '1';
        else
          bit_cnt <= bit_cnt + 1;
        end if;
      end if;
    end if;
  end process;
  
  shift_reg <= shift_reg_int;
  bit_count <= bit_cnt;
  frame_complete <= frame_complete_int;

end architecture rtl;
