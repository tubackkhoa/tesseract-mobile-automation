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

// update more
env.DEVICE_WIDTH = 1600;
env.DEVICE_HEIGHT = 900;
env.PADDING_BOTTOM = 400;

const db = level('mt4')
const express = require("express");
const { execSync, fork, spawn } = require("child_process");
const fs = require("fs");
const app = express();
const expressWs = require("express-ws")(app);
const bodyParser = require("body-parser");
const path = require('path');
const {extractTradeData, modifyVolume} = require('./utils')

app.use(bodyParser.json()); // support json encoded bodies
app.use(bodyParser.urlencoded({ extended: true })); // support encoded bodies

let stop = false;
let data = { trade: [], history: [] };
let state = {copy:true, start: false};
let accounts = {data:[],selected:''};
let DEBUG = argv.verbose || false;
let delay = argv.delay || 100;
let autoit;
const PERCENTAGE = argv.percentage || 0.1;

const accountsExePath = path.join(__dirname, 'account_list');
const updateAccounts = () => {
  accounts.data = execSync(accountsExePath).toString().replace(/;$/,"").split(/\s*;\s*/);
  if(!accounts.selected) accounts.selected = accounts.data[0];
  setTimeout(updateAccounts, 1000);
}

const stopAutoIT=()=>{
  if(autoit){
    autoit.kill();
    autoit = null;
  }
}

const tradeExePath = path.join(__dirname, 'trade');
const startAutoIT=()=>{
  stopAutoIT();

  const ACTION = state.copy ? "copy" : "reverse";
  const ACCOUNT_ID = accounts.selected;

  // spawn can use current directory
  autoit = spawn(tradeExePath, [], {env:{ACTION, ACCOUNT_ID}});
  autoit.stdout.on('data', (data) => {
    console.log(`stdout: ${data}`);
  });
  
  autoit.stderr.on('data', (data) => {
    console.error(`stderr: ${data}`);
  });
  
  autoit.on('close', (code) => {
    console.log(`child process exited with code ${code}`);
  });
};

// fork another process
const childProcessTrade = fork("./extract_text.js", {
  env: env
});
const childProcessHistory = fork("./extract_text.js", {
  env: env
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
      aWss.clients.forEach(ws => sendData(ws, type));
    } catch (ex) {
      console.log("Error processing");
    }
  }
};

const sendData = (ws, type) => {
  ws.send(JSON.stringify({ data: data[type], type: type }));
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
  if(accounts.selected !== req.body.selected){
    accounts.selected = req.body.selected;
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
  const {copy,start} = req.body;
  // console.log(copy, start);
  if(start !== state.start){
    state.start = start;
    // change status
    if(start) {
      startAutoIT();
    } else {
      stopAutoIT();
    }
  }
  state.copy = copy;
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
      filterData = modifyVolume(filterData, PERCENTAGE);
    }

    res.send(filterData);
  } else {
    // just return raw data
    res.send(data[type])
  }

  
});

app.post("/data", async (req, res) => {
  // console.log(req.body);
  const {type} = req.query;
  const {orderID, copyOrderID} = req.body;
  // update database
  await db.put(`${type}.${orderID}`, copyOrderID);
  res.send("OK");
});

const aWss = expressWs.getWss("/");
const port = argv.port || 80;
app.listen(port, "0.0.0.0", () => {
  console.log(`Example app listening on ${port}!`);
  // trigger
  sendTradeMessage();
  sendHistoryMessage();
  updateAccounts();
});
