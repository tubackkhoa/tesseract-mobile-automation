const https = require('https');

class MyRegExp extends RegExp {
    // implement matchAll
    [Symbol.matchAll](str) {
        let result = RegExp.prototype[Symbol.matchAll].call(this, str);
        if (!result) {
            return null;
        }
        return Array.from(result);
    }
}


const tradeHeaders = ["orderID", "time", "type", "volume", "symbol", "price", "sl", "tp"];
const floatGroup = `([0-9]+\\.[0-9]+)`;
const symbolGroup = `(\\w+(?:\\.\\w+)?)`;
const reTrade = new MyRegExp(`(\\d+)\\s+([\\d\\.]+\\s*[\\d\\:]+)\\s+((?:sell|buy)(?:\\s+(?:limit|stop))?)\\s+${floatGroup}\\s+${symbolGroup}\\s+${floatGroup}(?:\\s+${floatGroup}\\s+${floatGroup})?`, 'g');
// Order #2169022 buy 1.00 EURUSD at 1.10984 sl: 0.00000 tp: 0.000000
const tradeHeadersData = ["orderID", "type", "volume", "symbol", "price", "sl", "tp"];
const reTradeData = new MyRegExp(`Order\\s+#(\\d+)\\s+((?:sell|buy)(?:\\s+(?:limit|stop))?)\\s+${floatGroup}\\s+${symbolGroup}\\s+at\\s+${floatGroup}\\s+sl:\\s+${floatGroup}\\s+tp:\\s+${floatGroup}`, 'g');

const toObject = (names, match) => {
    const values = match.slice(1, names.length + 1)
    const result = {};
    for (var i = 0; i < names.length; i++)
         result[names[i]] = values[i] || "";
    result.type = result.type.replace(/(?=\b)\w/g, c => c.toUpperCase())
    return result;
};


const extractTradeData = rawData => {
    const matches = rawData.replace(/[_-]/g,'').matchAll(reTrade);
    return matches.map(match=> toObject(tradeHeaders, match));
};

const extractTradeData2 = rawData => {
    const matches = rawData.replace(/[_-]/g,'').matchAll(reTradeData);
    return matches.map(match=> toObject(tradeHeadersData, match));
};

const modifyVolume = (tradeData, percentage = 1, minimum = 0.005) => {
    return tradeData.map(item=>({
      ...item,
      volume : Math.max(minimum, item.volume * percentage).toFixed(4).toString()
    }))
  };


class Telegram {

    constructor(token){
        this.endpoint = `https://api.telegram.org/bot${token}/sendMessage?chat_id=%chatId&text=%message`;
    }

    send (recipient, message, callback) {
        let endpointUrl = this.endpoint
            .replace('%chatId', recipient)
            .replace('%message', message);

        https.get(endpointUrl, (res) => {
            res.on("data", function(chunk) {
                // console.log("BODY: " + chunk);
                callback && callback(chunk);
            });
        });
    }
}

module.exports = {extractTradeData, extractTradeData2, modifyVolume, Telegram}