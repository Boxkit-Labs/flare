#!/bin/bash
cd flight-data && npm run dev &
cd ../crypto-data && npm run dev &
cd ../news-data && npm run dev &
cd ../product-data && npm run dev &
cd ../job-data && npm run dev &
echo "All 5 data services started"
