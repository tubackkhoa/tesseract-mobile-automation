const { execSync } = require("child_process");
const fs = require("fs");
const sharp = require("sharp");

const adb = process.env.ADB;
const env = { TESSDATA_PREFIX: process.env.TESSDATA_PREFIX };
const tesseract = process.env.TESSERACT;

const getStream = async (device, top) => {
  const cmd = `${adb} -s ${device} exec-out screencap -p`;
  const inputBuffer = execSync(cmd);
  // fs.writeFileSync("test.png", inputBuffer);
  // 720 × 1280

  let buffer = await sharp(inputBuffer)
    .extract({
      width: 300,
      height: 1280 - top - 500,
      left: 0,
      top: top
    })
    .toBuffer();

  return buffer;
};

async function detect(device, image, top) {
  // extract from image
  if (device) {
    const buffer = await getStream(device, top);
    // console.log('tesscmd', tesscmd)
    fs.writeFileSync(image, buffer);
  }
  const tesscmd = `${tesseract} ${image} stdout`;
  const rawData = execSync(tesscmd, {
    env: env
  })
    .toString()
    .replace(/(?:Orders|Positions)\s+/g, "");
  return rawData;
}
// receive message from master process
process.on("message", async message => {
  const rawData = await detect(message.device, message.image, message.top);

  // send response to master process
  process.send({ rawData: rawData });
});
