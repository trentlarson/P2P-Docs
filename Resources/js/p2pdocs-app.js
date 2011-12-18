// from stuff I saw here: https://geoserver.org/suite/browser/trunk/dashboard/OpenGeo Dashboard/Resources/app/script/workers/stats.js?rev=1282
onmessage = function(e) {
  if (e.message) {
    Titanium.API.print("Starting count, because p2pdocs-app got message: " + e.message + "\n");
    count();
  }
};

var process = {
  status : "initial value",
  setStatus : function(message) {
    this.status = message;
  }
};

function count(i) {
  // There's no good way inside a thread to wait nicely; this will hang the program for a few seconds.
  // (I tried setTimeout and setInterval, but those methods aren't recognized here.)
  for (var i = 0; i < 1000000000; i++) {}
  process.setStatus(i);
  Titanium.API.print("Finished count, so status is set to to " + process.status + "\n");
  postMessage({status:process.status});
}
