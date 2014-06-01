
function errorProps(err) {
  var errorDebug = "";
  if (typeof(err) != "string") {
    if (Object.keys(err).length < 30) { // don't show when it's a ton of Ruby method properties (or anything else that totally scrolls off the screen)
      for (var prop in err) {
         errorDebug += "property '" + prop + "' value: " + err[prop] + "\n";
      }
    } else {
      errorDebug += "too many properties: " + Object.keys(err).length + "\n";
    }
  }
  errorDebug += "toString(): " + err.toString() + "\n";
  return errorDebug;
}

/**
 * This shows a user-friendly alert with a bunch of debugging info, including a stack trace showing function names and argument values passed in.
 *
 * Unfortunately, it appears that assigning window.onerror doesn't work in Ti.
 *
 * requires stacktrace.js
 */
function p2pdocsHandleError(err, extras) {
  message = "Sorry!  I don't understand what just happened.  If you don't mind, contact the nice people at " + Ti.App.getURL() + " and send them this information.  Thanks!\n\n";
  message += "version: " + Ti.App.getVersion() + "\n";
  message += errorProps(err);
  if (extras) {
    message += errorProps(extras);
  }
  message += "stack: " + printStackTrace({e:err, guess:true}).join('\n- ');
  alert(message);
}

/**
 * 
 * Returns a function that will open the given location in the system's default application for that file extension.
 * To open a directory, pass an empty path.
 * 
 * requires Titanium, stacktrace.js
 */
function viewFileWrapperFunc(sourceDir, path) {
  // This indirect path to the function is so that the values are saved
  // (and we don't have to refer to other variables which can cause Titanium crashes/errors).
  // Return false (so event handler on click won't signal page refresh).
  var viewFileFunc = function() {
    // We use another method so that its name shows in the stack trace (instead of just anonymous).
    viewFile(sourceDir, path);
    return false;
  }
  return viewFileFunc;
}

/**
 * No return value specified.
 */
function viewFile(sourceDir, path) {
  if (path == null) {
    path = "";
  }
  var file = Ti.Filesystem.getFile(sourceDir, path).toString();
  try {
    var result = Ti.Platform.openApplication(file);
    if (result !== "true"     // The API says that the result is a string...
        && result !== true) { // ... but I'm getting a boolean result.
      alert("Sorry!  We had a problem opening that file.  If you report this problem, the following info will help.\nfile: " + file + "\nresult: " + result);
    }
  } catch (e) {
    p2pdocsHandleError(e, {"file":file});
  }
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
    // I added this decode & replace: looks like Titanium doesn't unencode this internal stuff
    return decodeURIComponent(results[1]).replace(/\+/g, " ");
}

