var server,
  http      = require('http'),
  sys       = require("sys"),
  apricotLib= require('apricot');
  qsLib     = require('querystring');
  urlLib    = require("url"),
  filesystem= require("fs"),
  GitHubApi = require("github").GitHubApi,
  github    = new GitHubApi(true),
  githubUserOfConcern = 'appcelerator';

var ohNo = function(req, resp, err) {
  resp.writeHead(500, {"Content-Type": "text/plain"});  
    resp.write(err + "\n");  
    resp.end();
    return;
};
  
var getFollowers = function(req, resp) {
  github.getUserApi().getFollowers(githubUserOfConcern, function(err, followers) {
      if(err) { ohNo(req, resp, err); }
      
      if (followers) {
        resp.write(JSON.stringify({users: followers}));
      } else {
        resp.write(JSON.stringify({users: []}));
      }
      
      resp.end();
  });
};

var getRepos = function(req, resp) {
  github.getRepoApi().getUserRepos(githubUserOfConcern, function(err, repositories) {
      if(err) { ohNo(req, resp, err); }

      if (repositories) {
        resp.write(JSON.stringify({repos: repositories}));
      } else {
        resp.write(JSON.stringify({repos: []}));
      }
      
      resp.end();
  });
};

var getRepoWatchers = function(req, resp) {
  var urlParts = req.url.split('/');
  if (urlParts && urlParts.length === 3) {
    //Valid length, so pick out the repo name
    var repo = urlParts[2];
    
    github.getRepoApi().getRepoWatchers(githubUserOfConcern, repo, function(err, watchers) {
        if(err) { ohNo(req, resp, err); }

        if (watchers) {
          resp.write(JSON.stringify({users: watchers}));
        } else {
          resp.write(JSON.stringify({users: []}));
        }
        
        resp.end();
    });
  } else {
    resp.writeHead(404, {"Content-Type": "text/plain"});  
        resp.write("404 Not Found\n");  
        resp.end(); 
        return;
  }
};

var getProfile = function(req, resp) {
  var urlParts = req.url.split('/');
  if (urlParts && urlParts.length === 3) {
    //Valid length, so pick out the username
    var username = urlParts[2];
    
    github.getUserApi().show(username, function(err, details) {
        if(err) { ohNo(req, resp, err); }
        
        resp.write(JSON.stringify(details));
        resp.end();
    });
  } else {
    resp.writeHead(404, {"Content-Type": "text/plain"});  
        resp.write("404 Not Found\n");  
        resp.end(); 
        return;
  }
};

function endsWith(str, suffix) {
  return str.indexOf(suffix, str.length - suffix.length) !== -1;
}


function serveScript(fileUnderResources, resp) {
  filesystem.readFile(__dirname + '/' + fileUnderResources, function(err, data) {
    if (err) {
      resp.writeHead(500, {"Content-Type": "text/plain"});
      resp.write("500 Server Error: " + err + "\n");
      resp.end();
    } else {
      resp.writeHead(200, {"Content-Type": "application/javascript"});
      resp.write(data);
      resp.end();
    }
  });
}


/**
 * request should have two parameters: "ancestryIds" is the list of ancestor IDs (for use in XYZ),
 *   and "incomingFiles" is a JSON-stringified array of: "path" file name through which to search for those IDs, 
 *    plus other things for displaying results (eg. "repoNum" & "diffNum")
 * return an array of the incomingFiles info, each with the addition of: "context" with surrounding text
 *   and "position" with the ID attribute of the preceding element
 */
var checkDatabase = function(request, response) {
  if (request.method == 'POST') {
    var body = '';
    request.on('data', function (data) {
      body += data;
    });
    request.on('end', function () {
      var postData = qsLib.parse(body);
      var idInfo = JSON.parse(postData['ancestryIds']);
      var allIds = [];
      for (var i = 0, len = idInfo.length; i < len; i++) {
        allIds = allIds.concat([idInfo[i]['id']]);
      }
      allIds.sort();
            
      //console.log("Searching for these IDs: " + JSON.stringify(allIds));
      // an array of file diff info
      incomingFiles = JSON.parse(postData['incomingFiles']);
      if (incomingFiles.length === 0) {
        response.write("[]");
        response.end();
      } else {
        //console.log(" ... in these files: " + JSON.stringify(incomingFiles));
        // an array of objects with: file, context, position (similar to main in search.rb)
        var resultsCollector = {
          inProgress: incomingFiles.length,
          results: [],
          fillResult: function(interestingLocations) {
            //console.log("Decrementing " + this.inProgress + " for interestingLocations: " + JSON.stringify(interestingLocations));
            this.results = this.results.concat(interestingLocations);
            this.inProgress--;
            if (this.inProgress === 0) {
              response.write(JSON.stringify(this.results));
              response.end();
            }
          }
        };
        for (i = 0, len = incomingFiles.length; i < len; i++) {
          if (endsWith(incomingFiles[i].path, ".htm")
              || endsWith(incomingFiles[i].path, ".html")) {
            apricotLib.Apricot.open(incomingFiles[i].path, function(fileInfo) {
              return function(error, doc) {
                if (error) {
                  //console.log("Got this error parsing file " + fileInfo.path + ": " + error);
                  resultsCollector.fillResult([]);
                } else {
                  doc.find("span[itemscope][itemtype=\"http://historical-data.org/HistoricalPerson.html\"]");
                  var matches = [];
                  doc.each(function(element) {
                    // check for the first 'meta' tag that matches anyone in my ancestry
                    var foundPersonId = null;
                    metas = element.getElementsByTagName("meta");
                    for (var j = 0; j < metas.length; j++) {
                      if (!foundPersonId) {
                        if (metas[j].getAttribute("itemprop").length > 0
                            && metas[j].getAttribute("content").length > 0) {
                          metaId = metas[j].getAttribute("itemprop") + "/" + metas[j].getAttribute("content");
                          var pastAlpha = false; // to shortcut more searching if we're past where the ID would be in our search of this sorted array
                          allIds.forEach(function(value, index) {
                            if (!foundPersonId /*&& !pastAlpha -- turned off due to a bug in royal.ged w/ INDI 2 */) {
                              var comparison = metaId.localeCompare(value);
                              if (comparison == 0) {
                                foundPersonId = metaId;
                              } else if (comparison > 0) {
                                pastAlpha = true;
                              }
                            }
                          });
                        }
                      }
                    }
                    if (foundPersonId) {
                      fileInfo.context = element.textContent; // textContent omits tag elements; text includes it all
                      fileInfo.position = element.id;
                      matches.push(fileInfo);
                    }
                  });
                  //if (matches.length>0) { console.log("Parsed through " + fileInfo.path + " and found: " + matches + ", eg. " + matches[0].text + " " + matches[0].textContent); }
                  resultsCollector.fillResult(matches);
                }
              };
            }(incomingFiles[i]));
          } else {
            resultsCollector.fillResult([]);
          }
        }
      }
    });
  } else {
    response.writeHead(400, {"Content-Type": "text/plain"});  
    response.write("400 Bad Request (not a POST)\n");
    response.end(); 
  }
}

server = http.createServer(function (req, resp) {
  resp.writeHead(200, {'Content-Type': 'text/plain'});
  
  if (req.url === '/get_followers') {
    // This is just from the node sample.
    getFollowers(req, resp);
  } else if (req.url === '/get_repos') {
    // This is just from the node sample.
    getRepos(req, resp);
  } else if (req.url.indexOf('/get_repo_watchers') === 0) {
    // This is just from the node sample.
    getRepoWatchers(req, resp);
  } else if (req.url.indexOf('/get_profile') === 0) {
    // This is just from the node sample.
    getProfile(req, resp);

  } else if (req.url.indexOf('/version') === 0) {
    // coordinate this version with the one in tiapp.xml
    resp.write(JSON.stringify("0.10")); // this is a String mainly to keep consistent with other version numbers
    resp.end();

  } else if (req.url === '/load-script/jquery') {
    serveScript('js/jquery-1.5.1.min.js', resp);

  } else if (req.url.indexOf('/load-script/for-histories') === 0) { // checking the prefix because jQuery adds an _ parameter
    serveScript('js-for-histories.js', resp);

  } else if (req.url.indexOf('/check_database') === 0) {
    // curl http://127.0.0.1:1338/check_database -d "ancestryIds=2&incomingFiles=[{'path':'/Users/tlarson/Dropbox/Multimedia from Janell/Baker Austin-Fanny','repoNum':0,'diffNum':2}/]"
    try {
      checkDatabase(req, resp);
    } catch (e) {
      resp.writeHead(500, {"Content-Type": "text/plain"});  
      resp.write("500 Server Error: " + e + "\n");  
      resp.end();
    }
    
  } else {
    resp.writeHead(404, {"Content-Type": "text/plain"});  
    resp.write("404 Not Found\n");  
    resp.end(); 
  }
}).listen(1338, "127.0.0.1");

console.log('NodeJS server now running at http://127.0.0.1:1338/');
