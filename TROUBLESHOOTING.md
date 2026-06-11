# Troubleshooting

## Switching Between CocoaPods And SPM

CocoaPods and SPM both provide the same frameworks (`SMKit`, `SMBase`). Only one integration method should be active in an app target at a time. Using both can cause duplicate framework or "Multiple commands produce" build errors.

## Switching From CocoaPods To SPM

1. Remove CocoaPods from your project:

   ```bash
   pod deintegrate
   ```

2. Clean derived data:

   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```

3. Remove CocoaPods artifacts if they remain:

   ```bash
   rm -rf Pods/
   rm Podfile.lock
   ```

4. Open the `.xcodeproj` file.

5. Add the SPM package:

   ```text
   https://bitbucket.org/sencyai/smkit_package
   ```

   Use version `1.9.8`.

6. Build your project to verify the integration.

This branch is the complete SPM demo. For CocoaPods project structure, use the [`release/1.9.1`](https://github.com/sency-ai/smkit-ios-demo/tree/release/1.9.1) branch as a reference.

## Switching From SPM Back To CocoaPods

1. In Xcode, remove the SPM package:
   - Select your project in the navigator.
   - Open the **Package Dependencies** tab.
   - Select `smkit_package` and remove it.

2. Clean derived data:

   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```

3. Add the SMKit pod:

   ```ruby
   platform :ios, '16.0'

   source 'https://bitbucket.org/sencyai/ios_sdks_release.git'
   source 'https://github.com/CocoaPods/Specs.git'

   target 'YourApp' do
     use_frameworks!
     pod 'SMKit', '1.9.8'
   end

   post_install do |installer|
     installer.pods_project.targets.each do |target|
       target.build_configurations.each do |config|
         config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
         config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
         config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
       end
     end
   end
   ```

4. Install pods:

   ```bash
   pod install --repo-update
   ```

5. Open the `.xcworkspace` file and build.

## Common Issues

### `SMKit` cannot start because models are not initialized

Make sure `SMKitFlowManager.configure(...)` has succeeded before creating `SMKitFlowManager`.

### 3D session fails to start

Call `configure` with `shouldSupport3D: true`, then start the session with `SMKitSessionSettings(include3D: true)`.

### Duplicate framework build errors

Remove either CocoaPods or SPM from the target. Do not link both `SMKit` integrations at the same time.

---

Having issues? [Contact us](mailto:support@sency.ai) and let us know what the problem is.
