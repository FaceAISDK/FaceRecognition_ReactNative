// FaceAISDK.Service@gmail.com , https://github.com/FaceAISDK

import AVFoundation
import Foundation
import os.log
#if canImport(UIKit)
    import UIKit
#endif

// MARK: - TTS player / 语音播放器

/// Serializes speech operations on the main thread; public commands are thread-safe.
/// 在主线程串行执行语音操作，公开命令支持跨线程调用。
final class TTSPlayer: NSObject {

    static let shared = TTSPlayer()

    // MARK: - Public types / 公开类型

    enum Policy {
        /// Replaces current and queued speech. 替换当前及排队语音。
        case interrupt
        /// Appends speech to the bounded queue. 将语音加入有限队列。
        case enqueue
        /// Drops new speech while busy. 忙碌时丢弃新语音。
        case dropIfBusy
    }

    enum State: Equatable {
        case idle
        case speaking(String)
        case paused
    }

    struct Configuration {
        /// Default BCP-47 language; `nil` uses the preferred system language. 默认 BCP-47 语言，`nil` 使用系统首选语言。
        var defaultLanguage: String?

        /// Normalized 0...1 rate mapped to Apple's range. 映射到 Apple 语速范围的 0...1 标准值。
        var defaultRate: Float = 0.50
        var defaultPitch: Float = 0.98

        /// Suppresses adjacent duplicates within this interval; A → B → A remains valid.
        /// 在该时间内抑制相邻重复文本，但允许 A → B → A。
        var duplicateSuppressionInterval: TimeInterval = .infinity

        /// Bounds queued guidance. 限制排队提示数量。
        var maximumQueueDepth: Int = 8

        /// Delay before releasing the audio session. 释放音频会话前的延迟。
        var sessionDeactivationDelay: TimeInterval = 2.0

        /// Disable when the host owns AVAudioSession. 宿主管理 AVAudioSession 时关闭。
        var managesAudioSession: Bool = true
        var audioSessionCategory: AVAudioSession.Category = .playback
        var audioSessionMode: AVAudioSession.Mode = .spokenAudio
        var audioSessionOptions: AVAudioSession.CategoryOptions = [.duckOthers]

        /// Stops face guidance in the background. 进入后台时停止人脸提示。
        var stopsOnBackground: Bool = true

        init() {}
    }

    /// Main-thread callback; capture owners weakly because the player is a singleton.
    /// 主线程回调；播放器是单例，需弱引用回调持有者。
    var onStateChanged: ((State) -> Void)?

    /// Read on the main thread. 请在主线程读取。
    private(set) var state: State = .idle {
        didSet {
            guard state != oldValue else { return }
            onStateChanged?(state)
        }
    }

    /// Read on the main thread. 请在主线程读取。
    var isSpeaking: Bool {
        if case .speaking = state { return true }
        return false
    }

    // MARK: - Private types / 私有类型

    private final class SpeechRequest {
        let text: String
        let textKey: String
        let utterance: AVSpeechUtterance

        init(text: String, textKey: String, utterance: AVSpeechUtterance) {
            self.text = text
            self.textKey = textKey
            self.utterance = utterance
        }
    }

    private struct AudioSessionSnapshot {
        let category: AVAudioSession.Category
        let mode: AVAudioSession.Mode
        let options: AVAudioSession.CategoryOptions
    }

    // MARK: - Private state / 私有状态

    private let log = OSLog(subsystem: "com.faceAI.sdk", category: "TTSPlayer")

    /// Lazily created on main even when first requested elsewhere. 即使首次从其他线程访问，也在主线程延迟创建。
    private lazy var synthesizer: AVSpeechSynthesizer = {
        dispatchPrecondition(condition: .onQueue(.main))
        let value = AVSpeechSynthesizer()
        value.delegate = self
        return value
    }()

    private var configuration = Configuration()
    private var currentRequest: SpeechRequest?
    private var pendingRequests: [SpeechRequest] = []

    private var lastAcceptedTextKey: String?
    private var lastAcceptedTime: TimeInterval = 0

    private var voiceCache: [String: AVSpeechSynthesisVoice] = [:]
    private var unavailableVoiceLanguages = Set<String>()

    private var isSessionActive = false
    private var audioSessionSnapshot: AudioSessionSnapshot?
    private var pendingDeactivation: DispatchWorkItem?

    private var shouldResumeAfterInterruption = false

    // MARK: - Lifecycle / 生命周期

    private override init() {
        super.init()
        addObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public API / 公开接口

    /// Replaces configuration; call while idle when possible. 替换配置，建议空闲时调用。
    func configure(_ configuration: Configuration) {
        executeOnMain { player in
            player.configuration = player.sanitized(configuration)
        }
    }

    /// Warms voice lookup; optional session activation may duck host audio.
    /// 预热语音查询；可选的会话激活可能暂时压低宿主音频。
    func prepare(language: String? = nil, activateAudioSession: Bool = false) {
        executeOnMain { player in
            _ = player.cachedVoice(for: player.normalizedLanguage(language))

            if activateAudioSession {
                player.activateSessionIfNeeded()
                player.scheduleDeactivation()
            }
        }
    }

    /// Speaks using the selected policy; real-time guidance defaults to `.interrupt`.
    /// 按策略播报；实时人脸提示默认使用 `.interrupt`，确保最新提示替换旧语音。
    /// `rate` uses 0...1; `nil` uses the configured default. `rate` 范围为 0...1，`nil` 使用默认配置。
    func speak(
        _ text: String?,
        language: String? = nil,
        rate: Float? = nil,
        pitch: Float? = nil,
        policy: Policy = .interrupt
    ) {
        guard let rawText = text else { return }
        let trimmedText = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        let textKey = normalizedTextKey(trimmedText)
        guard !textKey.isEmpty else { return }

        executeOnMain { player in
            guard !player.shouldSuppressDuplicate(textKey) else { return }

            switch policy {
            case .dropIfBusy:
                guard player.currentRequest == nil else { return }

            case .interrupt:
                player.pendingRequests.removeAll(keepingCapacity: true)
                player.cancelCurrentUtteranceForReplacement()

            case .enqueue:
                break
            }

            guard let request = player.makeRequest(
                text: trimmedText,
                textKey: textKey,
                language: language,
                rate: rate,
                pitch: pitch
            ) else { return }

            player.recordAcceptedText(textKey)

            if player.currentRequest == nil {
                player.start(request)
            } else {
                player.enqueue(request)
            }
        }
    }

    /// Clears duplicate history. 清除重复文本记录。
    func resetDuplicateHistory() {
        executeOnMain { player in
            player.lastAcceptedTextKey = nil
            player.lastAcceptedTime = 0
        }
    }

    /// Stops current and queued speech. 停止当前及排队语音。
    func stop() {
        executeOnMain { player in
            player.stopAll(deactivateImmediately: true)
        }
    }

    func pause() {
        executeOnMain { player in
            guard player.currentRequest != nil else { return }
            if player.synthesizer.pauseSpeaking(at: .word) {
                player.state = .paused
            }
        }
    }

    func resume() {
        executeOnMain { player in
            guard let request = player.currentRequest else { return }
            guard case .paused = player.state else { return }

            player.activateSessionIfNeeded()
            if player.synthesizer.continueSpeaking() {
                player.state = .speaking(request.text)
            }
        }
    }

    /// Stops playback, releases managed resources, and keeps the singleton reusable.
    /// 停止播放并释放托管资源，单例仍可继续使用。
    func release() {
        executeOnMain { player in
            player.stopAll(deactivateImmediately: true)
            player.voiceCache.removeAll()
            player.unavailableVoiceLanguages.removeAll()
            player.lastAcceptedTextKey = nil
            player.lastAcceptedTime = 0
            player.shouldResumeAfterInterruption = false
            player.onStateChanged = nil
        }
    }

    // MARK: - Request state machine / 请求状态机

    private func makeRequest(
        text: String,
        textKey: String,
        language: String?,
        rate: Float?,
        pitch: Float?
    ) -> SpeechRequest? {
        let utterance = AVSpeechUtterance(string: text)
        let normalizedRate = clamped(rate ?? configuration.defaultRate, lower: 0, upper: 1)
        utterance.rate =
            AVSpeechUtteranceMinimumSpeechRate
            + normalizedRate * (AVSpeechUtteranceMaximumSpeechRate - AVSpeechUtteranceMinimumSpeechRate)
        utterance.pitchMultiplier = clamped(
            pitch ?? configuration.defaultPitch,
            lower: 0.5,
            upper: 2.0
        )
        utterance.preUtteranceDelay = 0
        utterance.postUtteranceDelay = 0.03
        if #available(iOS 14.0, *) {
            // Prevents VoiceOver or other assistive voices from overriding normal TTS.
            // 防止 VoiceOver 等辅助功能音色覆盖普通 TTS 音色。
            utterance.prefersAssistiveTechnologySettings = false
        }
        guard let voice = cachedVoice(for: normalizedLanguage(language)) else { return nil }
        utterance.voice = voice
        return SpeechRequest(text: text, textKey: textKey, utterance: utterance)
    }

    private func start(_ request: SpeechRequest) {
        dispatchPrecondition(condition: .onQueue(.main))
        cancelPendingDeactivation()
        activateSessionIfNeeded()
        currentRequest = request
        state = .speaking(request.text)
        synthesizer.speak(request.utterance)
    }

    private func enqueue(_ request: SpeechRequest) {
        let maximumDepth = max(0, configuration.maximumQueueDepth)
        guard maximumDepth > 0 else {
            os_log("TTS queue disabled; utterance dropped", log: log, type: .info)
            return
        }

        if pendingRequests.count >= maximumDepth {
            pendingRequests.removeFirst()
            os_log("TTS queue full; oldest pending utterance dropped", log: log, type: .info)
        }
        pendingRequests.append(request)
    }

    private func finishCurrentRequest(_ utterance: AVSpeechUtterance) {
        dispatchPrecondition(condition: .onQueue(.main))

        // Ignores callbacks from replaced utterances. 忽略已被替换语音的延迟回调。
        guard let current = currentRequest, current.utterance === utterance else { return }
        currentRequest = nil

        if !pendingRequests.isEmpty {
            let next = pendingRequests.removeFirst()
            start(next)
        } else {
            state = .idle
            scheduleDeactivation()
        }
    }

    private func cancelCurrentUtteranceForReplacement() {
        guard currentRequest != nil else { return }

        // Clears first so late cancellation cannot affect replacement state. 先清空状态，避免延迟取消回调影响新语音。
        currentRequest = nil
        _ = synthesizer.stopSpeaking(at: .immediate)
    }

    private func stopAll(deactivateImmediately: Bool) {
        dispatchPrecondition(condition: .onQueue(.main))
        pendingRequests.removeAll(keepingCapacity: true)
        currentRequest = nil
        shouldResumeAfterInterruption = false
        _ = synthesizer.stopSpeaking(at: .immediate)
        state = .idle

        if deactivateImmediately {
            deactivateSessionNow()
        } else {
            scheduleDeactivation()
        }
    }

    // MARK: - Duplicate suppression / 重复抑制

    private func shouldSuppressDuplicate(_ textKey: String) -> Bool {
        guard textKey == lastAcceptedTextKey else { return false }
        let elapsed = ProcessInfo.processInfo.systemUptime - lastAcceptedTime
        return elapsed < configuration.duplicateSuppressionInterval
    }

    private func recordAcceptedText(_ textKey: String) {
        lastAcceptedTextKey = textKey
        lastAcceptedTime = ProcessInfo.processInfo.systemUptime
    }

    // MARK: - Audio session / 音频会话

    private func activateSessionIfNeeded() {
        dispatchPrecondition(condition: .onQueue(.main))
        cancelPendingDeactivation()

        guard configuration.managesAudioSession, !isSessionActive else { return }

        let session = AVAudioSession.sharedInstance()
        if audioSessionSnapshot == nil {
            audioSessionSnapshot = AudioSessionSnapshot(
                category: session.category,
                mode: session.mode,
                options: session.categoryOptions
            )
        }

        do {
            try session.setCategory(
                configuration.audioSessionCategory,
                mode: configuration.audioSessionMode,
                options: configuration.audioSessionOptions
            )
            try session.setActive(true)
            isSessionActive = true
        } catch {
            os_log(
                "AudioSession activation failed: %{public}@",
                log: log,
                type: .error,
                error.localizedDescription
            )
            restoreAudioSessionConfigurationIfNeeded()
        }
    }

    private func scheduleDeactivation() {
        dispatchPrecondition(condition: .onQueue(.main))
        cancelPendingDeactivation()

        guard configuration.managesAudioSession,
            currentRequest == nil,
            pendingRequests.isEmpty
        else { return }

        let item = DispatchWorkItem { [weak self] in
            self?.deactivateSessionNow()
        }
        pendingDeactivation = item
        DispatchQueue.main.asyncAfter(
            deadline: .now() + configuration.sessionDeactivationDelay,
            execute: item
        )
    }

    private func cancelPendingDeactivation() {
        pendingDeactivation?.cancel()
        pendingDeactivation = nil
    }

    private func deactivateSessionNow() {
        dispatchPrecondition(condition: .onQueue(.main))
        cancelPendingDeactivation()
        guard configuration.managesAudioSession else { return }
        guard isSessionActive || audioSessionSnapshot != nil else { return }

        let session = AVAudioSession.sharedInstance()
        do {
            if isSessionActive {
                try session.setActive(false, options: .notifyOthersOnDeactivation)
                isSessionActive = false
            }
            restoreAudioSessionConfigurationIfNeeded()
        } catch {
            os_log(
                "AudioSession deactivation failed: %{public}@",
                log: log,
                type: .error,
                error.localizedDescription
            )
        }
    }

    private func restoreAudioSessionConfigurationIfNeeded() {
        guard let snapshot = audioSessionSnapshot else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(
                snapshot.category,
                mode: snapshot.mode,
                options: snapshot.options
            )
            audioSessionSnapshot = nil
        } catch {
            os_log(
                "AudioSession configuration restore failed: %{public}@",
                log: log,
                type: .error,
                error.localizedDescription
            )
        }
    }

    // MARK: - Notifications / 系统通知

    private func addObservers() {
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleMediaServicesWereReset),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: nil
        )
        #if canImport(UIKit)
            center.addObserver(
                self,
                selector: #selector(handleDidEnterBackground),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )
        #endif
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
            let rawType = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: rawType)
        else { return }

        let rawOptions = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
        let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)

        executeOnMain { player in
            switch type {
            case .began:
                player.cancelPendingDeactivation()
                player.shouldResumeAfterInterruption =
                    player.currentRequest != nil && player.state != .paused
                player.isSessionActive = false
                if player.currentRequest != nil {
                    player.state = .paused
                }

            case .ended:
                let shouldResume = player.shouldResumeAfterInterruption
                player.shouldResumeAfterInterruption = false

                guard shouldResume, options.contains(.shouldResume),
                    let current = player.currentRequest
                else {
                    if shouldResume {
                        player.stopAll(deactivateImmediately: true)
                    }
                    return
                }

                player.activateSessionIfNeeded()
                _ = player.synthesizer.continueSpeaking()
                player.state = .speaking(current.text)

            @unknown default:
                break
            }
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
            let rawReason = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason),
            reason == .oldDeviceUnavailable
        else { return }

        pause()
    }

    @objc private func handleMediaServicesWereReset() {
        executeOnMain { player in
            player.isSessionActive = false
            player.audioSessionSnapshot = nil
            if let current = player.currentRequest, player.state != .paused {
                player.activateSessionIfNeeded()
                player.state = .speaking(current.text)
            }
        }
    }

    @objc private func handleDidEnterBackground() {
        executeOnMain { player in
            guard player.configuration.stopsOnBackground else { return }
            player.stopAll(deactivateImmediately: true)
        }
    }

    // MARK: - Voice selection / 音色选择

    private func cachedVoice(for language: String) -> AVSpeechSynthesisVoice? {
        if let cached = voiceCache[language] { return cached }
        if unavailableVoiceLanguages.contains(language) { return nil }

        guard let voice = bestVoice(for: language) else {
            unavailableVoiceLanguages.insert(language)
            os_log(
                "No TTS voice available for language %{public}@",
                log: log,
                type: .error,
                language
            )
            return nil
        }

        voiceCache[language] = voice
        os_log(
            "TTS voice selected: %{public}@ (%{public}@), language=%{public}@",
            log: log,
            type: .info,
            voice.name,
            voice.identifier,
            voice.language
        )
        return voice
    }

    private func bestVoice(for language: String) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
            .filter(isReliableStandardVoice)
        let requestedCode =
            Locale(identifier: language).languageCode
            ?? language.split(separator: "-").first.map(String.init)

        var preferredLanguages = [language]
        switch requestedCode {
        case "zh":
            preferredLanguages.append(contentsOf: ["zh-CN", "zh-TW"])
        case "en":
            preferredLanguages.append(contentsOf: ["en-US", "en-GB", "en-AU"])
        default:
            break
        }
        preferredLanguages.append("en-US")

        var checkedLanguages = Set<String>()
        for preferredLanguage in preferredLanguages {
            let normalized = normalizedLanguage(preferredLanguage).lowercased()
            guard checkedLanguages.insert(normalized).inserted else { continue }

            let candidates = voices.filter {
                normalizedLanguage($0.language).lowercased() == normalized
            }
            if let voice = preferredVoice(from: candidates) {
                return voice
            }
        }

        if let requestedCode {
            let sameLanguage = voices.filter {
                Locale(identifier: $0.language).languageCode == requestedCode
            }
            if let voice = preferredVoice(from: sameLanguage) {
                return voice
            }
        }
        return nil
    }

    private func preferredVoice(
        from candidates: [AVSpeechSynthesisVoice]
    ) -> AVSpeechSynthesisVoice? {
        candidates.max { lhs, rhs in
            let lhsRank = reliabilityRank(of: lhs)
            let rhsRank = reliabilityRank(of: rhs)
            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }
            if lhs.quality.rawValue != rhs.quality.rawValue {
                return lhs.quality.rawValue < rhs.quality.rawValue
            }
            return lhs.identifier > rhs.identifier
        }
    }

    private func isReliableStandardVoice(_ voice: AVSpeechSynthesisVoice) -> Bool {
        let identifier = voice.identifier.lowercased()
        if identifier.contains(".eloquence.") {
            return false
        }

        // Excludes voices that vocalize effects or transform normal speech.
        // 排除会播放效果音或改变正常发音的趣味音色。
        let excludedNames: Set<String> = [
            "albert", "bad news", "bahh", "bells", "boing", "bubbles", "cellos",
            "good news", "jester", "organ", "superstar", "trinoids", "whisper",
            "wobble", "zarvox",
        ]
        return !excludedNames.contains(voice.name.lowercased())
    }

    private func reliabilityRank(of voice: AVSpeechSynthesisVoice) -> Int {
        let identifier = voice.identifier.lowercased()
        if identifier.contains(".compact.") || identifier.contains("-compact") {
            return 4
        }
        if identifier.contains("ttsbundle") {
            return 3
        }
        if identifier.contains(".premium.") || identifier.contains("-premium") {
            return 2
        }
        if identifier.contains(".enhanced.") || identifier.contains("-enhanced") {
            return 2
        }
        return 1
    }

    // MARK: - Helpers / 辅助方法

    private func normalizedLanguage(_ language: String?) -> String {
        let candidate =
            language
            ?? configuration.defaultLanguage
            ?? Locale.preferredLanguages.first
            ?? "en-US"
        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "en-US" }
        return Locale.canonicalLanguageIdentifier(from: trimmed)
            .replacingOccurrences(of: "_", with: "-")
    }

    private func normalizedTextKey(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private func sanitized(_ value: Configuration) -> Configuration {
        var result = value
        result.defaultRate = clamped(result.defaultRate, lower: 0, upper: 1)
        result.defaultPitch = clamped(result.defaultPitch, lower: 0.5, upper: 2)
        result.duplicateSuppressionInterval = max(0, result.duplicateSuppressionInterval)
        result.maximumQueueDepth = max(0, result.maximumQueueDepth)
        result.sessionDeactivationDelay = max(0, result.sessionDeactivationDelay)
        return result
    }

    private func clamped(_ value: Float, lower: Float, upper: Float) -> Float {
        min(max(value, lower), upper)
    }

    private func executeOnMain(_ action: @escaping (TTSPlayer) -> Void) {
        if Thread.isMainThread {
            action(self)
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                action(self)
            }
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate / 语音合成回调

extension TTSPlayer: AVSpeechSynthesizerDelegate {

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didStart utterance: AVSpeechUtterance
    ) {
        executeOnMain { player in
            guard let current = player.currentRequest,
                current.utterance === utterance
            else { return }
            player.state = .speaking(current.text)
        }
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        executeOnMain { player in
            player.finishCurrentRequest(utterance)
        }
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        executeOnMain { player in
            player.finishCurrentRequest(utterance)
        }
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didPause utterance: AVSpeechUtterance
    ) {
        executeOnMain { player in
            guard let current = player.currentRequest,
                current.utterance === utterance
            else { return }
            player.state = .paused
        }
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didContinue utterance: AVSpeechUtterance
    ) {
        executeOnMain { player in
            guard let current = player.currentRequest,
                current.utterance === utterance
            else { return }
            player.state = .speaking(current.text)
        }
    }
}
