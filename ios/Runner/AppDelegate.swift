import Flutter
import UIKit
import UserNotifications
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Required so local notifications are delivered/forwarded with UIScene + implicit engine.
    // See: https://github.com/MaikuB/flutter_local_notifications/blob/master/flutter_local_notifications/example/ios/Runner/AppDelegate.swift
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // Headless/background action isolate: register the same way as the main engine.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // SOS dial pad: open tel: via UIApplication.shared.open so we don't rely on
    // url_launcher's canOpenURL gate (often fails on iOS even when dialling works).
    let sosPhoneChannel = FlutterMethodChannel(
      name: "flutter_application_1/sos_phone",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    sosPhoneChannel.setMethodCallHandler { call, result in
      guard call.method == "openTel" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any],
            let raw = args["number"] as? String else {
        result(
          FlutterError(code: "bad_args", message: "Missing number", details: nil)
        )
        return
      }
      let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
      guard let url = URL(string: "tel:\(cleaned)") else {
        result(false)
        return
      }
      DispatchQueue.main.async {
        UIApplication.shared.open(url, options: [:]) { success in
          result(success)
        }
      }
    }
  }
}
