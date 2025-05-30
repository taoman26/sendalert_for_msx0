# sendalert_for_msx0 - MSX0熱中症アラートプログラム

MSX0マイコンボード用の熱中症アラートプログラムです。温度・湿度センサー（DHT）とネットワーク機能を使用して、環境データをAmbientサービスに送信し、危険な条件を検知した場合はGoogle Home Notifierを通じて音声アラートを出力します。

## 機能

- DHT温湿度センサーから温度と湿度データを取得
- MSX0のバッテリーレベルを監視
- 収集したデータをAmbientサービスに定期的に送信
- 設定された閾値（温度28℃以上かつ湿度60%以上）で熱中症アラートを検知
- Google Home NotifierサーバーへHTTPリクエストを送信し、Google Home端末で音声アラートを再生
- 一定時間待機後に再起動または継続動作の選択が可能

## 必要なもの

- MSX0本体
- DHT温湿度センサー（MSX0に接続）
- インターネット接続環境
- Ambientアカウントとチャンネル設定
- Google Home端末とGoogle Home Notifierサーバー

## セットアップ方法

1. Ambient (https://ambidata.io/) でアカウントを作成し、データチャンネルを設定します
2. Google Home Notifierをサーバー上で設定します
3. `SENDALERT.BAS`を編集し、以下の設定値を変更します：

```basic
140    CH$="xxxxx"             'Ambientのチャンネルコード
150    WK$="xxxxx"             'Ambientのライトキー
160    WT=300                  'データ送信間隔（秒）
170    RB=0                    'リブートモード（0:待機モード, 1:リブートモード）
180    GA$="xxx.xxx.xxx.xxx"  'Google Home NotifierサーバーのIPアドレス
182    DB=0                    'デバッグモード（1:Google Home Notifierテストのみ実行）
```

## 使用方法

1. DHT温湿度センサーをMSX0に接続します
2. MSX0のBASIC環境で`LOAD "SENDALERT.BAS"`を実行します
3. `RUN`コマンドでプログラムを開始します

プログラムは以下の動作を行います：
- 設定された間隔（デフォルト300秒）でセンサーデータを読み取りAmbientに送信します
- 温度28℃以上かつ湿度60%以上の条件を検知すると、Google Home経由で熱中症アラートを発声します
- コンソールには接続状態やデータ送信の進行状況が表示されます

## アラートメッセージ

熱中症アラート条件（温度28℃以上かつ湿度60%以上）を検知した場合、以下のようなメッセージがGoogle Homeから流れます：

> 温度はXXで、湿度はXXパーセントです。熱中症に注意してください。

※ MSX0の日本語処理の制限によりテキスト文字化けが発生するため、プログラム内ではローマ字（英語表記）を使用しています:
```basic
GM$="ondo wa "+STR$(D1)+" de, shitsudo wa "+STR$(D2)+"% desu. Ne-chuushou ni chuui shite kudasai."
```

この変更により、日本語テキストの文字化け問題を回避し、Google Home Notifierがメッセージを正しく処理できるようになります。

## 技術的な詳細

- MSX0のIOT機能（_IOTPUT、_IOTGET）を使用してネットワーク通信を実現
- HTTPリクエストを使用してAmbientサービスとGoogle Home Notifierにデータを送信
- 定期的なデータ送信後は、待機モード（WT秒間の待機）またはリブートモード（WT秒後に再起動）のいずれかで動作します
- MSX BASICの変数名制限（2文字）に対応するため、すべての変数を2文字以下に最適化しています
- Google Home Notifierへの接続試行は最大3回まで行い、接続の安定性を向上させています
- HTTPヘッダーとボディの間に空行（GS$(6)=NL$）を追加し、正しいHTTPリクエスト形式を確保
- URLエンコードされた形式でデータを送信するため、Content-Typeヘッダーを `application/x-www-form-urlencoded` に設定
- レスポンス内の "200 OK" 文字列を検出して成功を確認するロジックを追加
- デバッグ情報の出力機能を強化し、POSTリクエストボディの確認が容易に

## 注意事項

- Google Home Notifierへの接続が失敗しても、Ambientへのデータ送信は継続されます
- 熱中症の危険性は温度・湿度以外の要因にも左右されるため、本プログラムは参考情報としてご利用ください
- 長時間の運用を行う場合は、MSX0の電源管理に注意してください

## トラブルシューティング

### Google Home Notifierとの接続問題

1. **接続エラーの確認**: プログラム実行時に「Google Home Connection Status: 0」と表示される場合は接続エラーです
2. **IPアドレスの確認**: Google Home NotifierサーバーのIPアドレス（GA$）が正しく設定されているか確認してください
3. **ポートの確認**: Google Home Notifierは8091ポートを使用します。ファイアウォールでこのポートが開放されているか確認してください
4. **デバッグモードの使用**: DB=1に設定してプログラムを実行すると、センサーデータの取得とAmbientへの送信をスキップして、Google Home Notifier接続のテストのみを行います
5. **HTTPリクエスト形式の確認**: Google Home Notifierへのリクエストが正しく送信されているか確認するには、実行時に表示される「POST Body (actual): 」の出力を確認してください
6. **レスポンス確認**: 「Google Home notification sent successfully」と表示された場合は成功、「Google Home notification might have failed」と表示された場合は失敗を意味します

### 文字化けの問題

- MSX0のBASICプログラムでメッセージに日本語を使用すると文字化けが発生することがあります
- この問題を解決するため、プログラムではメッセージをローマ字表記に変更しています
- ローマ字表記は日本語発音を正確に再現し、Google Home Notifierが正しく音声化できます
- `GM$="ondo wa "+STR$(D1)+" de, shitsudo wa "+STR$(D2)+"% desu. Ne-chuushou ni chuui shite kudasai."` の形式で実装

## 動作確認方法

プログラムを実行すると、コンソールに以下のような情報が表示されます：

1. Ambientへのデータ送信:
```
---- Send Message to Ambient ----
POST /api/v2/channels/xxxxx/data HTTP/1.1
Host: 54.65.206.59
Content-Length:70
Content-Type: application/json

{"writeKey":"xxxxx","d1":"28","d2":"60","d3":"100"}

---- Receive Message from Ambient ----
HTTP/1.1 200 OK
...
```

2. Google Home Notifierへの接続とメッセージ送信（条件を満たした場合のみ）:
```
---- Connecting to Google Home Notifier ----
Address: xxx.xxx.xxx.xxx:8091
Connecting...
1 times trying to connect to xxx.xxx.xxx.xxx:8091...
Google Home Connection Status: 1

---- Send Message to Google Home Notifier ----
Message: ondo wa 28 de, shitsudo wa 60% desu. Ne-chuushou ni chuui shite kudasai.
Address: xxx.xxx.xxx.xxx:8091
POST Body (actual): text=ondo wa 28 de, shitsudo wa 60% desu. Ne-chuushou ni chuui shite kudasai.
POST /google-home-notifier HTTP/1.1
Host: xxx.xxx.xxx.xxx:8091
Content-Length: 74
Content-Type: application/x-www-form-urlencoded
Accept: */*
Connection: close

text=ondo wa 28 de, shitsudo wa 60% desu. Ne-chuushou ni chuui shite kudasai.

---- Google Home Notifier Response ----
HTTP/1.1 200 OK
...
Google Home notification sent successfully
```

接続状況やレスポンスを確認して、プログラムが正常に動作しているかを判断できます。

## 改善点と更新履歴

### 最新の修正

1. **HTTP要求形式の修正**
   - ヘッダーとボディの間に空行を追加 (`GS$(6)=NL$`)
   - 正しいContent-Typeヘッダー (`application/x-www-form-urlencoded`) を設定

2. **文字エンコーディングの問題解決**
   - 日本語テキストをローマ字表記に変更
   - Google Home Notifierとの互換性を確保
   - `GM$="ondo wa "+STR$(D1)+" de, shitsudo wa "+STR$(D2)+"% desu. Ne-chuushou ni chuui shite kudasai."`

3. **コード構造の改善**
   - 重複する行番号の修正（特に476-501行付近）
   - GOTOリファレンスの適切な行番号への修正
   - デバッグ情報とエラーハンドリングの強化

4. **通信の安定性向上**
   - レスポンス内の "200 OK" 検出による成功確認機能
   - デバッグ出力の強化 (`PRINT "POST Body (actual): "; GP$`)
   - 最大3回の再接続試行による接続安定性の向上
