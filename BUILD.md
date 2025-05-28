# Build Mullvad Browser
## Build Dependencies

Mullvad Browser uses [CocoaPods](https://cocoapods.org/) as its dependency manager.


## Steps to build Mullvad Browser

```bash
git clone git@github.com:mullvad/mullvad-browser-ios.git
cd MullvadBrowser
pod repo update
pod install
open MullvadBrowser.xcworkspace
```

## Edit Config.xcconfig

Instead of changing signing/release-related configuration in the main project configuration 
(which mainly edits the `project.pbxproj` file), do it in `Config.xcconfig` instead, which avoids
accidental checkins of sensitive information.

You will at least need to edit the `PRODUCT_BUNDLE_IDENTIFIER[config=Debug]` line to be able to run
the app in a simulator. 

Make sure, you didn't accidentally remove the references to that in `project.pbxproj`!


### Resources

https://mullvad.net/en/press
