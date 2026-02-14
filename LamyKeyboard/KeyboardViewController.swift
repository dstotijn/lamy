import UIKit
import LamyShared

class KeyboardViewController: UIInputViewController {
    private lazy var micButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "mic.fill")
        config.cornerStyle = .capsule
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(micTapped), for: .touchUpInside)
        button.accessibilityLabel = "Start recording"
        return button
    }()

    private lazy var stopButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "stop.fill")
        config.baseBackgroundColor = .systemRed
        config.cornerStyle = .capsule
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)
        button.isHidden = true
        button.accessibilityLabel = "Stop recording"
        return button
    }()

    private lazy var globeButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "globe")
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        button.accessibilityLabel = "Next keyboard"
        return button
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        spinner.accessibilityLabel = "Transcribing"
        return spinner
    }()

    private var currentState = TranscriptionState()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        refreshState()

        DarwinNotificationCenter.shared.observe(
            LamyConstants.DarwinNotification.stateChanged
        ) { [weak self] in
            DispatchQueue.main.async {
                self?.refreshState()
            }
        }

        // Refresh when the host app returns to foreground — Darwin notifications
        // may have been dropped while the extension was suspended.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshState()
    }

    @objc private func appDidBecomeActive() {
        refreshState()
    }

    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [
            globeButton, statusLabel, spinner, micButton, stopButton
        ])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4),
            stack.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    private func refreshState() {
        let defaults = LamyConstants.sharedDefaults
        currentState = TranscriptionState.load(from: defaults)

        // Handle stale recording state
        if currentState.status == .recording && currentState.isStale {
            currentState = TranscriptionState()
            currentState.save(to: defaults)
        }

        // Handle pending transcription
        if currentState.status == .done, let text = currentState.transcription {
            textDocumentProxy.insertText(text)
            currentState = TranscriptionState()
            currentState.save(to: defaults)
            DarwinNotificationCenter.shared.post(
                LamyConstants.DarwinNotification.stateChanged
            )
            UIAccessibility.post(
                notification: .announcement,
                argument: "Transcription inserted"
            )
        }

        updateUI()
    }

    private func updateUI() {
        let isRecording = currentState.status == .recording
        let isBusy = currentState.status == .stopping
            || currentState.status == .uploading

        micButton.isHidden = isRecording || isBusy
        stopButton.isHidden = !isRecording
        spinner.isHidden = !isBusy
        if isBusy { spinner.startAnimating() } else { spinner.stopAnimating() }

        switch currentState.status {
        case .idle: statusLabel.text = nil
        case .recording:
            statusLabel.text = "Recording\u{2026}"
            UIAccessibility.post(notification: .announcement, argument: "Recording")
        case .stopping, .uploading:
            statusLabel.text = "Transcribing\u{2026}"
            UIAccessibility.post(notification: .announcement, argument: "Transcribing")
        case .done: statusLabel.text = nil
        case .error:
            let message = currentState.errorMessage ?? "Error"
            statusLabel.text = message
            UIAccessibility.post(notification: .announcement, argument: message)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.resetToIdle()
            }
        }
    }

    @objc private func micTapped() {
        currentState.status = .recording
        currentState.timestamp = Date()
        currentState.save(to: LamyConstants.sharedDefaults)
        DarwinNotificationCenter.shared.post(
            LamyConstants.DarwinNotification.stateChanged
        )
        updateUI()
        openMainApp()
    }

    @objc private func stopTapped() {
        currentState.status = .stopping
        currentState.timestamp = Date()
        currentState.save(to: LamyConstants.sharedDefaults)
        DarwinNotificationCenter.shared.post(
            LamyConstants.DarwinNotification.stateChanged
        )
        updateUI()
    }

    private func openMainApp() {
        guard let url = URL(string: "\(LamyConstants.urlScheme)://record") else { return }
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let application = next as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                return
            }
            responder = next
        }
    }

    private func resetToIdle() {
        currentState = TranscriptionState()
        currentState.save(to: LamyConstants.sharedDefaults)
        updateUI()
    }
}
