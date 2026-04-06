# PowerShell Start All Services Script
$env:SERVICE_OPERATOR_PUBLIC="GDKU2DY4TTRRSQ6BBFYTDV2GEWREHCIDUM5FFXLIF66PDOO3HYJ2YZIF"
$env:RECEIVING_ADDRESS="GDKU2DY4TTRRSQ6BBFYTDV2GEWREHCIDUM5FFXLIF66PDOO3HYJ2YZIF"
$env:RECEIVING_SECRET="SAGQKX7WQAT7DN4H7Z7EJLOQ77YE5ALF6WD3CCJAQR3F23LQPJG6NIKE"
$env:NETWORK="testnet"
$env:USDC_ASSET="CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA"

Write-Host "Starting Flare Combined Services (Port 3001)..." -ForegroundColor Cyan
Start-Process -NoNewWindow -FilePath "powershell.exe" -ArgumentList "-Command cd combined; `$env:PORT=3001; npm run dev"

Write-Host "Flare Consolidated Services initiated on Port 3001." -ForegroundColor Green
Write-Host "Includes: Flights, Crypto, News, Product, Job, Stocks, Real Estate, Sports"
Write-Host "Health Check: http://localhost:3001/health"
