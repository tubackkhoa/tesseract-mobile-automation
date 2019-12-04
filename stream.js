const express = require("express");
const { execSync } = require("child_process");
const fs = require("fs");
var app = express();
var expressWs = require("express-ws")(app);
const sharp = require("sharp");

let stop = false;
let data = "";
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
  ws.send(data);
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

var aWss = expressWs.getWss("/");
const port = process.env.PORT || 80;
app.listen(port, "0.0.0.0", function() {
  console.log(`Example app listening on ${port}!`);
});

const detect = async ()=>{
    const buffer = await getStream();     
    // console.log('tesscmd', tesscmd)
    fs.writeFileSync(image, buffer);
    return execSync(tesscmd).toString();
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
