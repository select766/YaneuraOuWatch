const express = require('express');
const readline = require("readline");
const app = express()

process.stdin.setEncoding("utf8");

let lines = [];
const reader = readline.createInterface({
  input: process.stdin,
});

reader.on("line", (line) => {
  //改行ごとに"line"イベントが発火される
  lines.push(line); //ここで、lines配列に、標準入力から渡されたデータを入れる
});


// req.bodyにPOSTデータを入れる設定
app.use(express.raw({ type: '*/*', limit: '128kb' }));

const port = 4090;
const server = app.listen(port, () => {
  console.error(`Server listening on port ${port}`);
});

app.post('/write', (req, res)=> {
  let text = req.body.toString('utf-8');
  let lines = text.split('\n');
  for (const line of lines) {
    console.log(line);
  }
  res.send('1');
  res.end();
});

app.post('/read', (req, res)=> {
  const quit = lines.some((v) => v == "quit");
  const line = lines.join('\n');
  lines = [];
  res.send(line);
  res.end();

  if (quit) {
    // クライアントがquitを読み次第、サーバプロセスを終了する
    setTimeout(() => {
      server.close();
    }, 100);
  }
});

reader.on("close", () => {
    // stdinが閉じられたら終了。ただし、将棋所は対局が終わっても閉じてくれない
    console.error('stdin closed');
    server.close();
});
