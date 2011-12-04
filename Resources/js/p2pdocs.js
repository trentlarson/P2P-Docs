
function errorProps(err) {
  var errorDebug = "";
  if (typeof(err) != "string") {
    for (var prop in err) {
       errorDebug += "property: " + prop + " value: [" + err[prop] + "]\n";
    }
  }
  errorDebug += "toString(): [" + err.toString() + "]\n";
  return errorDebug;
}

/**
 * This shows a user-friendly alert with a bunch of debugging info, including a stack trace showing function names and argument values passed in.
 *
 * Unfortunately, it appears that assigning window.onerror doesn't work in Titanium.
 *
 * requires stacktrace.js
 */
function p2pdocsHandleError(err, extras) {
  message = "Sorry!  I don't understand what just happened.  If you don't mind, contact the nice people at familyhistories.info and send them this information.  Thanks!\n\n";
  message += "version: " + Titanium.App.getVersion() + "\n";
  message += errorProps(err);
  if (extras) {
    message += errorProps(extras);
  }
  message += "stack: " + printStackTrace().join('\n- ');
  alert(message);
}

/**
 * Returns a function that will open the given location in the system's default opener.
 * To open a directory, pass a path of Titanium.FileSystem.getSeparator() (because other things don't work, such as ending the sourceDir with the separator).
 * 
 * requires Titanium, stacktrace.js
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
      file = Titanium.Filesystem.getFile(sourceDir, path); // note that getFile doesn't append path if path is "/"
    }
    try {
      var result = Titanium.Platform.openApplication(file);
      if (result !== "true"     // The API says that the result is a string...
          && result !== true) { // ... but I'm getting a boolean result.
        alert("Sorry!  We had a problem opening that file.  If you report this problem, the following info will help.\nfile: " + file + "\nresult: " + result);
      }
    } catch (e) {
      p2pdocsHandleError(e, {"file":file});
    }
    return false;
  }
  return viewFileFunc;
}

// from http://www.netlobo.com/url_query_string_javascript.html
// also in search.html
function urlParam( name )
{
  name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
  var regexS = "[\\?&]"+name+"=([^&#]*)";
  var regex = new RegExp( regexS );
  var results = regex.exec( window.location.href );
  if( results == null )
    return null;
  else
    return unescape(results[1]); // I added the unescape: looks like Titanium doesn't unencode this internal stuff.
}

