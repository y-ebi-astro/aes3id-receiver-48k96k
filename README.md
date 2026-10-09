# AES3id レシーバー (48kHz/96kHz対応)

AES3デジタルオーディオインターフェースをシリアルパラレル変換するVHDL実装です。

## 特徴
- **48kHz/96kHz** サンプリングレート対応
- **シリアルパラレル変換** 機能
- **AES3フレーム同期** 検出
- **24ビット** オーディオデータ対応

## AES3フレーム構造
```
192ビット/フレーム
├── チャネルA（96ビット）
│   ├── 24ビット オーディオデータ
│   ├── 4ビット AUXデータ
│   ├── Vビット (validity)
│   ├── Uビット (user data)
│   ├── Cビット (channel status)
│   └── Pビット (parity)
└── チャネルB（96ビット）
    └── チャネルAと同構造
```

## ファイル構成
```
aes3id-receiver-48k96k/
├── README.md
├── rtl/
│   ├── aes3_receiver_top.vhd      # トップレベルモジュール
│   ├── aes3_frame_detector.vhd    # フレーム同期検出
│   ├── aes3_shift_register.vhd    # シフトレジスタ
│   ├── aes3_decoder.vhd           # デコーダ
│   └── aes3_clock_gen.vhd         # クロック生成
├── sim/
│   ├── tb_aes3_receiver.vhd       # テストベンチ
│   └── aes3_stim.vhd              # 刺激ジェネレータ
└── doc/
    └── aes3_specification.txt     # 仕様書
```

## クロック仕様
- **48kHz**: フレームクロック = 48kHz, ビットクロック = 48kHz × 192 = 9.216MHz
- **96kHz**: フレームクロック = 96kHz, ビットクロック = 96kHz × 192 = 18.432MHz

## 使用方法
詳細は各ファイルのコメントを参照してください。
