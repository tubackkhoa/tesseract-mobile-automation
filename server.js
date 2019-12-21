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
const {extractTradeData, modifyVolume, Telegram} = require('./utils');

const telegram = new Telegram(argv.telegramToken || '1069055490:AAF6X4Cq-QQrNvIRTn400qjEwFpWFCY7gok');
const TELEGRAM_GROUPID = argv.chatId || '-308224929';

app.use(bodyParser.json()); // support json encoded bodies
app.use(bodyParser.urlencoded({ extended: true })); // support encoded bodies

let stop = false;
let data = { trade: [], history: [] };
let log = {};
let state = {copy:true, start: false,multiply:0.1,marginLimit:0.015};
let accounts = {data:[],pubSelected:'',subSelected:''};
let DEBUG = argv.verbose || false;
let delay = argv.delay || 100;
let autoit;

const accountsExePath = path.join(__dirname, 'account_list');
const updateAccounts = () => {
  accounts.data = execSync(accountsExePath).toString().replace(/;$/,"").split(/\s*;\s*/);
  if(!accounts.pubSelected) accounts.pubSelected = accounts.data[0];
  if(!accounts.subSelected) accounts.subSelected = accounts.data[accounts.data.length - 1];
  setTimeout(updateAccounts, 1000);
}

const stopAutoIT=()=>{
  if(autoit){
    autoit.kill();
    autoit = null;
  }
}

const aWss = expressWs.getWss("/");

const sendDataToAll = (type) => {
  const message = JSON.stringify({ data: data[type], type: type });
  aWss.clients.forEach(ws => ws.send(message));
};

const sendData = (ws, type) => {
  ws.send(JSON.stringify({ data: data[type], type: type }));
};

const sendLog = (ws) => {
  ws.send(JSON.stringify({ data: log, type: 'log' }));
};

const sendLogToAll = () => {
  const message = JSON.stringify({ data: log, type: 'log' })
  aWss.clients.forEach(ws => ws.send(message));
};

const sendTelegram = (tradeItem, type) => {
  // console.log(tradeItem, type);
  if(tradeItem){
    //["orderID", "time", "type", "volume", "symbol", "price", "sl", "tp"]
    let message = accounts.subSelected + ", ";
    if(tradeItem.marginPrice){
      message += `Ignore because differ by ${tradeItem.marginPrice}`;
    } else {
      message += type === 'trade' ? `${state.copy ? 'Copy' : 'Reverse'} [${tradeItem.type}]` : 'Close';
    }
    message += ` ${tradeItem.orderID} Price: ${tradeItem.price}`;
    if(type == 'trade'){
      message += ` Volume: ${tradeItem.volume * state.multiply} S/L: ${tradeItem.sl} T/P:${tradeItem.tp}`;
    }
    telegram.send(TELEGRAM_GROUPID, message);
  }
};

const tradeExePath = path.join(__dirname, 'trade');
const startAutoIT=()=>{
  stopAutoIT();

  const ACTION = state.copy ? "copy" : "reverse";
  const PUBLISH_ACCOUNT_ID = accounts.pubSelected;
  const SUBSCRIBE_ACCOUNT_ID = accounts.subSelected;
  const MARGIN_LIMIT = state.marginLimit;

  if(PUBLISH_ACCOUNT_ID === SUBSCRIBE_ACCOUNT_ID) return ;

  // spawn can use current directory
  autoit = spawn(tradeExePath, [], {env:{ACTION, PUBLISH_ACCOUNT_ID,SUBSCRIBE_ACCOUNT_ID,MARGIN_LIMIT}});
  autoit.stdout.on('data', (data) => {
    const message = data.toString();
    log = {type: 'info', message};
    sendLogToAll();
    console.log(`stdout: ${message}`);
  });
  
  autoit.stderr.on('data', (data) => {
    message = data.toString();
    log =  {type: 'danger', message};
    sendLogToAll();
    console.error(`stderr: ${message}`);
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
    PADDING_BOTTOM: 400,
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
childProcessTrade.on("message", message => {
  update(message.rawData, "trade");
  setTimeout(sendTradeMessage, delay);
});

// listen for messages from forked childProcess
childProcessHistory.on("message", message => {
  update(message.rawData, "history");
  setTimeout(sendHistoryMessage, delay);
});


const filterCopyTrade = async tradeData => {
  const filterData = [];
  for(let item of tradeData) {
    const copyOrderID = await getCopyOrderID('trade', item.orderID);
    // has entered 
    if(copyOrderID) filterData.push({...item,copyOrderID});
  }
  return filterData;
}



// trigger update
const update = (rawData, type) => {
  if (!stop) {
    const start = Date.now();
    try {
      data[type] = extractTradeData(rawData);
      if (DEBUG) {
        const elapsed = Date.now() - start;
        console.log("Took " + elapsed + " ms\n", type, data[type]);
      }
      sendDataToAll(type);
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
  const {pubSelected, subSelected} = req.body;
  if(accounts.pubSelected !== pubSelected || accounts.subSelected !== subSelected){
    accounts.pubSelected = pubSelected;
    accounts.subSelected = subSelected;
    if(state.start) {
      startAutoIT();
    }
  }
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
  }
  
  res.send(state);
});

app.post("/upload", function(req, res, next) {
  req.pipe(fs.createWriteStream(image));
  req.on("end", next);
});

// update data for the first time
app.ws("/", (ws, req) => {
  sendData(ws, "trade");
  sendData(ws, "history");
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
    let filterData = [];
    for(let item of data[type]) {
      const copyOrderID = await getCopyOrderID(type, item.orderID);
      // console.log(type, item.orderID,copyOrderID);
      // not processed
      if(!copyOrderID) filterData.push(item);
    }
  
    if(type === 'history'){
      // with history, it means that we need to close the order, 
      // and we only close copy order that is mapped to this order, otherwise it is meaningless
      filterData = await filterCopyTrade(filterData);
    } else {
      filterData = modifyVolume(filterData, state.multiply);
    }

    res.send(filterData);
  } else {
    // just return raw data
    res.send(data[type])
  }

  
});

app.post("/data", async (req, res, next) => {
  // console.log(req.body);
  const {type} = req.query;
  if(!data[type]) return next();
  const {orderID, copyOrderID, marginPrice} = req.body;
  // update database
  const updatedItem = data[type].find(item=>item.orderID == orderID);
  updatedItem.marginPrice = marginPrice;
  sendTelegram(updatedItem, type);
  // now remove this item ?, should not, keep it to track removed item, by update db we know we have done this
  // but history is ok
  if(type == 'history')
    data.history = data.history.filter(item => item.orderID != orderID);

  await db.put(`${type}.${orderID}`, copyOrderID || "");
  res.send("OK");
});

//["orderID", "time", "type", "volume", "symbol", "price", "sl", "tp"]
// Order #2169022 buy 1.00 EURUSD at 1.10984 sl: 0.00000 tp: 0.000000
app.post("/addTrade", async(req,res)=>{
  const {tradeData} = req.body;
  const trades = extractTradeData2(tradeData);
  // append to list
  data.trade = [...data.trade, ...trades];
  res.send("OK");
});

app.post("/closeTrade", async(req,res)=>{
  const {tradeData} = req.body;
  const trades = extractTradeData2(tradeData);
  // if item in trade not found in tradeData => move to history, remove from trade 
  const newTrade = [];
  for(let tradeItem of data.trade) {
    const index = trades.findIndex(item => item.orderID == tradeItem.orderID);
    if(index == -1){
      // not found, for close, it is ok whatever 
      // if for trade, limit become market, new item is still on top, we still loop through so it is ok 
      data.history.push(tradeItem);
    } else {
      newTrade.push(tradeItem);
    }
  }
  
  data.trade = newTrade;
  
  res.send("OK");
});

const port = argv.port || 80;
app.listen(port, "0.0.0.0", () => {
  console.log(`Example app listening on ${port}!`);
  // trigger
  // sendTradeMessage();
  // sendHistoryMessage();
  updateAccounts();
});
