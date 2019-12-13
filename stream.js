const express = require("express");
const { execSync } = require("child_process");
const fs = require("fs");
var app = express();
var expressWs = require("express-ws")(app);

var bodyParser = require("body-parser");
app.use(bodyParser.json()); // support json encoded bodies
app.use(bodyParser.urlencoded({ extended: true })); // support encoded bodies

let stop = false;
let data = [];
let tradeDict = {};
let DEBUG = false;

const image = "./public/test.png";

const device = process.argv[2] || "localhost:5555";

console.log('device', device, 'cmd', cmd);



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

app.get("/reset", function(req, res){
  tradeDict[req.query.price] = false;
  res.send("OK");
});

app.get("/resetall", function(req, res){
  tradeDict = {};
  res.send("OK");
});

app.get("/data", function(req,res){
  const filterData = data.filter(function(rowData){
    return !tradeDict[rowData.price];
  });
  res.send(filterData);
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
const PERCENTAGE = 0.1;
const detect = async ()=>{
    const buffer = await getStream();     
    // console.log('tesscmd', tesscmd)
    fs.writeFileSync(image, buffer);
    const rawData = execSync(tesscmd).toString().replace(/Orders\s+/g,'');
    // console.log(rawData);

    const rawList = rawData.split(/(\r?\n){2,}/);
    // console.log(rawList);
    const list = []

    rawList.forEach(function(row) {
      
      const matched =  row.match(/(\w+),\s*(sell|buy)\s*limit\s*([\d\.]+)\s+at\s+([\d\.]+)/im);
      if(matched){
        // console.log(row);
        var ret = {};
        for(let i=0;i<4;++i)
          ret[headers[i]] = matched[i+1];
          ret.size = (ret.size * PERCENTAGE).toFixed(4);
        list.push(ret);
      }
    });
    // console.log('list', list);
    return list; 
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
