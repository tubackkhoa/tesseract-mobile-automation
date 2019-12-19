const { spawn,execSync  } = require("child_process");
const argv = require("yargs").argv;

// const env = {ACCOUNT_ID:argv.account};

const autoit = spawn('history', [], {env});

autoit.stdout.on('data', (data) => {
  console.log(`stdout: ${data}`);
});

autoit.stderr.on('data', (data) => {
  console.error(`stderr: ${data}`);
});

autoit.on('close', (code) => {
  console.log(`child process exited with code ${code}`);
});

// const ret = execSync(__dirname + '/account_list').toString().trim().split(/\s+/);
// console.log(ret);
// setTimeout(()=>autoit.kill(), 10000);