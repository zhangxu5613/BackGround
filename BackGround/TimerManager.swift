//
//  TimerManager.swift
//  BackGround
//
//  Created by 张徐 on 2025/8/2.
//

import Foundation
import UserNotifications
import BackgroundTasks
import UIKit

class TimerManager: ObservableObject {
    @Published var timeRemaining: TimeInterval = 0
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var totalTime: TimeInterval = 0
    
    private var timer: Timer?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var dispatchTimer: DispatchSourceTimer?
    
    init() {
        setupBackgroundTask()
    }
    
    deinit {
        endBackgroundTask()
    }
    
    // 设置时间
    func setTime(hours: Int, minutes: Int, seconds: Int) {
        totalTime = TimeInterval(hours * 3600 + minutes * 60 + seconds)
        timeRemaining = totalTime
        isRunning = false
        isPaused = false
    }
    
    // 开始倒计时
    func startTimer() {
        guard timeRemaining > 0 else { return }
        
        isRunning = true
        isPaused = false
        
        // 开始后台任务
        beginBackgroundTask()
        
        // 创建 DispatchSourceTimer 用于更可靠的后台倒计时
        let queue = DispatchQueue.global(qos: .userInteractive)
        dispatchTimer = DispatchSource.makeTimerSource(queue: queue)
        dispatchTimer?.schedule(deadline: .now(), repeating: 1.0)
        dispatchTimer?.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.updateTimer()
            }
        }
        dispatchTimer?.resume()
        
        // 同时使用 Timer 用于 UI 更新
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
        
        // 将定时器添加到 RunLoop 中
        RunLoop.main.add(timer!, forMode: .common)
        
        // 设置后台倒计时通知
        scheduleBackgroundNotifications()
    }
    
    // 暂停倒计时
    func pauseTimer() {
        isPaused = true
        timer?.invalidate()
        timer = nil
        dispatchTimer?.cancel()
        dispatchTimer = nil
    }
    
    // 恢复倒计时
    func resumeTimer() {
        guard isPaused else { return }
        
        isPaused = false
        startTimer()
    }
    
    // 重置倒计时
    func resetTimer() {
        timer?.invalidate()
        timer = nil
        dispatchTimer?.cancel()
        dispatchTimer = nil
        timeRemaining = totalTime
        isRunning = false
        isPaused = false
        endBackgroundTask()
    }
    
    // 更新倒计时
    private func updateTimer() {
        print("time decr")
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            timerCompleted()
        }
    }
    
    // 倒计时完成
    private func timerCompleted() {
        timer?.invalidate()
        timer = nil
        dispatchTimer?.cancel()
        dispatchTimer = nil
        isRunning = false
        isPaused = false
        
        // 发送通知
        sendNotification()
        
        // 结束后台任务
        endBackgroundTask()
        
        // 取消所有待处理的通知
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // 发送通知
    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "倒计时完成"
        content.body = "您设定的时间已经到了！"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "timer_completed", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    // 开始后台任务
    private func beginBackgroundTask() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "TimerBackgroundTask") { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    // 结束后台任务
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    // 设置后台任务
    private func setupBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.yourapp.timer", using: nil) { task in
            self.handleBackgroundTask(task: task as! BGAppRefreshTask)
        }
    }
    
    // 处理后台任务
    private func handleBackgroundTask(task: BGAppRefreshTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // 在这里可以执行一些后台任务
        task.setTaskCompleted(success: true)
    }
    

    
    // 格式化时间显示
    func formattedTime() -> String {
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // 获取进度百分比
    func progress() -> Double {
        guard totalTime > 0 else { return 0 }
        return 1.0 - (timeRemaining / totalTime)
    }
    
    // 设置后台倒计时通知
    private func scheduleBackgroundNotifications() {
        // 取消之前的通知
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // 计算倒计时完成时间
        let completionDate = Date().addingTimeInterval(timeRemaining)
        
        // 创建通知内容
        let content = UNMutableNotificationContent()
        content.title = "倒计时完成"
        content.body = "您设定的时间已经到了！"
        content.sound = .default
        content.badge = 1
        
        // 创建触发器
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeRemaining, repeats: false)
        
        // 创建通知请求
        let request = UNNotificationRequest(identifier: "timer_completion", content: content, trigger: trigger)
        
        // 添加通知
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知设置失败: \(error)")
            } else {
                print("后台通知已设置，将在 \(self.timeRemaining) 秒后触发")
            }
        }
    }
    
    // 应用进入后台时的处理
    func applicationDidEnterBackground() {
        if isRunning && !isPaused {
            // 保存当前状态到 UserDefaults
            UserDefaults.standard.set(timeRemaining, forKey: "timeRemaining")
            UserDefaults.standard.set(totalTime, forKey: "totalTime")
            UserDefaults.standard.set(isRunning, forKey: "isRunning")
            UserDefaults.standard.set(isPaused, forKey: "isPaused")
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "startTime")
        }
    }
    
    // 应用进入前台时的处理
    func applicationWillEnterForeground() {
        if isRunning && !isPaused {
            // 从 UserDefaults 恢复状态
            let savedTimeRemaining = UserDefaults.standard.double(forKey: "timeRemaining")
            let savedStartTime = UserDefaults.standard.double(forKey: "startTime")
            let elapsedTime = Date().timeIntervalSince1970 - savedStartTime
            
            // 计算实际剩余时间
            timeRemaining = max(0, savedTimeRemaining - elapsedTime)
            
            if timeRemaining <= 0 {
                timerCompleted()
            }
        }
    }
} 
