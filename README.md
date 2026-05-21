# WordTrainer

SwiftUI で作った、語句を手動入力して学習するための iOS アプリです。

## 機能

- 語句、問題文・意味、シリーズ、例文、メモを手入力で登録
- 登録した語句の検索、編集、削除
- 教科や単元ごとのシリーズ管理
- シリーズ別の復習
- 手入力と選択式の回答形式を語句ごとに設定
- 未学習・学習中・覚えた、の習得状況管理
- 問題文を見て語句を答える復習クイズ
- 登録数や暗記率の簡単な記録表示
- 端末内の Documents に JSON でローカル保存

## Xcode で動かす方法

1. macOS の Xcode で `WordTrainer.xcodeproj` を開きます。
2. iPhone シミュレータを選択して Run します。
3. 実機で動かす場合は、Signing & Capabilities で Team と Bundle Identifier を自分の環境に合わせて変更します。

## 推奨環境

- Xcode 15 以降
- iOS 17 以降
