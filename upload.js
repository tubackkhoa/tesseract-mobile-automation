const express = require("express");
const { execSync } = require("child_process");
const request = require("request");
const fs = require("fs");
const sharp = require("sharp");
const { Readable } = require("stream");

let stop = false;
const device = process.argv[2] || "127.0.0.1:58297";
console.log("device", device);

const getStream = async () => {
  const inputBuffer = execSync(`adb -s ${device} exec-out screencap -p`);
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

  const readableInstanceStream = new Readable();
  readableInstanceStream.push(buffer);
  readableInstanceStream.push(null);

  return readableInstanceStream;
};

const run = async () => {
  const upload = await getStream();
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

run();
