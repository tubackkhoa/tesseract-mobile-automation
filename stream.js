const express = require("express");
const { execSync } = require("child_process");
const fs = require("fs");
var app = express();
var expressWs = require("express-ws")(app);
const sharp = require("sharp");
var bodyParser = require("body-parser");
app.use(bodyParser.json()); // support json encoded bodies
app.use(bodyParser.urlencoded({ extended: true })); // support encoded bodies

let stop = false;
let data = [];
let tradeDict = {};
let DEBUG = false;

const image = "./public/test.png";

const device = process.argv[2] || "localhost:5555";


const adb = 'E:/MT4/platform-tools/adb.exe';
const TESSDATA_PREFIX = 'E:/MT4/tesseract/tessdata';
const tesseract = 'E:/MT4/tesseract/tesseract.exe';
const cmd = `${adb} -s ${device} exec-out screencap -p`;
const tesscmd = `${tesseract} ${image} stdout`;

console.log('device', device, 'cmd', cmd);

const getStream = async () => {
  
  const inputBuffer = execSync(cmd);
  // fs.writeFileSync("test.png", inputBuffer);
  // 720 × 1280
  let top = 360;
  let buffer = await sharp(inputBuffer)
    .extract({
      width: 300,
      height: 1280 - top - 100,
      left: 0,
      top: top
    })
    .toBuffer();

    return buffer;
  
};

const sendData = ws => {
  ws.send(JSON.stringify(data));
};

app.use(express.static("public"));

app.post("/upload", function(req, res, next) {
  req.pipe(fs.createWriteStream(image));
  req.on("end", next);
});

// update data for the first time
app.ws("/", function(ws, req) {
  sendData(ws);
});

app.get("/data", function(req,res){
  res.send(data);
});

app.post("/data", function(req, res){
  // console.log(req.body);
  tradeDict[req.body.price] = true;
  res.send("OK");
});

var aWss = expressWs.getWss("/");
const port = process.env.PORT || 80;
app.listen(port, "0.0.0.0", function() {
  console.log(`Example app listening on ${port}!`);
});
const headers = ["symbol", "type", "size", "price", "mprice"];
const detect = async ()=>{
    const buffer = await getStream();     
    // console.log('tesscmd', tesscmd)
    fs.writeFileSync(image, buffer);
    const rawData = execSync(tesscmd).toString();

    const rawList = rawData.split(/\n{2,}/);

    return rawList.map(function(row) {
      const rowData =  row.trim().split(/[^\w\.]+/);
      var ret = {};
      rowData.forEach(function(rowItem, i) {
        ret[headers[i]] = rowItem;
      });
      return ret;
    }).filter(function(rowData){
      return !tradeDict[rowData.price];
    });
};

// trigger update
const update = async () => {
  if (!stop) {
    const start = Date.now();
    try {
      data = await detect();
      if (DEBUG) {
        const elapsed = Date.now() - start;
        console.log("Took " + elapsed + " ms\n", data);
      }
      aWss.clients.forEach(sendData);
    } catch (ex) {
      console.log("Error processing");
    }
    setTimeout(update, 100);
  }
};

update();
