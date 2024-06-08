const express = require('express');
const readline = require("readline");
const app = express()

process.stdin.setEncoding("utf8");

let lines = {};
let readLineCount = 0;
const reader = readline.createInterface({
  input: process.stdin,
});

reader.on("line", (line) => {
  //改行ごとに"line"イベントが発火される
  if (line) { // 空行がもし来たら無視(USIでは使わないので)
    lines[readLineCount++] = line;
  }
});


// req.bodyにPOSTデータを入れる設定
app.use(express.raw({ type: '*/*', limit: '128kb' }));

const port = 4090;
const server = app.listen(port, () => {
  console.error(`Server listening on port ${port}`);
});

let lastWriteLineNumber = -1;
app.post('/write', (req, res)=> {
  const text = req.body.toString('utf-8');
  const lines = text.split('\n');
  if (lines.length === 0 || lines[lines.length - 1] !== "EOT") {
    // wrong format
    console.error("/write: wrong format is given")
    res.sendStatus(400);
    res.end();
    return;
  }

  for (let i = 0; i < lines.length - 1; i++) {
    const [lineNumberString, content] = lines[i].split(",", 2);
    const lineNumber = Number(lineNumberString);
    if (!(lineNumber >= 0)) {
      console.error("/write: wrong line number is given")
      res.sendStatus(400);
      res.end();
      return;
    }
    if (lineNumber <= lastWriteLineNumber) {
      // すでに受け取った行
      console.error("/write: duplicate line number")
      continue;
    }
    lastWriteLineNumber = lineNumber;
    console.log(content);
  }
  res.send('1');
  res.end();
});

function wait(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

app.post('/read', async (req, res)=> {
  const offset = Number(req.query.offset);
  // offset未満の番号はもう受信されたので、削除する
  for (let i = offset - 1; i >= 0; i--) {
    if (!(i in lines)) {
      break;
    }
    delete lines[i];
  }

  // 行番号を付与したデータを作成
  let line = "";
  let quit = false;
  // ロングポーリング風。すぐ返すべき重要なメッセージがなければ少し待ってから返す
  for (let t = 0; t < 20; t++) {
    let j = offset;
    line = "";
    let important = false;
    while (j in lines) {
      const item = lines[j];
      if (item.startsWith("go") || item.startsWith("ponderhit") || item.startsWith("stop")) {
        important = true;
      }
      if (item === "quit") {
        quit = true;
      }
      line += `${j},${item}\n`;
      j += 1;
    }

    if (important) {
      break;
    }

    await wait(10);
  }
  line += "EOT";

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
