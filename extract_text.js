const { execSync } = require("child_process");
const fs = require("fs");
const sharp = require("sharp");

const adb = process.env.ADB;
const env = { TESSDATA_PREFIX: process.env.TESSDATA_PREFIX };
const tesseract = process.env.TESSERACT;
const DEVICE_WIDTH = process.env.DEVICE_WIDTH ||1600;
const DEVICE_HEIGHT = process.env.DEVICE_HEIGHT ||900;

const getStream = async (device, top, right) => {
  const cmd = `${adb} -s ${device} exec-out screencap -p`;
  const inputBuffer = execSync(cmd);
  // fs.writeFileSync("test.png", inputBuffer);
  // 720 × 1280

  let buffer = await sharp(inputBuffer)
    .extract({
      width: DEVICE_WIDTH - right,
      height: DEVICE_HEIGHT - top,
      left: 0,
      top: top
    })
    .toBuffer();

  return buffer;
};

async function detect(device, image, top, right) {
  // extract from image
  if (device) {
    const buffer = await getStream(device, top, right);
    // console.log('tesscmd', tesscmd)
    fs.writeFileSync(image, buffer);
  }
  const tesscmd = `${tesseract} ${image} stdout --psm 6`;
  const rawData = execSync(tesscmd, {
    env: env
  })
    .toString()
   // .replace(/(?:Orders|Positions)\s+/g, "");
  return rawData;
}
// receive message from master process
process.on("message", async message => {
  try {
    const rawData = await detect(message.device, message.image, message.top, message.right);

    // send response to master process
    process.send({ rawData: rawData });
  } catch(ex){
    process.send({ error: ex.message})
  }
});
