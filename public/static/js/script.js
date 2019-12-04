function updateData() {
  $.get("/market", function(data) {
    var marketData = data.data.map(function(row) {
      return { symbol: row[0], bid: row[1], ask: row[2] };
    });
    $("#tableMarket").bootstrapTable("load", marketData);
    var orderData = data.orders.map(function(row) {
      return {
        id: row[0],
        time: row[1],
        type: row[2],
        size: row[3],
        symbol: row[4],
        sellprice: row[5],
        stoploss: row[6],
        takeprofit: row[7],
        buyprice: row[8],
        commission: row[9],
        taxes: row[10],
        swap: row[11],
        profit: row[12],
        comment: row[13]
      };
    });
    $("#tableOrder").bootstrapTable("load", orderData);
    // console.log(data);

    setTimeout(updateData, 2000);
  });
}

$(function() {
  updateData();
});
