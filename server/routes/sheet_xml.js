var express = require("express");
var jimp = require("jimp");
var path = require("path");
var exec = require("child_process").exec;
var router = express.Router();

router.post("/", function(req, res){
  print("lul");
  var name = req.body.name;
  var img = req.body.image;
  var realFile = Buffer.from(img,"base64");
  fs.writeFile(name, realFile, function(err) {
      if(err)
         console.log(err);
   });
   res.send("OK");
 });

module.exports = router;




/**
 * Executes a shell command and return it as a Promise.
 * @param cmd {string}
 * @return {Promise<string>}
 */
function execShellCommand(cmd) {
  const exec = require('child_process').exec;
  return new Promise((resolve, reject) => {
   exec(cmd, (error, stdout, stderr) => {
    if (error) {
     console.warn(error);
    }
    resolve(stdout? stdout : stderr);
   });
  });
 }

var input = path.join(__dirname, "sheet.JPG");
//interpretImageAsMusicXML(input);

async function interpretImageAsMusicXML(imgFile, cb) {
  console.log("removing orientation");
  await execShellCommand("exiftool -Orientation=1 " + imgFile);
  console.log("pre-processing image");

  jimp.read(imgFile).then(img => {
    img
      .greyscale()
      .brightness(0.25)
      .contrast(1)
      .write(path.join(__dirname, "out.jpg"));
    console.log("yayeya");
  })
  .catch(err => {
    console.error(err);
  });
}
