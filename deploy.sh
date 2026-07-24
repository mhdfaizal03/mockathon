#!/bin/bash
set -e

echo "Cleaning Flutter project..."
flutter clean
flutter pub get

echo "Building admin role..."
flutter build web -t lib/main_admin.dart --base-href / --no-tree-shake-icons
rm -rf build/web_admin
cp -R build/web build/web_admin

echo "Building interviewer role..."
flutter build web -t lib/main_interviewer.dart --base-href / --no-tree-shake-icons
rm -rf build/web_interviewer
cp -R build/web build/web_interviewer

echo "Building interviewee role..."
flutter build web -t lib/main_interviewee.dart --base-href / --no-tree-shake-icons
rm -rf build/web_interviewee
cp -R build/web build/web_interviewee

echo "Deploying to Firebase..."
/opt/homebrew/bin/firebase deploy

echo "Deployment complete."
