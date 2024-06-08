//
//  ContentView.swift
//  YaneuraOuWatch Watch App
//
//  Created by 日高雅俊 on 2024/05/12.
//

import SwiftUI

// FIXME: 将棋所が動いているMacのIPアドレスを指定
let baseURL = "http://192.168.3.11:4090"

struct ContentView: View {
    @State var running = false
    @State var lastMessage = "やねうら王 on Apple Watch"
    @State var writeQueue = [Int:String]()
    @State var writeBusy = false
    @State var readLineNumber = -1
    @State var writeLineNumber = 0

    var body: some View {
        VStack(alignment: .leading) {
            BatteryView()
            Text(lastMessage).frame(maxWidth: .infinity, alignment: .leading)
            if !running {
                Button(action: start) {
                    Text("Connect")
                }.padding()
            }
            Spacer()
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func start() {
        if running {
            return
        }
        running = true
        startYaneuraou(recvCallback: { messageFromYane in
            DispatchQueue.main.async {
                doWrite(message: messageFromYane)
            }
        })
        doRead()
        writeNext()
    }
    
    func doWrite(message: String) {
        // ここで直接HTTP POSTすると順序が乱れる場合があるためキューに入れて順番に送信
        writeQueue[writeLineNumber] = message
        writeLineNumber += 1
    }
    
    func writeNext() {
        if writeQueue.count == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: writeNext)
            return
        }
        
        let maxLineNumber = writeLineNumber
        var minLineNumber = maxLineNumber - 1
        while writeQueue.keys.contains(minLineNumber-1) {
            minLineNumber -= 1
        }
        var message = ""
        for i in minLineNumber..<maxLineNumber {
            message += "\(i),\(writeQueue[i]!)\n"
        }
        message += "EOT"
        lastMessage = "> \(message)"
        let url = URL(string: "\(baseURL)/write")!
        var request = URLRequest(url: url, timeoutInterval: 3.0)
        request.httpMethod = "POST"
        request.httpBody = message.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                lastMessage = "write error: " + String(describing: error)
                print("write error: " + String(describing: error))
                DispatchQueue.main.async {
                    writeNext()
                }
                return
            }
            let message = String(data: data, encoding: .utf8)!
            if message == "1" {
                // 書き込み成功
                // 送信済みメッセージを削除
                DispatchQueue.main.async {
                    for i in minLineNumber..<maxLineNumber {
                        writeQueue.removeValue(forKey: i)
                    }
                    writeNext()
                }
            } else {
                DispatchQueue.main.async {
                    writeNext()
                }
            }
        }
        task.resume()
    }
    
    func doRead() {
        let url = URL(string: "\(baseURL)/read?offset=\(readLineNumber+1)")!
        var request = URLRequest(url: url, timeoutInterval: 3.0)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                lastMessage = "read error: " + String(describing: error)
                print("read error: " + String(describing: error))
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01, execute: doRead)
                return
            }
            let messages = String(data: data, encoding: .utf8)!
            
            DispatchQueue.main.async {
                // 受信済み行番号を触るのでメインスレッドで処理
                processReadMessage(messages: messages)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01, execute: doRead)
            }
        }
        task.resume()
    }
    
    func processReadMessage(messages: String) {
        let linesWithLineNumber = messages.split(separator: "\n")
        if linesWithLineNumber.count > 1 && linesWithLineNumber.last! == "EOT" {
            lastMessage = "< \(messages)"
            for i in 0..<linesWithLineNumber.count-1 {
                let lineWithLineNumber = linesWithLineNumber[i]
                let items = lineWithLineNumber.split(separator: ",", maxSplits: 2)
                if items.count != 2 {
                    print("wrong format: \(lineWithLineNumber)")
                    continue
                }
                
                guard let lineNumber = Int(items[0]) else {
                    print("wrong format: \(lineWithLineNumber)")
                    continue
                }
                
                if lineNumber > readLineNumber {
                    readLineNumber = lineNumber
                    sendToYaneuraou(messageWithoutNewLine: String(items[1]))
                } else {
                    print("duplicate line number \(lineNumber)")
                }
            }
        } else {
            // 正しく受信されなかった or EOTのみ
        }
    }
}

#Preview {
    ContentView()
}
