$ErrorActionPreference = "Stop"

Write-Host "Building admin role..."
flutter build web -t lib/main_admin.dart --base-href /
if (-not (Test-Path "build\web_admin")) { New-Item -ItemType Directory -Path "build\web_admin" | Out-Null }
# Use Copy-Item with robust options or xcopy for reliability on Windows
# Copy-Item build\web\* to build\web_admin -Recurse -Force
xcopy "build\web\*" "build\web_admin\" /E /H /C /I /Y

Write-Host "Building interviewer role..."
flutter build web -t lib/main_interviewer.dart --base-href /
if (-not (Test-Path "build\web_interviewer")) { New-Item -ItemType Directory -Path "build\web_interviewer" | Out-Null }
xcopy "build\web\*" "build\web_interviewer\" /E /H /C /I /Y

Write-Host "Building interviewee role..."
flutter build web -t lib/main_interviewee.dart --base-href /
if (-not (Test-Path "build\web_interviewee")) { New-Item -ItemType Directory -Path "build\web_interviewee" | Out-Null }
xcopy "build\web\*" "build\web_interviewee\" /E /H /C /I /Y

Write-Host "Deploying to Firebase..."
firebase deploy

Write-Host "Deployment complete."
