
const {extractTradeData2,extractTradeData,modifyVolume} = require('./utils')


const trade = `I 2170267 2019.12.20 05:47 buy 1.00 EURUSD 1.11166 1.11102 1.11212
I 2170269 2019.12.20 05:49 sell 1.00 EURUSD 1.11133 1.11191 111117
Balance: 99 372.97 Credit: 0.00 Equity: 99 320.97 Free margin: 99 320.97`

const history = `2171552 2019.12.23 05-48 sell 0.10 USDCHF 0.98058
2171550 2019.12.23 05-48 sell 0.10 USDCHF 0.98058
2171542 2019.12.23 05-46 buy 0.10 USDCHF 0.98088
2171541 2019.12.23 05-46 buy 0.10 USDCHF 0.98088
2171540 2019.12.23 05-46 buy 0.10 USDCHF 0.98088
2171539 2019.12.23 05-46 buy 0.10 EURAUD 1.60164`


const tradeData = `Order #97201148 buy 0.01 USDCHF.lmx at 0.97278 sl: 0.00000 tp: 0.00000
Order #97201149 buy 0.01 USDCHF.lmx at 0.97277 sl: 0.00000 tp: 0.00000
Order #97201150 buy 0.01 USDCHF.lmx at 0.97270 sl: 0.00000 tp: 0.00000
Order #97201151 buy 0.01 USDCHF.lmx at 0.97270 sl: 0.00000 tp: 0.00000
Order #97201152 buy 0.01 USDCHF.lmx at 0.97272 sl: 0.00000 tp: 0.00000
Order #97201153 buy 0.01 USDCHF.lmx at 0.97272 sl: 0.00000 tp: 0.00000
Order #97201154 sell 0.01 USDCHF.lmx at 0.97263 sl: 0.00000 tp: 0.00000
Order #97201155 sell 0.01 USDCHF.lmx at 0.97263 sl: 0.00000 tp: 0.00000
Order #97201156 sell 0.01 GBPJPY.lmx at 143.201 sl: 0.000 tp: 0.000
Order #97201157 sell 0.01 USDCHF.lmx at 0.97268 sl: 0.00000 tp: 0.00000`

let data = extractTradeData2(tradeData);
console.log(data);