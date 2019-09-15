var express = require('express');
var router = express.Router();

router.get('/', function(req, res, next) {
  console.log("incoming stuff");
  res.render('index');
});

router.post("/", function(req, res, next) {
  console.log("woops. you posted in the wrong neighborhood.");
  res.send(":thumbsup:");
});

module.exports = router;
