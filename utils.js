
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
const reTrade = new MyRegExp(`(\\d+)\\s+([\\d\\.]+\\s*[\\d\\:]+)\\s+((?:sell|buy)(?:\\s+(?:limit|stop))?)\\s+${floatGroup}\\s+([A-Z]+)\\s+${floatGroup}(?:\\s+${floatGroup}\\s+${floatGroup})?`, 'g');

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

const modifyVolume = (tradeData, percentage = 1) => {
    return tradeData.map(item=>({
      ...item,
      volume : (item.volume * percentage).toString()
    }))
  };




module.exports = {extractTradeData,modifyVolume}