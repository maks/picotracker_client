#!/bin/sh

# based on https://odilondamasceno.medium.com/creating-appimage-with-flutter-d19ef8b53158

flutter build linux --release

cp -r build/linux/x64/release/bundle/ picoTrackerClient.AppDir
cp appimage/picotracker_client.png  picoTrackerClient.AppDir/
cp appimage/AppRun picoTrackerClient.AppDir/
cp appimage/PicotrackerClient.desktop picoTrackerClient.AppDir/PicotrackerClient.desktop
chmod +x  picoTrackerClient.AppDir/AppRun 

# appimagetool-x86_64.AppImage needs to be in path already 
appimagetool-x86_64.AppImage picoTrackerClient.AppDir