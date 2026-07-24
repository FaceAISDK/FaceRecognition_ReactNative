import Foundation
import AVFoundation
import os.log
#if canImport(UIKit)
import UIKit
#endif

// MARK: - TTSPlayer 20260703
final class TTSPlayer: NSObject {

    static let shared = TTSPlayer()

    // MARK: - 播报策略

    enum Policy {
        case interrupt
        case enqueue
        case dropIfBusy
    }

    // MARK: - 状态

    enum State: Equatable {
        case idle
        case speaking(String)
        case paused
    }

    var onStateChanged: ((State) -> Void)?

    /// State 仅限在主线程读写，确保外部 UI 绑定的绝对安全
    private(set) var state: State = .idle {
        didSet {
            guard state != oldValue else { return }
            onStateChanged?(state)
        }
    }

    var isSpeaking: Bool {
        if case .speaking = state { return true }
        return false
    }

    // MARK: - Private

    private let synthesizer = AVSpeechSynthesizer()
    private let log: OSLog
    
    /// 专用串行队列：保证去重、音频会话、播报状态处理顺序一致。
    /// AVSpeechSynthesizer/AudioSession 内部可能使用 default QoS 线程，使用 default 避免高 QoS 等待低 QoS 造成优先级反转告警。
    private let workQueue = DispatchQueue(label: "com.faceAI.sdk.ttsPlayer", qos: .default)

    // 以下变量现在仅在 workQueue 中访问，天然线程安全
    private var isSessionActive = false
    private var pendingDeactivation: DispatchWorkItem?
    /// 人脸检测过程中提示通常连续出现，保活稍久一点可以避免每一句都重新激活 AudioSession 导致“慢半拍”。
    private let sessionDeactivationDelay: TimeInterval = 8.0

    private var voiceCache: [String: AVSpeechSynthesisVoice] = [:]

    /// 仅在 workQueue 访问，避免频繁同步读取 AVSpeechSynthesizer.isSpeaking/isPaused 触发 priority inversion。
    private var synthesizerIsSpeaking = false
    private var synthesizerIsPaused = false

    /// 只去重“相邻两次”的相同文字：A、A 只播第一次；A、B、A 中第二个 A 仍允许播。
    private var lastAcceptedTextKey: String?
    private var preparedLanguages = Set<String>()

    private var interruptedBySystem = false

    // MARK: - Init

    private override init() {
        self.log = OSLog(subsystem: "com.faceAI.sdk", category: "TTSPlayer")
        super.init()
        synthesizer.delegate = self
        addObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public API

    /// 预热音频会话和语音资源，建议在页面 onAppear 时调用。
    /// 这样第一次真正 speak 时不用再同步做 voice 查询和 AudioSession 激活，能明显减少首句“慢半拍”。
    func prepare(language: String? = nil) {
        workQueue.async { [weak self] in
            guard let self = self else { return }

            self.activateSessionIfNeeded()

            let lang = self.normalizedLanguage(language)
            guard !self.preparedLanguages.contains(lang) else { return }

            _ = self.cachedVoice(for: lang)
            self.preparedLanguages.insert(lang)
        }
    }

    /// 播报文本
    func speak(_ text: String?,
               language: String? = nil,
               rate: Float = 0.50,
               pitch: Float = 0.98,
               policy: Policy = .dropIfBusy) {
        let originalText = text ?? ""
        let textKey = normalizedTextKey(originalText)
        guard !textKey.isEmpty else { return }

        workQueue.async { [weak self] in
            guard let self = self else { return }

            // 相邻重复文本只播第一次，避免 SwiftUI body 重复刷新导致同一句反复播报。
            if textKey == self.lastAcceptedTextKey {
                return
            }

            switch policy {
            case .interrupt:
                self.synthesizer.stopSpeaking(at: .immediate)

            case .enqueue:
                break

            case .dropIfBusy:
                // 默认策略：前一句没播完时，不打断，也不追加队列，避免提示越排越滞后。
                guard !self.synthesizerIsSpeaking && !self.synthesizerIsPaused else { return }
            }

            self.lastAcceptedTextKey = textKey

            let lang = self.normalizedLanguage(language)
            self.activateSessionIfNeeded()

            let utterance = AVSpeechUtterance(string: originalText.trimmingCharacters(in: .whitespacesAndNewlines))
            let clampedRate = min(max(rate, 0), 1)
            utterance.rate = AVSpeechUtteranceMinimumSpeechRate
                + clampedRate * (AVSpeechUtteranceMaximumSpeechRate - AVSpeechUtteranceMinimumSpeechRate)
            utterance.pitchMultiplier = min(max(pitch, 0.5), 2.0)

            // 去掉人为前置延迟，缩短后置延迟，减少连续提示时的“慢半拍”。
            utterance.preUtteranceDelay = 0
            utterance.postUtteranceDelay = 0.03
            utterance.voice = self.cachedVoice(for: lang)

            self.synthesizerIsSpeaking = true
            self.synthesizerIsPaused = false
            self.synthesizer.speak(utterance)
        }
    }

    /// 清空相邻去重记录。
    /// 如果一个流程结束后，希望下次进入页面同一句提示仍能重新播放，可在 onAppear/onDisappear 调用。
    func resetDuplicateHistory() {
        workQueue.async { [weak self] in
            self?.lastAcceptedTextKey = nil
        }
    }

    /// 停止当前播报，并清空已排队的语音。
    func stop() {
        workQueue.async { [weak self] in
            guard let self = self else { return }
            self.stopSynthesizerIfActive()
        }
    }

    func pause() {
        workQueue.async { [weak self] in
            guard let self = self else { return }
            if self.synthesizerIsSpeaking, self.synthesizer.pauseSpeaking(at: .word) {
                self.synthesizerIsSpeaking = false
                self.synthesizerIsPaused = true
            }
        }
    }

    func resume() {
        workQueue.async { [weak self] in
            guard let self = self else { return }
            if self.synthesizerIsPaused {
                self.activateSessionIfNeeded()
                if self.synthesizer.continueSpeaking() {
                    self.synthesizerIsSpeaking = true
                    self.synthesizerIsPaused = false
                }
            }
        }
    }

    func release() {
        workQueue.async { [weak self] in
            guard let self = self else { return }
            self.stopSynthesizerIfActive()
            self.deactivateSessionNow()
            self.voiceCache.removeAll()
            self.preparedLanguages.removeAll()
            self.lastAcceptedTextKey = nil
        }
    }
    
    private func stopSynthesizerIfActive() {
        if synthesizerIsSpeaking || synthesizerIsPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        synthesizerIsSpeaking = false
        synthesizerIsPaused = false
    }

    // MARK: - Audio Session (仅在 workQueue 内调用)

    private func activateSessionIfNeeded() {
        pendingDeactivation?.cancel()
        pendingDeactivation = nil

        guard !isSessionActive else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            isSessionActive = true
        } catch {
            os_log("AudioSession activate failed: %{public}@", log: log, type: .error, error.localizedDescription)
        }
    }

    private func scheduleDeactivation() {
        pendingDeactivation?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.deactivateSessionNow()
        }
        pendingDeactivation = item
        workQueue.asyncAfter(deadline: .now() + sessionDeactivationDelay, execute: item)
    }

    private func deactivateSessionNow() {
        pendingDeactivation?.cancel()
        pendingDeactivation = nil
        guard isSessionActive else { return }
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            isSessionActive = false
        } catch {
            os_log("AudioSession deactivate failed: %{public}@", log: log, type: .error, error.localizedDescription)
        }
    }

    // MARK: - Observers

    private func addObservers() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(handleInterruption),
                       name: AVAudioSession.interruptionNotification, object: nil)
        nc.addObserver(self, selector: #selector(handleRouteChange),
                       name: AVAudioSession.routeChangeNotification, object: nil)
        #if canImport(UIKit)
        nc.addObserver(self, selector: #selector(handleDidEnterBackground),
                       name: UIApplication.didEnterBackgroundNotification, object: nil)
        #endif
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
        let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)

        workQueue.async { [weak self] in
            guard let self = self else { return }
            
            switch type {
            case .began:
                self.interruptedBySystem = self.synthesizerIsSpeaking || self.synthesizerIsPaused
                self.isSessionActive = false
                self.synthesizerIsSpeaking = false
                self.synthesizerIsPaused = false

            case .ended:
                let shouldResume = self.interruptedBySystem
                self.interruptedBySystem = false

                if shouldResume, options.contains(.shouldResume) {
                    self.activateSessionIfNeeded()
                    if self.synthesizer.continueSpeaking() {
                        self.synthesizerIsSpeaking = true
                        self.synthesizerIsPaused = false
                    }
                } else if shouldResume {
                    self.stopSynthesizerIfActive()
                }

            @unknown default:
                break
            }
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        if reason == .oldDeviceUnavailable {
            workQueue.async { [weak self] in
                guard let self = self else { return }
                if self.synthesizerIsSpeaking, self.synthesizer.pauseSpeaking(at: .word) {
                    self.synthesizerIsSpeaking = false
                    self.synthesizerIsPaused = true
                }
            }
        }
    }

    @objc private func handleDidEnterBackground() {
        workQueue.async { [weak self] in
            self?.stopSynthesizerIfActive()
        }
    }

    // MARK: - Voice Selection (仅在 workQueue 内调用)

    private func cachedVoice(for language: String?) -> AVSpeechSynthesisVoice? {
        let lang = normalizedLanguage(language)
        if let cached = voiceCache[lang] { return cached }
        let voice = bestVoice(for: lang)
        if let voice = voice { voiceCache[lang] = voice }
        return voice
    }

    private func bestVoice(for lang: String) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()

        let candidates: [AVSpeechSynthesisVoice] = {
            let exact = voices.filter { $0.language == lang }
            if !exact.isEmpty { return exact }

            let prefix = lang.components(separatedBy: "-").first ?? lang
            let prefixed = voices.filter { $0.language.hasPrefix(prefix) }
            if !prefixed.isEmpty { return prefixed }

            if prefix == "zh" {
                let cn = voices.filter { $0.language == "zh-CN" }
                if !cn.isEmpty { return cn }
                let tw = voices.filter { $0.language == "zh-TW" }
                if !tw.isEmpty { return tw }
            }

            return voices.filter { $0.language == "en-US" }
        }()

        return candidates.max(by: { $0.quality.rawValue < $1.quality.rawValue })
    }

    // MARK: - Helpers

    private func normalizedLanguage(_ language: String?) -> String {
        let lang = language ?? Locale.preferredLanguages.first ?? "en-US"
        let trimmed = lang.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "en-US" : trimmed
    }

    private func normalizedTextKey(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    /// 安全地向主线程抛出状态变更
    private func updateStateOnMainThread(_ newState: State) {
        if Thread.isMainThread {
            self.state = newState
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.state = newState
            }
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TTSPlayer: AVSpeechSynthesizerDelegate {

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        workQueue.async { [weak self] in
            self?.synthesizerIsSpeaking = true
            self?.synthesizerIsPaused = false
        }
        updateStateOnMainThread(.speaking(utterance.speechString))
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        updateStateOnMainThread(.idle)
        workQueue.async { [weak self] in
            guard let self = self else { return }
            self.synthesizerIsSpeaking = false
            self.synthesizerIsPaused = false
            self.scheduleDeactivation()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        updateStateOnMainThread(.idle)
        workQueue.async { [weak self] in
            guard let self = self else { return }
            self.synthesizerIsSpeaking = false
            self.synthesizerIsPaused = false
            self.scheduleDeactivation()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        workQueue.async { [weak self] in
            self?.synthesizerIsSpeaking = false
            self?.synthesizerIsPaused = true
        }
        updateStateOnMainThread(.paused)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        workQueue.async { [weak self] in
            self?.synthesizerIsSpeaking = true
            self?.synthesizerIsPaused = false
        }
        updateStateOnMainThread(.speaking(utterance.speechString))
    }
}
