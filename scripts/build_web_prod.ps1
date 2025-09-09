param(
    [string]$BaseUrl = "https://dompet-backend.onrender.com",
    [string]$Flavor = "prod"
)

Write-Host "Building Flutter Web (release) with BASE_URL=$BaseUrl FLAVOR=$Flavor" -ForegroundColor Cyan
flutter clean
flutter pub get
flutter build web --release --dart-define=BASE_URL=$BaseUrl --dart-define=FLAVOR=$Flavor

Write-Host "Build finished. Artifacts in build/web" -ForegroundColor Green
