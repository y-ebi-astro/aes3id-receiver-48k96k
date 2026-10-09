-- AES3id レシーバー トップレベルモジュール
-- 48kHz/96kHz 対応
-- シリアルパラレル変換機能付き

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity aes3_receiver_top is
  generic (
    CLOCK_FREQ : integer := 50_000_000  -- クロック周波数 (Hz)
  );
  port (
    -- クロックとリセット
    clk           : in  std_logic;                     -- メインクロック
    rst_n         : in  std_logic;                     -- リセット (アクティブロー)
    
    -- AES3入力
    aes3_in       : in  std_logic;                     -- AES3シリアル入力
    
    -- 出力データ
    ch_a_data     : out std_logic_vector(23 downto 0); -- チャネルA オーディオデータ
    ch_b_data     : out std_logic_vector(23 downto 0); -- チャネルB オーディオデータ
    ch_a_aux      : out std_logic_vector(3 downto 0);  -- チャネルA AUXデータ
    ch_b_aux      : out std_logic_vector(3 downto 0);  -- チャネルB AUXデータ
    ch_a_valid    : out std_logic;                     -- チャネルA データ有効
    ch_b_valid    : out std_logic;                     -- チャネルB データ有効
    
    -- ステータス
    frame_sync    : out std_logic;                     -- フレーム同期検出
    sample_rate   : out std_logic_vector(1 downto 0);  -- サンプリングレート (00=48kHz, 01=96kHz)
    frame_error   : out std_logic                      -- フレームエラー
  );
end entity aes3_receiver_top;

architecture rtl of aes3_receiver_top is
  
  -- クロック生成
  signal bit_clk : std_logic;
  signal frame_clk : std_logic;
  
  -- フレーム検出
  signal frame_detected : std_logic;
  signal preamble_detected : std_logic;
  signal preamble_type : std_logic_vector(1 downto 0);
  
  -- シフトレジスタ
  signal shift_reg : std_logic_vector(191 downto 0);
  signal bit_count : std_logic_vector(7 downto 0);
  
  -- デコード信号
  signal frame_complete : std_logic;
  
begin

  -- クロック生成モジュール
  clk_gen_inst : entity work.aes3_clock_gen
    generic map (
      CLOCK_FREQ => CLOCK_FREQ
    )
    port map (
      clk => clk,
      rst_n => rst_n,
      bit_clk => bit_clk,
      frame_clk => frame_clk,
      sample_rate => sample_rate
    );
  
  -- フレーム検出モジュール
  frame_det_inst : entity work.aes3_frame_detector
    port map (
      clk => clk,
      rst_n => rst_n,
      bit_clk => bit_clk,
      aes3_in => aes3_in,
      preamble_detected => preamble_detected,
      preamble_type => preamble_type,
      frame_error => frame_error
    );
  
  -- シフトレジスタモジュール
  shift_reg_inst : entity work.aes3_shift_register
    port map (
      clk => clk,
      rst_n => rst_n,
      bit_clk => bit_clk,
      aes3_in => aes3_in,
      preamble_detected => preamble_detected,
      shift_reg => shift_reg,
      bit_count => bit_count,
      frame_complete => frame_complete
    );
  
  -- デコーダモジュール
  decoder_inst : entity work.aes3_decoder
    port map (
      clk => clk,
      rst_n => rst_n,
      frame_complete => frame_complete,
      shift_reg => shift_reg,
      ch_a_data => ch_a_data,
      ch_b_data => ch_b_data,
      ch_a_aux => ch_a_aux,
      ch_b_aux => ch_b_aux,
      ch_a_valid => ch_a_valid,
      ch_b_valid => ch_b_valid
    );
  
  -- フレーム同期信号
  frame_sync <= preamble_detected;

end architecture rtl;
