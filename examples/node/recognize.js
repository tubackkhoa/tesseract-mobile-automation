#!/usr/bin/env node
const path = require("path");
const Tesseract = require("../../");

const [, , imagePath] = process.argv;
const image = process.argv[2];

console.log(`Recognizing ${image}`);

Tesseract.recognize(image, "eng", { logger: m => console.log(m) }).then(
  ({ data: { text } }) => {
    console.log(text);
  }
);
