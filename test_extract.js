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



const { fork } = require("child_process");
const argv = require("yargs").argv;

// 250: emulator-5564:history.png, 300, emulator-5554, trade.png

env.PADDING_BOTTOM = argv.bottom || 0;
env.DEVICE_WIDTH = 1600;
env.DEVICE_HEIGHT = 1440;
// fork another process
const childProcess = fork("./extract_text.js", {
  env: env
});

childProcess.send({
  device: argv.device,
  image: argv.image,
  top: argv.top || 210,
  right: argv.right || 550 
});

// listen for messages from forked childProcess
childProcess.on("message", message => {
   console.log(message.rawData);
   childProcess.kill();
});
