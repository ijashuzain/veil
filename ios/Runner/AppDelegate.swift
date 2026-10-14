import Flutter
import UIKit
import AVKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var playerChannel: FlutterMethodChannel?
  private var originalBrightness: CGFloat?
  private var fullscreenController: VeilSystemPlayer?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "VeilPlayer") else { return }
    let channel = FlutterMethodChannel(name: "veil/player", binaryMessenger: registrar.messenger())
    playerChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "getBrightness": result(Double(UIScreen.main.brightness))
      case "setBrightness":
        guard let value = call.arguments as? Double else { result(FlutterError(code: "arguments", message: "Missing brightness", details: nil)); return }
        if self.originalBrightness == nil { self.originalBrightness = UIScreen.main.brightness }
        UIScreen.main.brightness = CGFloat(min(1, max(0.02, value)))
        result(nil)
      case "restoreBrightness":
        if let value = self.originalBrightness { UIScreen.main.brightness = value; self.originalBrightness = nil }
        result(nil)
      case "fullscreen":
        guard self.fullscreenController == nil,
              let args = call.arguments as? [String: Any],
              let source = args["url"] as? String, let url = URL(string: source), url.scheme == "https",
              let root = registrar.viewController ?? self.window?.rootViewController else {
          result(FlutterError(code: "unavailable", message: "Cannot present native player", details: nil)); return
        }
        let headers = args["headers"] as? [String: String] ?? [:]
        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        player.volume = Float(args["volume"] as? Double ?? 1)
        let controller = VeilSystemPlayer()
        controller.player = player
        controller.modalPresentationStyle = .fullScreen
        controller.onFinish = { [weak self] position, playing in
          self?.fullscreenController = nil
          result(["position": position, "playing": playing])
        }
        self.fullscreenController = controller
        var presenter = root
        while let presented = presenter.presentedViewController { presenter = presented }
        presenter.present(controller, animated: true) {
          let time = CMTime(seconds: ((args["position"] as? NSNumber)?.doubleValue ?? 0) / 1000, preferredTimescale: 600)
          player.seek(to: time, toleranceBefore: CMTime(seconds: 0.25, preferredTimescale: 600), toleranceAfter: CMTime(seconds: 0.25, preferredTimescale: 600)) { completed in
            if completed && (args["playing"] as? Bool ?? false) { player.play() }
          }
        }
      default: result(FlutterMethodNotImplemented)
      }
    }
  }
}

private class VeilSystemPlayer: AVPlayerViewController {
  var onFinish: ((Int64, Bool) -> Void)?
  private var finished = false
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    guard isBeingDismissed || navigationController?.isBeingDismissed == true else { return }
    finish()
  }
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if presentingViewController == nil { finish() }
  }
  private func finish() {
    guard !finished else { return }
    finished = true
    let seconds = player?.currentTime().seconds ?? 0
    let playing = (player?.rate ?? 0) > 0
    player?.pause()
    onFinish?(seconds.isFinite ? Int64(seconds * 1000) : 0, playing)
    onFinish = nil
    player?.replaceCurrentItem(with: nil)
  }
}
