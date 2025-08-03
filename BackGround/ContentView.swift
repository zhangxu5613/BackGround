 //
//  ContentView.swift
//  BackGround
//
//  Created by 张徐 on 2025/8/2.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var timerManager = TimerManager()
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    @State private var showingTimePicker = true
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // 标题
                Text("倒计时")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if showingTimePicker {
                    // 时间设置界面
                    TimePickerView(
                        hours: $hours,
                        minutes: $minutes,
                        seconds: $seconds
                    )
                    
                    // 开始按钮
                    Button(action: {
                        timerManager.setTime(hours: hours, minutes: minutes, seconds: seconds)
                        showingTimePicker = false
                        timerManager.startTimer()
                    }) {
                        Text("开始倒计时")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color.green)
                            .cornerRadius(15)
                    }
                    .disabled(hours == 0 && minutes == 0 && seconds == 0)
                    .opacity(hours == 0 && minutes == 0 && seconds == 0 ? 0.5 : 1.0)
                } else {
                    // 倒计时显示界面
                    TimerView(timerManager: timerManager)
                    
                    // 控制按钮
                    HStack(spacing: 20) {
                        if timerManager.isRunning {
                            Button(action: {
                                timerManager.pauseTimer()
                            }) {
                                Image(systemName: "pause.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.orange)
                                    .clipShape(Circle())
                            }
                        } else if timerManager.isPaused {
                            Button(action: {
                                timerManager.resumeTimer()
                            }) {
                                Image(systemName: "play.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.green)
                                    .clipShape(Circle())
                            }
                        }
                        
                        Button(action: {
                            timerManager.resetTimer()
                            showingTimePicker = true
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                timerManager.applicationWillEnterForeground()
            case .inactive:
                break
            case .background:
                timerManager.applicationDidEnterBackground()
            @unknown default:
                break
            }
        }
    }
}

struct TimePickerView: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Text("设置时间")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                // 小时选择器
                VStack {
                    Text("小时")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Picker("小时", selection: $hours) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text("\(hour)").tag(hour)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 80, height: 120)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                }
                
                // 分钟选择器
                VStack {
                    Text("分钟")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Picker("分钟", selection: $minutes) {
                        ForEach(0..<60, id: \.self) { minute in
                            Text("\(minute)").tag(minute)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 80, height: 120)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                }
                
                // 秒选择器
                VStack {
                    Text("秒")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Picker("秒", selection: $seconds) {
                        ForEach(0..<60, id: \.self) { second in
                            Text("\(second)").tag(second)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 80, height: 120)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
}

struct TimerView: View {
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        VStack(spacing: 20) {
            // 倒计时显示
            ZStack {
                // 进度圆环
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 15)
                    .frame(width: 250, height: 250)
                
                Circle()
                    .trim(from: 0, to: timerManager.progress())
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerManager.timeRemaining)
                
                // 时间显示
                VStack {
                    Text(timerManager.formattedTime())
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text(timerManager.isRunning ? "倒计时中..." : timerManager.isPaused ? "已暂停" : "准备就绪")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
}

#Preview {
    ContentView()
}
