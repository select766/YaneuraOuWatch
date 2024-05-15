//
//  ContentView.swift
//  YaneuraOuWatch Watch App
//
//  Created by 日高雅俊 on 2024/05/12.
//

import SwiftUI

// FIXME: 将棋所が動いているMacのIPアドレスを指定
let baseURL = "http://192.168.3.12:4090"

struct ContentView: View {
    @State var running = false
    @State var lastMessage = "やねうら王 on Apple Watch"
    @State var writeQueue = [String]()
    @State var writeBusy = false

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
        writeQueue.append(message)
    }
    
    func writeNext() {
        if writeQueue.count == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: writeNext)
            return
        }
        
        let message = writeQueue.joined(separator: "\n")
        writeQueue.removeAll()
        lastMessage = "> \(message)"
        let url = URL(string: "\(baseURL)/write")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = message.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                writeNext()
            }
        }
        task.resume()
    }
    
    func doRead() {
        let url = URL(string: "\(baseURL)/read")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else { lastMessage = "Error: " + String(describing: error); return; }
            let messages = String(data: data, encoding: .utf8)!
            
            var nextTime = DispatchTime.now()
            if messages.count > 0 {
                lastMessage = "< \(messages)"
                for message in messages.split(separator: "\n") {
                    sendToYaneuraou(messageWithoutNewLine: String(message))
                }

                nextTime = nextTime + 0.01
            } else {
                nextTime = nextTime + 0.1
            }
            
            DispatchQueue.main.asyncAfter(deadline: nextTime, execute: doRead)
        }
        task.resume()
    }
}

#Preview {
    ContentView()
}
