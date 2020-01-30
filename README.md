## Start 

```bash
node server.js --device-trade=emulator-5554 --device-history=emulator-5564
node test_extract.js --device=emulator-5554 --image=public/test.png
```


#### ngrok
`ngrok http -bind-tls=false -subdomain=mt4 80`
`ngrok tcp --region=ap  --remote-addr=1.tcp.ap.ngrok.io:20077 3389`