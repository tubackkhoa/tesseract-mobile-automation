//https://api.telegram.org/bot1069055490:AAF6X4Cq-QQrNvIRTn400qjEwFpWFCY7gok/getUpdates

const https = require('https');

class Telegram {

    constructor(token){
        this.endpoint = `https://api.telegram.org/bot${token}/sendMessage?chat_id=%chatId&text=%message`;
    }

    send (recipient, message) {
        let endpointUrl = this.endpoint
            .replace('%chatId', recipient)
            .replace('%message', encodeURIComponent(message));

        https.get(endpointUrl, (res) => {
            res.on("data", function(chunk) {
                console.log("BODY: " + chunk);
            });
        });
    }
}

const telegram = new Telegram('1069055490:AAF6X4Cq-QQrNvIRTn400qjEwFpWFCY7gok');
//telegram.send('857037443', 'Hello');
telegram.send('-308224929', 'Lets have lunch to all');