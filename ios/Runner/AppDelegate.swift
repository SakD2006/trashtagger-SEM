import Flutter
import UIKit
import GoogleMaps  // ADD THIS

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // ADD THIS LINE - Replace with your actual API key
    GMSServices.provideAPIKey("AIzaSyAqG1kS08XLAAdo69k_ct7OwFT_Bo3CBj4")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}