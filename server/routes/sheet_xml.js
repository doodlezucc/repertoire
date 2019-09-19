var express = require("express");
var jimp = require("jimp");
var path = require("path");
var spawn = require("child_process").spawn;
var exec = require("child_process").exec;
var jo = require("jpeg-autorotate");
var fs = require("fs");
var router = express.Router();

const audiverisPath = "/home/tappi/audiveris/";
const directoryPath = "/home/tappi/lal/";

router.post("/", function (req, res) {
  print("lul");
  var name = req.body.name;
  var img = req.body.image;
  var realFile = Buffer.from(img, "base64");
  fs.writeFile(name, realFile, function (err) {
    if (err)
      console.log(err);
  });
  res.send("OK");
});

module.exports = router;




function spawnPretty(cmd, args) {
  return new Promise((resolve, reject) => {
    console.log(cmd);
    var child = spawn(cmd, args);

    child.stdout.setEncoding('utf8');
    child.stdout.on('data', function (data) {
      //Here is where the output goes

      console.log('stdout: ' + data);

      data = data.toString();
    });

    child.on("close", function () {
      resolve();
    });
  });
}


var input = path.join(__dirname, "try2.JPG");
//drainExif(input);
//interpretImageAsMusicXML(input);
processTask(input);

async function processTask(file) {
  const low = file.toLowerCase();
  if (low.endsWith(".png") || low.endsWith(".jpg") || low.endsWith(".gif")) {
    console.log("Dealing with an image");
    file = await drainExif(file);
  }
  fileToMusicXml(file);
  //console.log(std);
}

function fileToMusicXml(file) {
  console.log("magically turning file into musicxml");
  spawnPretty(audiverisPath + "gradlew", ["run", "--project-dir", audiverisPath, "-PcmdLineArgs", "\"-batch,-export,-output," + directoryPath + ",--," + file + "\""]);
}


function drainExif(file) {
  return new Promise((resolve, reject) => {
    jo.rotate(file, { quality: 85 })
      .then(({ buffer, orientation, dimensions, quality }) => {
        console.log(`Orientation was ${orientation}`)
        console.log(`Dimensions after rotation: ${dimensions.width}x${dimensions.height}`)
        console.log(`Quality: ${quality}`);
        var output = path.join(__dirname, "normalized.jpg");
        fs.writeFile(output, buffer, function (err) {
          console.log(err ? err : "yawww");
          resolve(output);
        });
      })
      .catch((error) => {
        if (error.code === jo.errors.correct_orientation) {
          resolve(file);
        } else {
          console.log('An error occurred when rotating the file: ' + error.message);
          reject(error);
        }
      });
  });
}

function preprocessImage(file) {
  console.log("pre-processing image");
  return new Promise(resolve => {
    jimp.read(file)
      .then(img => {
        var start = Date.now();
        img
          .scan(0, 0, img.bitmap.width, img.bitmap.height, (x, y, idx) => {
            var v = img.bitmap.data[idx + 1];
            if (v > 110) {
              v = 255;
            } else {
              v = 0;
            }
            img.bitmap.data[idx + 0] = v;
            img.bitmap.data[idx + 1] = v;
            img.bitmap.data[idx + 2] = v;
          });
        var diff = Date.now() - start;
        console.log("Millis passed: " + diff);
        resolve(img);
        img.write(path.join(__dirname, "out.jpg"));
      });
  });
}

function straightenSheet(img) {
  return new Promise(resolve => {

  });
}

async function interpretImageAsMusicXML(file, cb) {
  //drainExif();
  var prep = await preprocessImage(file);

  console.log("yayeya");
}
