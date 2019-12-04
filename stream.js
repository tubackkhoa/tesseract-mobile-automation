const express = require("express");
const { execSync } = require("child_process");
const fs = require("fs");
var app = express();
var expressWs = require("express-ws")(app);

let stop = false;
let data = "";
let DEBUG = false;

const image = "./public/test.png";

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

app.listen(3000, "0.0.0.0", function() {
  console.log("Example app listening on port 3000!");
});

// trigger update
const update = () => {
  if (!stop) {
    const start = Date.now();
    try {
      data = execSync(`tesseract ${image} stdout`).toString();
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
