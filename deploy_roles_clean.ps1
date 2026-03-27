$ErrorActionPreference = "Stop"

Write-Host "Cleaning Flutter project to ensure a fresh build..."
flutter clean
flutter pub get

Write-Host "Building admin role..."
flutter build web -t lib/main_admin.dart --base-href /
if (Test-Path "build\web_admin") { Remove-Item -Recurse -Force "build\web_admin" }
Move-Item -Path "build\web" -Destination "build\web_admin"

Write-Host "Building interviewer role..."
flutter build web -t lib/main_interviewer.dart --base-href /
if (Test-Path "build\web_interviewer") { Remove-Item -Recurse -Force "build\web_interviewer" }
Move-Item -Path "build\web" -Destination "build\web_interviewer"

Write-Host "Building interviewee role..."
flutter build web -t lib/main_interviewee.dart --base-href /
if (Test-Path "build\web_interviewee") { Remove-Item -Recurse -Force "build\web_interviewee" }
Move-Item -Path "build\web" -Destination "build\web_interviewee"

Write-Host "Deploying to Firebase..."
firebase deploy

Write-Host "Deployment complete."
