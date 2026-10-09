-- AES3 フレーム検出モジュール
-- プリアンブル検出 (Z, X, Y パターン)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity aes3_frame_detector is
  port (
    clk                : in  std_logic;             -- メインクロック
    rst_n              : in  std_logic;             -- リセット
    bit_clk            : in  std_logic;             -- ビットクロック
    aes3_in            : in  std_logic;             -- AES3入力
    preamble_detected  : out std_logic;             -- プリアンブル検出
    preamble_type      : out std_logic_vector(1 downto 0);  -- 00=Z, 01=X, 10=Y
    frame_error        : out std_logic              -- フレームエラー
  );
end entity aes3_frame_detector;

architecture rtl of aes3_frame_detector is
  
  -- AES3 プリアンブルパターン (BMC符号化)
  -- Z preamble: 1110_0010 (0xE2)
  -- X preamble: 1110_0100 (0xE4)
  -- Y preamble: 1110_1000 (0xE8)
  
  constant Z_PATTERN : std_logic_vector(7 downto 0) := "11100010";
  constant X_PATTERN : std_logic_vector(7 downto 0) := "11100100";
  constant Y_PATTERN : std_logic_vector(7 downto 0) := "11101000";
  
  signal sync_aes3 : std_logic_vector(2 downto 0);  -- CDCシンク
  signal pattern_reg : std_logic_vector(7 downto 0);
  signal bit_cnt : std_logic_vector(3 downto 0);
  signal preamble_found : std_logic;
  signal preamble_type_reg : std_logic_vector(1 downto 0);
  
begin
  
  -- 入力同期化
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      sync_aes3 <= (others => '0');
    elsif rising_edge(clk) then
      sync_aes3 <= sync_aes3(1 downto 0) & aes3_in;
    end if;
  end process;
  
  -- パターンマッチング
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      pattern_reg <= (others => '0');
      bit_cnt <= (others => '0');
      preamble_found <= '0';
      preamble_type_reg <= "00";
      frame_error <= '0';
    elsif rising_edge(clk) then
      if bit_clk = '1' then
        -- シフトレジスタ
        pattern_reg <= pattern_reg(6 downto 0) & sync_aes3(2);
        
        -- ビットカウント
        if bit_cnt = 7 then
          bit_cnt <= (others => '0');
          
          -- パターン検出
          if pattern_reg = Z_PATTERN then
            preamble_found <= '1';
            preamble_type_reg <= "00";
            frame_error <= '0';
          elsif pattern_reg = X_PATTERN then
            preamble_found <= '1';
            preamble_type_reg <= "01";
            frame_error <= '0';
          elsif pattern_reg = Y_PATTERN then
            preamble_found <= '1';
            preamble_type_reg <= "10";
            frame_error <= '0';
          else
            preamble_found <= '0';
            frame_error <= '1';
          end if;
        else
          bit_cnt <= bit_cnt + 1;
          preamble_found <= '0';
        end if;
      end if;
    end if;
  end process;
  
  preamble_detected <= preamble_found;
  preamble_type <= preamble_type_reg;

end architecture rtl;
