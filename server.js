const argv = require("yargs").argv;
const level = require('level');

// 250: emulator-5564:history.png, 300, emulator-5554, trade.png
const platform = process.platform;
let env;
if (platform === "win32") {
  env = {
    TESSERACT: "E:/MT4/tesseract/tesseract.exe",
    TESSDATA_PREFIX: "E:/MT4/tesseract/tessdata",
    ADB: "E:/MT4/platform-tools/adb.exe"
  };
} else {
  env = {
    TESSERACT: "/usr/local/bin/tesseract",
    TESSDATA_PREFIX: "/tmp/tessdata",
    ADB: "/Users/thanhtu/Library/Android/sdk/platform-tools/adb"
  };
}


const db = level('mt4')
const express = require("express");
const { execSync, fork, spawn } = require("child_process");
const fs = require("fs");
const app = express();
const expressWs = require("express-ws")(app);
const bodyParser = require("body-parser");
const path = require('path');
const {extractTradeData, extractTradeData2, modifyVolume, Telegram} = require('./utils');

const telegram = new Telegram(argv.telegramToken || '1069055490:AAF6X4Cq-QQrNvIRTn400qjEwFpWFCY7gok');
const TELEGRAM_GROUPID = argv.chatId || '-308224929';

app.use(bodyParser.json()); // support json encoded bodies
app.use(bodyParser.urlencoded({ extended: true })); // support encoded bodies

let stop = false;
let data = { trade: [], history: [], init: [] };
let log = {};
let state = {copy:true, start: false,multiply:0.1,marginLimit:0.015};
let accounts = {data:[],
  // pubSelected:'',
subSelected:''};
let DEBUG = argv.verbose || false;
let MAX_ORDER = argv.maxOrder || 20;
let delay = argv.delay || 100;
let autoit;

const accountsExePath = path.join(__dirname, 'account_list');
const updateAccounts = () => {
  accounts.data = execSync(accountsExePath).toString().replace(/;$/,"").split(/\s*;\s*/);
  // if(!accounts.pubSelected) accounts.pubSelected = accounts.data[0];
  if(!accounts.subSelected) accounts.subSelected = accounts.data[0];
  setTimeout(updateAccounts, 1000);
}

const stopAutoIT=()=>{
  if(autoit){
    autoit.kill();
    autoit = null;
  }
}

const aWss = expressWs.getWss("/");

const filterDataFromType = (type) => {
  let filterData = data[type];
    // for(let item of data[type]) {
    //   const copyOrderID = await getCopyOrderID(type, item.orderID);
    //   // console.log(type, item.orderID,copyOrderID);
    //   // not processed
    //   if(!copyOrderID) filterData.push(item);
    // }
  
  if(type === 'history'){
    // with history, it means that we need to close the order, 
    // and we only close copy order that is mapped to this order, otherwise it is meaningless
    // filterData = await filterCopyTrade(filterData);
  } else {
    filterData = modifyVolume(filterData, state.multiply);
  }

    // res.send(filterData);
    return filterData;
};

const sendDataToAll =  (type) => {
  const filterData =  filterDataFromType(type);
  const message = JSON.stringify({ data: filterData, type: type });
  aWss.clients.forEach(ws => ws.send(message));
};

const sendData =  (ws, type) => {
  const filterData =  filterDataFromType(type);
  ws.send(JSON.stringify({ data: filterData, type: type }));
};

const sendLog = (ws) => {
  ws.send(JSON.stringify({ data: log, type: 'log' }));
};

const sendLogToAll = () => {
  const message = JSON.stringify({ data: log, type: 'log' })
  aWss.clients.forEach(ws => ws.send(message));
};


const sendStateToAll = () => {
  const message = JSON.stringify({ data: {state,accounts}, type: 'state' })
  aWss.clients.forEach(ws => ws.send(message));
};

const sendTelegram = (tradeItem, type) => {
  // console.log(tradeItem, type);
  if(tradeItem){
    //["orderID", "time", "type", "volume", "symbol", "price", "sl", "tp"]
    let message = accounts.subSelected + ", ";
    if(tradeItem.marginPrice){
      message += `Ignore because differ by ${tradeItem.marginPrice}`;
    } else if(!tradeItem.copyOrderID){
      if(tradeItem.countLimit){
        message += `Ignore because exceed max number of trades: ${tradeItem.countLimit}`;
      } else if(tradeItem.retries) {
        message += `Ignore after retries: ${tradeItem.retries}`;
      } else {
        message += `Ignore because price is too close to market price ${tradeItem.price}`;
      }
      
    } else {
      message += type === 'trade' ? `${state.copy ? 'Copy' : 'Reverse'} [${tradeItem.type}]` : 'Close';
    }
    message += ` ${tradeItem.orderID} ,Price: ${tradeItem.price}`;
    if(type == 'trade' && tradeItem.copyOrderID){
      message += `, Volume: ${Math.round(tradeItem.volume * state.multiply)} ,S/L: ${tradeItem.sl} ,T/P:${tradeItem.tp}`;
    }
    // update log
    telegram.send(TELEGRAM_GROUPID, message, ret=>{
      log = {type: 'info', message:ret};
      sendLogToAll();
    });
  }
};

const tradeExePath = path.join(__dirname, 'trade');
const startAutoIT=()=>{
  stopAutoIT();

  const ACTION = state.copy ? "copy" : "reverse";
  // const PUBLISH_ACCOUNT_ID = accounts.pubSelected;
  const SUBSCRIBE_ACCOUNT_ID = accounts.subSelected;
  const MARGIN_LIMIT = state.marginLimit;

  // console.log(PUBLISH_ACCOUNT_ID, SUBSCRIBE_ACCOUNT_ID);

  // if(PUBLISH_ACCOUNT_ID === SUBSCRIBE_ACCOUNT_ID) return ;

  // spawn can use current directory
  autoit = spawn(tradeExePath, [], {env:{ACTION, 
    // PUBLISH_ACCOUNT_ID,
    MAX_ORDER,
    SUBSCRIBE_ACCOUNT_ID,MARGIN_LIMIT}});
  autoit.stdout.on('data', (data) => {
    const message = data.toString();
    log = {type: 'info', message};
    sendLogToAll();
    // console.log(`stdout: ${message}`);
  });
  
  autoit.stderr.on('data', (data) => {
    message = data.toString();
    log =  {type: 'danger', message};
    sendLogToAll();
    // console.error(`stderr: ${message}`);
  });
  
  autoit.on('close', (code) => {
    message = `child process exited with code ${code}, on ${accounts.SUBSCRIBE_ACCOUNT_ID}`;
    log = {type:'warning', message};
    sendLogToAll();
    console.log(message);   
  });
};

// fork another process
const childProcessTrade = fork("./extract_text.js", {
  env: {
    ...env,
    PADDING_BOTTOM: 0,
    DEVICE_WIDTH: 1600,
    DEVICE_HEIGHT: 900
  }
});

const childProcessHistory = fork("./extract_text.js", {
  env: {
    ...env,
    PADDING_BOTTOM: 0,
    DEVICE_WIDTH: 1600,
    DEVICE_HEIGHT: 900
  }
});

const sendTradeMessage = () => {
  childProcessTrade.send({
    device: argv.deviceTrade,
    image: "public/trade.png",
    top:  210,
    right:  450
  });
};

const sendHistoryMessage = () => {
  childProcessHistory.send({
    device: argv.deviceHistory,
    image: "public/history.png",
    top:  210,
    right:  550  // no need to extract stop loss and take profit 
  });
};

// listen for messages from forked childProcess
childProcessTrade.on("message", async message => {
  await update(message.rawData, "trade");
  setTimeout(sendTradeMessage, delay);
});

// listen for messages from forked childProcess
childProcessHistory.on("message", async message => {
  await update(message.rawData, "history");
  setTimeout(sendHistoryMessage, delay);
});


// const filterCopyTrade = async tradeData => {
//   const filterData = [];
//   for(let item of tradeData) {
//     const copyOrderID = await getCopyOrderID('trade', item.orderID);
//     // has entered 
//     if(copyOrderID) filterData.push({...item,copyOrderID});
//   }
//   return filterData;
// }

const updateCopyOrderID = async(trades, type) => {
  const newTrade = [];
  for(let item of trades) {
    if(!item.copyOrderID){
      item.copyOrderID = await getCopyOrderID(type, item.orderID);
      if(item.copyOrderID){
        // if(type == "trade"){
        //   item.status = "processed";
        // } else {
        //   // ignore
        //   continue;
        // }
        continue;
      } else if (type == "history") {
        item.copyOrderID = await getCopyOrderID("trade", item.orderID);
      }
      
    }

    newTrade.push(item);

  }

  return newTrade;
};

// trigger update
const update = async (rawData, type) => {
  if (!stop) {
    // const start = Date.now();
    try {
      
      const trades = extractTradeData(rawData);

      if(type == "history"){        
        // trade: remain items which not found in history
        data.trade = data.trade.filter(c => trades.findIndex(item => item.orderID == c.orderID) == -1);
      }
      
      // console.log(trades);
      // come to history => remove from trade, append to history 
      // come to trade => append new one, but limit 20      
      let newTrades = [...data[type], ...trades.filter(c => data[type].findIndex(item => item.orderID == c.orderID) == -1)];
    
      // update first
      newTrades = await updateCopyOrderID(newTrades, type);
      // if(newTrades.length != 0) 
      if(type == "trade"){
        newTrades = newTrades.slice(0, MAX_ORDER);
      } else {
        // remove history that do not have copyOrderID or copyOrderIndex
        const newHistory = [];
        for(let item of newTrades){
          if(item.copyOrderID){
            const copyOrderIndex = data.init.findIndex(initItem => initItem.orderID == item.copyOrderID);
            // can close
            if(copyOrderIndex != -1){
              newHistory.push(item);
            }
          }
        }

        // only show history that we can delete this time
        newTrades = newHistory;
      }

      data[type] = newTrades;
      

      if (DEBUG) {
        // const elapsed = Date.now() - start;
        console.log(type, data[type]);
      }
      sendDataToAll('trade');
      sendDataToAll('history');
    } catch (ex) {
      console.log("Error processing");
    }
  }
};



const getCopyOrderID = async (type, orderID)=>{
  let value;
  try{
   value = await db.get(`${type}.${orderID}`);
  } catch(ex){
    value = "";
  }
  return value;
}

app.use(express.static("public"));

app.get("/accounts", (req,res)=>{
   res.send(accounts);
});

app.post("/accounts", (req,res)=>{
  // restart with new account
  const {
    // pubSelected, 
    subSelected} = req.body;
  // if(accounts.pubSelected !== pubSelected || accounts.subSelected !== subSelected){
    // accounts.pubSelected = pubSelected;
    accounts.subSelected = subSelected;
    // if(state.start) {
    //   startAutoIT();
    // }
  // }
  res.send(accounts);
});

app.get("/state", (req,res)=>{
  res.send(state);
});

app.post("/state", (req,res)=>{
  const {copy,start,multiply,marginLimit} = req.body;
  // console.log(copy, start);
  state.copy = copy;
  state.multiply = parseFloat(multiply);
  state.marginLimit = parseFloat(marginLimit);
  if(start !== state.start){
    state.start = start;
    // change status
    if(start) {
      startAutoIT();
    } else {
      stopAutoIT();
    }

    sendStateToAll();
  }

  
  
  res.send(state);
});

app.post("/upload", function(req, res, next) {
  req.pipe(fs.createWriteStream(image));
  req.on("end", next);
});

// update data for the first time
app.ws("/", (ws, req) => {
  ["trade","history","init"].forEach(type=>sendData(ws, type));
  sendLog(ws);
});

app.get("/reset", async (req, res) => {
  const {type,orderID} = req.query.type;
  try {
    await db.del(`${type}.${orderID}`);
    res.send("OK");
  } catch(ex){
    res.send(ex);
  }
});

app.get("/resetall", function(req, res) {
  db.clear();
  res.send("OK");
});

app.get("/data", async (req, res,next) => {
  const {type, raw} = req.query;
  if(!data[type]) return next();

  // filter data from image processing
  if(!raw){
    let filterData =  filterDataFromType(type);
    // only update item which is not processed
    if (type == "trade")
      filterData = filterData.filter(item=>item.status != "processed");
    res.send(filterData);
  } else {
    // just return raw data
    res.send(data[type])
  }
});


// get one close order, if empty return null
app.get('/trade', async (req, res)=>{
  const item = data.trade[0];
  res.send(item);
});

// get one close order, if empty return null
app.get('/close', async (req, res)=>{
   const item = data.history[0];
   if(item){
    item.copyOrderIndex = data.init.findIndex(initItem => initItem.orderID == item.copyOrderID);
   }
   res.send(item);
});


app.post("/data", async (req, res, next) => {
  // console.log(req.body);
  // update history => remove from history
  // update trade => status done
  const {type} = req.query;
  if(!data[type]) return next();
  const {orderID, copyOrderID, marginPrice, retries, countLimit} = req.body;

  // console.log( {orderID, copyOrderID, marginPrice, retries});

  // update database
  const updatedItem = data[type].find(item=>item.orderID == orderID);
  if(updatedItem){
      updatedItem.marginPrice = marginPrice;
      updatedItem.copyOrderID = copyOrderID;
      updatedItem.retries = retries;
      updatedItem.countLimit = countLimit;
      sendTelegram(updatedItem, type);
  }
    
  // now remove this item ?, should not, keep it to track removed item, by update db we know we have done this
  // but history is ok
  // if(type == 'history'){
  //   data.history = data.history.filter(item => item.orderID != orderID);
  //   sendDataToAll('history');
  // } else {
  //   // const findIndex = data.trade.findIndex(item => item.orderID == orderID);
  //   // if(findIndex != -1)
  //   // data.trade[findIndex].status = 'processed';
  //   // data.trade[findIndex].copyOrderID = copyOrderID;
  //   data.trade = data.trade.filter(item => item.orderID != orderID);
  //   sendDataToAll('trade');
  // }
  if(countLimit) {
    console.log('Should ignore this order', orderID);
  }
  data[type] = data[type].filter(item => item.orderID != orderID);
  sendDataToAll(type);

  // if history => delete => remove from data.init
  // else append to data.init if asc, else prepend
  if(type == 'history'){
    data.init = data.init.filter(item=>item.orderID != copyOrderID);
  } else {
    // if success then update
    if(updatedItem && updatedItem.copyOrderID){
      data.init.push({...updatedItem,orderID:updatedItem.copyOrderID});
    }
  }

  // update init from subscriber
  sendDataToAll('init');

  // ignore to make sure it is ignore
  await db.put(`${type}.${orderID}`, copyOrderID || "ignore");
  

  res.send("OK");
});

//["orderID", "time", "type", "volume", "symbol", "price", "sl", "tp"]
// Order #2169022 buy 1.00 EURUSD at 1.10984 sl: 0.00000 tp: 0.000000

app.post("/initTrade", async(req,res)=>{
  const {tradeData} = req.body;
  const trades = extractTradeData2(tradeData);
  // append to list
  data.init = trades;
  sendDataToAll('init');
  res.send("OK");
});

// app.post("/addTrade", async(req,res)=>{
//   const {tradeData} = req.body;
//   const trades = extractTradeData2(tradeData);
//   // append to list if not found in init item
//   data.trade =  trades.filter(item => data.init.findIndex(initItem=>initItem.orderID == item.orderID) == -1);
//   res.send("OK");
// });

// app.post("/updateTrade", async(req,res)=>{
//   const {tradeData} = req.body;
//   let trades = extractTradeData2(tradeData);
//   // console.log('updateTrade', trades);
//   let historyChange = false;
//   // only get new trades
//   // trade =  trades.filter(item => data.init.findIndex(initItem=>initItem.orderID == item.orderID) == -1);
//   // if item in trade not found in tradeData => move to history, remove from trade 

//   // new trade - old trade => add
//   // old trade - new trade = history => remove from trade

//   const addedTrades = trades.filter(tradeItem=>data.trade.findIndex(item => item.orderID == tradeItem.orderID) == -1);

//   const newTrade = [];
//   for(let tradeItem of data.trade) {
//     const index = trades.findIndex(item => item.orderID == tradeItem.orderID);
//     if(index == -1){
//       // not found, for close, it is ok whatever 
//       // if for trade, limit become market, new item is still on top, we still loop through so it is ok 
//       const hasDeleted =  data.history.findIndex(item => item.orderID == tradeItem.orderID) != -1;
//       if(!hasDeleted){
//         data.history.push(tradeItem);
//         historyChange = true;
//       }
//     } else {
//       newTrade.push(tradeItem);
//     }
//   }

//   data.trade = newTrade.concat(addedTrades);

//   sendDataToAll('trade');
//   if(historyChange) sendDataToAll('history');
  
//   res.send("OK");
// });

const port = argv.port || 80;
app.listen(port, "0.0.0.0", () => {
  console.log(`Example app listening on ${port}!`);
  // trigger
  sendTradeMessage();
  sendHistoryMessage();
  updateAccounts();
});
