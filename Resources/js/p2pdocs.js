/**
 * requires Titanium
 */

function viewFileWrapperFunc(sourceDir, path) {
  var viewFileFunc = function() {
    if (path == null) {
      path = "";
    }
    var file;
    if (path == Titanium.Filesystem.getSeparator()) {
      file = sourceDir + Titanium.Filesystem.getSeparator();
    } else {
      file = Titanium.Filesystem.getFile(sourceDir, path); // note that this doesn't append path if path is "/"
    }
    try {
      var result = Titanium.Platform.openApplication(file);
      if (result !== "true"     // The API says that the result is a string...
          && result !== true) { // ... but I'm getting a boolean result.
        alert("Sorry!  We had a problem opening that file.  If you report this problem, the following info will help.\nfile: " + file + "\nresult: " + result);
      }
    } catch (err) {
      var errDebug = "";
      if (typeof(err) != "string") {
        for (var prop in err) {
           errDebug += "property: " + prop + " value: [" + err[prop] + "]\n";
        }
      }
      errDebug += "toString() value: [" + err.toString() + "]\n";
      alert("Sorry!  We had a problem opening that file.  If you report this problem, the following info will help.\nfile: " + file + "\n" + errDebug);
    }
    return false;
  }
  return viewFileFunc;
}
