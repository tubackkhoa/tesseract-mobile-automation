const argv = require("yargs").argv;
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

const express = require("express");
const { execSync, fork } = require("child_process");
const fs = require("fs");
var app = express();
var expressWs = require("express-ws")(app);

var bodyParser = require("body-parser");
app.use(bodyParser.json()); // support json encoded bodies
app.use(bodyParser.urlencoded({ extended: true })); // support encoded bodies

let stop = false;
let data = { trade: [], history: [] };
let dict = { trade: {}, history: {} };
let historyDict = {};
let DEBUG = argv.verbose || false;
let delay = argv.delay || 100;
const PERCENTAGE = argv.percentage || 0.1;

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
    top: 300
  });
};

const sendHistoryMessage = () => {
  childProcessHistory.send({
    device: argv.deviceHistory,
    image: "public/history.png",
    top: 250
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

const headers = ["symbol", "type", "size", "price", "mprice"];
const detect = rawData => {
  const rawList = rawData.split(/(\r?\n){2,}/);
  const list = [];

  rawList.forEach(row => {
    const matched = row.match(
      /(\w+),\s*(sell|buy)\s*limit\s*([\d\.]+)\s+at\s+([\d\.]+)/im
    );
    if (matched) {
      // console.log(row);
      var ret = {};
      for (let i = 0; i < 4; ++i) ret[headers[i]] = matched[i + 1];
      ret.size = (ret.size * PERCENTAGE).toFixed(4);
      list.push(ret);
    }
  });
  // console.log('list', list);
  return list;
};

// trigger update
const update = (rawData, type) => {
  if (!stop) {
    const start = Date.now();
    try {
      data[type] = detect(rawData);
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

app.use(express.static("public"));

app.post("/upload", function(req, res, next) {
  req.pipe(fs.createWriteStream(image));
  req.on("end", next);
});

// update data for the first time
app.ws("/", function(ws, req) {
  sendData(ws, "trade");
  sendData(ws, "history");
});

app.get("/reset", function(req, res) {
  const type = req.query.type;
  dict[type][req.query.price] = false;
  res.send("OK");
});

app.get("/resetall", function(req, res) {
  const type = req.query.type;
  dict[type] = {};
  res.send("OK");
});

app.get("/data", function(req, res,next) {
  const type = req.query.type;
  if(!data[type]) return next();
  const filterData = data[type].filter(function(rowData) {
    return !dict[type][rowData.price];
  });
  res.send(filterData);
});

app.post("/data", function(req, res) {
  // console.log(req.body);
  const type = req.query.type;
  dict[type][req.body.price] = true;
  res.send("OK");
});

var aWss = expressWs.getWss("/");
const port = argv.port || 80;
app.listen(port, "0.0.0.0", () => {
  console.log(`Example app listening on ${port}!`);
  // trigger
  sendTradeMessage();
  sendHistoryMessage();
});
