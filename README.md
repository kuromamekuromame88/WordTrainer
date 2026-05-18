# WordTrainer

SwiftUI で作った、英単語を手動入力して学習するための iOS アプリです。

## 機能

- 英単語、意味、例文、メモを手入力で登録
- 登録した単語の検索、編集、削除
- 未学習・学習中・覚えた、の習得状況管理
- 日本語の意味を見て英単語を入力する復習クイズ
- 登録数や暗記率の簡単な記録表示
- 端末内の Documents に JSON でローカル保存

## Xcode で動かす方法

1. macOS の Xcode で `WordTrainer.xcodeproj` を開きます。
2. iPhone シミュレータを選択して Run します。
3. 実機で動かす場合は、Signing & Capabilities で Team と Bundle Identifier を自分の環境に合わせて変更します。

## 推奨環境

- Xcode 15 以降
- iOS 17 以降
