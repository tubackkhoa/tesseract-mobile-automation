
const {extractTradeData2,modifyVolume} = require('./utils')


const trade = `I 2170267 2019.12.20 05:47 buy 1.00 EURUSD 1.11166 1.11102 1.11212
I 2170269 2019.12.20 05:49 sell 1.00 EURUSD 1.11133 1.11191 111117
Balance: 99 372.97 Credit: 0.00 Equity: 99 320.97 Free margin: 99 320.97`

const history = `2169022 2019.12.19 08:39 buy 0.01 EURUSD 1.11266 2019.12.19 (
    2169020 2019.12.19 08:38 sell 0.01 EURUSD 1.11241 2019.12.19 (
    2168944 2019.12.19 02:54 sell 0.01 EURUSD 1.11274 2019.12.19 (
    2168933 2019.12.19 02:49 buy 0.01 EURUSD 1.11308 2019.12.19 (
    2168929 2019.12.19 02:48 buy 0.01 EURUSD 1.11319 2019.12.19 (
    2168926 2019.12.19 02:47 sell 0.01 EURUSD 1.11295 2019.12.19 (`


const tradeData = `Order #2169022 buy 1.00 EURUSD at 1.10984 sl: 0.00000 tp: 0.000000
Order #2169022 buy limit 1.00 EURUSD at 1.10984 sl: 0.00000 tp: 0.000000
Order #2169022 sell 1.00 EURUSD at 1.10984 sl: 0.00000 tp: 0.000000
Order #2169022 sell stop 1.00 EURUSD at 1.10984 sl: 1.12000 tp: 0.000000
`

let data = extractTradeData2(tradeData);
data = modifyVolume(data, 0.1);
console.log([...data,...[{key:12}]]);