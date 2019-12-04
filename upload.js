const express = require("express");
const { execSync } = require("child_process");
const request = require("request");
const fs = require("fs");
const sharp = require("sharp");
const { Readable } = require("stream");

let stop = false;
const device = process.argv[2] || "localhost:5555";


const adb = 'E:/MT4/platform-tools/adb.exe';
const TESSDATA_PREFIX = 'E:/MT4/tesseract/tessdata';
const tesseract = 'E:/MT4/tesseract/tesseract.exe';
const cmd = `${adb} -s ${device} exec-out screencap -p`;

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

const run = async () => {
  const buffer = await getStream();
  const upload = new Readable();
  upload.push(buffer);
  upload.push(null);

  upload.pipe(request.post("http://202.134.19.119:3000/upload"));

  var upload_progress = 0;
  upload.on("data", function(chunk) {
    upload_progress += chunk.length;
    console.log(new Date(), upload_progress);
  });

  upload.on("end", function(res) {
    console.log("Done update");
    setTimeout(run, 100);
  });
};

// run();

const test = async ()=>{
  const start = Date.now();
    try {
      const buffer = await getStream();
      const image = "test.png";
      const tesscmd = `${tesseract} ${image} stdout`;
      console.log('tesscmd', tesscmd)
      fs.writeFileSync(image, buffer);
      const data = execSync(tesscmd).toString();
      const elapsed = Date.now() - start;
      console.log("Took " + elapsed + " ms\n", data);
      
    } catch (ex) {
      console.log("Error processing", ex);
    }
}

test();