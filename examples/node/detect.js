const Tesseract = require("../../");
const fetch = require("node-fetch");
const fs = require("fs");
const sharp = require("sharp");

const worker = Tesseract.createWorker({
  logger: m => {
    // console.log(m);
  }
});

// const getImage = async sessionID => {
//   const base64String = await fetch(
//     `http://localhost:4723/wd/hub/session/${sessionID}/screenshot`
//   )
//     .then(res => res.json())
//     .then(body => body.value);
//   const inputBuffer = Buffer.from(base64String, "base64");
//   // 1440 × 2960
//   const buffer = await sharp(inputBuffer)
//     .extract({
//       width: 1440,
//       height: 1480,
//       left: 0,
//       top: 820
//     })
//     .resize({ width: 850 })
//     .toBuffer();

//   fs.writeFileSync("./test.png", buffer);
//   // return "./test.png";
//   return buffer;
// };

const getImage = () => {
  return execSync(
    `/Applications/Genymotion.app/Contents/MacOS/tools/adb exec-out screencap -p`
  );
};

let stop = false;
// let sessionID = process.argv[2];
(async () => {
  await worker.load();
  await worker.loadLanguage("eng");
  await worker.initialize("eng");
  // await worker.setParameters("tessedit_pageseg_mode", "7");
  while (!stop) {
    const image = await getImage();
    const start = Date.now();
    const {
      data: { text }
    } = await worker.recognize(image);
    const elapsed = Date.now() - start;
    console.log("Took " + elapsed + " ms\n", text);
  }
  await worker.terminate();
  console.log("Exited");
})();

process.on("beforeExit", code => {
  stop = true;
});
