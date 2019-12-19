
const {extractTradeData,modifyVolume} = require('./utils')


const trade = `Balance: 99 865.07 Credit: 0.00 Equity: 99 865.07 Free margin: 99 865.07
2169037 2019.12.19 04:00 _ sell stop 0.01 EURUSD 1.11240 1.11340 1.11140`

const history = `2169022 2019.12.19 08:39 buy 0.01 EURUSD 1.11266 2019.12.19 (
    2169020 2019.12.19 08:38 sell 0.01 EURUSD 1.11241 2019.12.19 (
    2168944 2019.12.19 02:54 sell 0.01 EURUSD 1.11274 2019.12.19 (
    2168933 2019.12.19 02:49 buy 0.01 EURUSD 1.11308 2019.12.19 (
    2168929 2019.12.19 02:48 buy 0.01 EURUSD 1.11319 2019.12.19 (
    2168926 2019.12.19 02:47 sell 0.01 EURUSD 1.11295 2019.12.19 (`

let data = extractTradeData(trade);
data = modifyVolume(data, 0.1);
console.log(data)