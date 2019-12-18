
const {extractTradeData,modifyVolume} = require('./utils')


const trade = `2167764 2019.12.18 01:35 sell limit 0.01 EURUSD 1.11357
2167740 2019.12.18 01:35 sell 0.01 EURUSD 1.11357
2167764 2019.12.18 01:35 buy limit 0.01 EURUSD 1.11357
2167764 2019.12.18 01:35 sell limit 0.01 EURUSD 1.11357
Balance: 99 867.52 Credit: 0.00 Equity: 99 867.42 Margin: 4.45 Free margin: 99 862.97`

const history = `2167737 2019.12.17 22:57 _ sell limit 0.01 EURUSD 1.11356
2167730 2019.12.17 22:02 - buy limit 0.01 EURUSD 1.11320
2166680 2019.12.17 04:31 sell 0.01 EURUSD 1.11393
2166550 2019.12.17 03:13 buy 0.01 EURUSD 1.11400
2157362 2019.12.11 14:15 sell 0.11 EURUSD 1.11089
2157322 2019.12.11 14:15 sell 0.01 EURUSD 1.11113
2157320 2019.12.11 14:15 sell 0.01 EURUSD 1.11112
Profit: -34.94 Credit: 0.00 Deposit: 0.00 Withdrawal: 0.00`

let data = extractTradeData(history);
data = modifyVolume(data, 0.1);
console.log(data)