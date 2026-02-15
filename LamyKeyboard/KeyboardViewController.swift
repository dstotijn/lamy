import UIKit
import LamyShared

class KeyboardViewController: UIInputViewController {
    private lazy var micButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(
            systemName: "mic.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 20)
        )
        config.cornerStyle = .capsule
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(micTapped), for: .touchUpInside)
        button.accessibilityLabel = "Start recording"
        return button
    }()

    private lazy var stopButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(
            systemName: "stop.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 20)
        )
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
        config.baseForegroundColor = .tertiaryLabel
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        button.accessibilityLabel = "Next keyboard"
        return button
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
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
        // Globe pinned to leading edge
        globeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(globeButton)

        // Everything centered as a group — hidden views collapse automatically
        statusLabel.isHidden = true
        let centerStack = UIStackView(arrangedSubviews: [
            statusLabel, spinner, micButton, stopButton
        ])
        centerStack.axis = .vertical
        centerStack.alignment = .center
        centerStack.spacing = 4
        centerStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(centerStack)

        let buttonSize: CGFloat = 48
        let topPadding: CGFloat = 16
        let bottomPadding: CGFloat = 8
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(greaterThanOrEqualToConstant: 72),

            globeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            globeButton.centerYAnchor.constraint(equalTo: centerStack.centerYAnchor),

            centerStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerStack.topAnchor.constraint(equalTo: view.topAnchor, constant: topPadding),
            centerStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -bottomPadding),

            micButton.widthAnchor.constraint(equalToConstant: buttonSize),
            micButton.heightAnchor.constraint(equalToConstant: buttonSize),
            stopButton.widthAnchor.constraint(equalToConstant: buttonSize),
            stopButton.heightAnchor.constraint(equalToConstant: buttonSize)
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
        case .idle:
            statusLabel.text = nil
            statusLabel.isHidden = true
        case .recording:
            statusLabel.text = nil
            statusLabel.isHidden = true
            UIAccessibility.post(notification: .announcement, argument: "Recording")
        case .stopping, .uploading:
            statusLabel.text = "Transcribing\u{2026}"
            statusLabel.isHidden = false
            UIAccessibility.post(notification: .announcement, argument: "Transcribing")
        case .done:
            statusLabel.text = nil
            statusLabel.isHidden = true
        case .error:
            let message = currentState.errorMessage ?? "Error"
            statusLabel.text = message
            statusLabel.isHidden = false
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

        guard let cls = NSClassFromString("UIApplication") as? NSObject.Type,
              let app = cls.perform(NSSelectorFromString("sharedApplication"))?
                  .takeUnretainedValue() as AnyObject? else { return }

        let selector = NSSelectorFromString("openURL:options:completionHandler:")
        guard app.responds(to: selector) else { return }

        typealias OpenURLFunc = @convention(c) (
            AnyObject, Selector, URL, NSDictionary, ((Bool) -> Void)?
        ) -> Void
        let imp = app.method(for: selector)
        let open = unsafeBitCast(imp, to: OpenURLFunc.self)
        open(app, selector, url, [:] as NSDictionary, nil)
    }

    private func resetToIdle() {
        currentState = TranscriptionState()
        currentState.save(to: LamyConstants.sharedDefaults)
        updateUI()
    }
}
