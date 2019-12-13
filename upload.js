const { fork } = require('child_process');
const argv = require('yargs').argv


// 250: emulator-5564:history.png, 300, emulator-5554, trade.png

// fork another process
const process = fork('./extract_text.js');
process.send({ device:argv.device, image:argv.image, top:(argv.top||300) });
// listen for messages from forked process
process.on('message', (message) => {
  console.log(message.rawData);
});