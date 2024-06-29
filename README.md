# やねうら王 on Apple Watch

2024年6月29日開催、[NPO法人AI電竜戦プロジェクト主催 第5回電竜戦TSEC指定局面戦](https://denryu-sen.jp/denryusen/dr5_tsec/dr1_live.php) に将棋AI「うぉっち・ざ・るーく！」として参加したソフトです。第1部で11勝13敗で23位（28チーム中）。記事: https://select766.hatenablog.com/entry/2024/06/29/192614

# モデルについて
nnue-pytorchにより独自学習した。
shogi_hao_depth9データセットを利用。1008ファイルを学習に、8ファイルをvalidationに使用。
batch size=16384

形式は標準NNUE (halfkp_256x2-32-32)。
Apple Watchの探索速度を想定したノード数制限で、1手1秒の場合に水匠5に対してレート+67。

# Mac側セットアップ

Xcode、node 20.xを用意する。

`YaneuraOuWatch Watch App/ContentView.swift` の冒頭で、Mac側のIPアドレスを設定する。

```
cd server
npm install
```

`server/server.sh` 内ではnodeを起動しているが、シェルの環境変数が効かないので、適切な絶対パス指定が必要。

Xcodeでプロジェクトをデバッグ実行。

将棋所に `server/server.sh` をエンジンとして登録する。

エンジン登録待機状態で、watchOSアプリ画面のConnectボタンをタップ。エンジン登録されるはず。

エンジン登録や対局終了時にはサーバが終了するため、対局開始の前にアプリを再起動し、対局開始ボタンを押した後でConnectボタンをタップする必要がある。

# Macとの通信

URLSessionを使うしかない。

無線LAN環境で時折通信エラーが発生し、回復できずに対局続行が不可能になる場合があるため、独自の再送機構を設ける。

## read (Mac->watch)について

`/read` endpoint

サーバとしては送り終わったつもりでも、クライアントが受け取れない場合がリスク。
行に通し番号を付与して、リクエストパラメータに、オフセットを付与する。通し番号は0から開始する。送信時は先頭に番号とカンマを付与。最後の行にEOTを付与し、中途半端に切れた場合を検出可能にする。

`/read?offset=10`

```
10,position
11,go
EOT
```

次回は `/read?offset=12` とする。受信エラーの場合は、再度 `/read?offset=10` でリクエストする。

## write (watch->Mac)について

`/write` endpoint

クライアントとしては、サーバから正常なレスポンスが得られれば送れたことは確認可能。一方、サーバが正常なレスポンスを返したが、クライアントが受け取れなかった場合には再送したデータが重複する場合がある。
行に通し番号を付与して、サーバはすでに受け取った行は破棄する。送信時は先頭に番号とカンマを付与。最後の行にEOTを付与し、中途半端に切れた場合を検出可能にする。

```
10,info pv X
11,info pv Y
12,bestmove
EOT
```

# ライセンス

CC0

ただし、ビルドの際に依存ライブラリがダウンロードされます。思考エンジンとしてやねうら王をビルドしたもの( https://github.com/select766/YaneuraOuiOSSPM/tree/watchos )がダウンロードされ、これはGPLv3ライセンスですのでご注意ください。

