# PowerShell Start All Services Script
$env:SERVICE_OPERATOR_PUBLIC="GDKU2DY4TTRRSQ6BBFYTDV2GEWREHCIDUM5FFXLIF66PDOO3HYJ2YZIF"
$env:RECEIVING_ADDRESS="GDKU2DY4TTRRSQ6BBFYTDV2GEWREHCIDUM5FFXLIF66PDOO3HYJ2YZIF"
$env:RECEIVING_SECRET="SAGQKX7WQAT7DN4H7Z7EJLOQ77YE5ALF6WD3CCJAQR3F23LQPJG6NIKE"
$env:NETWORK="testnet"
$env:USDC_ASSET="CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA"

Write-Host "Starting Flight Data Service (3001)..." -ForegroundColor Cyan
Start-Process -NoNewWindow -FilePath "powershell.exe" -ArgumentList "-Command cd flight-data; `$env:PORT=3001; npm run dev"

Write-Host "Starting Crypto Data Service (3002)..." -ForegroundColor Cyan
Start-Process -NoNewWindow -FilePath "powershell.exe" -ArgumentList "-Command cd crypto-data; `$env:PORT=3002; npm run dev"

Write-Host "Starting News Data Service (3003)..." -ForegroundColor Cyan
Start-Process -NoNewWindow -FilePath "powershell.exe" -ArgumentList "-Command cd news-data; `$env:PORT=3003; npm run dev"

Write-Host "Starting Product Data Service (3004)..." -ForegroundColor Cyan
Start-Process -NoNewWindow -FilePath "powershell.exe" -ArgumentList "-Command cd product-data; `$env:PORT=3004; npm run dev"

Write-Host "Starting Job Data Service (3005)..." -ForegroundColor Cyan
Start-Process -NoNewWindow -FilePath "powershell.exe" -ArgumentList "-Command cd job-data; `$env:PORT=3005; npm run dev"

Write-Host "All 5 Flare Data Services initiated." -ForegroundColor Green
Write-Host "Health check URLs:"
Write-Host "http://localhost:3001/health"
Write-Host "http://localhost:3002/health"
Write-Host "http://localhost:3003/health"
Write-Host "http://localhost:3004/health"
Write-Host "http://localhost:3005/health"
