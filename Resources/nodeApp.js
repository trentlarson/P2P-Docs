var server,
  http      = require('http'),
  sys       = require("sys"),
  qsLib     = require('querystring');
  urlLib    = require("url"),
  // note the pure-JS mysql client: https://github.com/felixge/node-mysql, listed here http://nodejs.org/docs/latest/api/appendix_1.html
  sqliteLib = require("sqlite-osx"),
  GitHubApi = require("github").GitHubApi,
  github    = new GitHubApi(true),
  githubUserOfConcern = 'appcelerator';

var ohNo = function(req, resp) {
  resp.writeHead(500, {"Content-Type": "text/plain"});  
    resp.write(err + "\n");  
    resp.close();
    return;
};
  
var getFollowers = function(req, resp) {
  github.getUserApi().getFollowers(githubUserOfConcern, function(err, followers) {
      if(err) { ohNo(); }
      
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
      if(err) { ohNo(); }

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
        if(err) { ohNo(); }

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
        if(err) { ohNo(); }
        
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

/**
 * request should have two parameters, 'sqliteFile' is the genealogy DB file, and 'incomingFiles' is a JSON-stringified array of file names to detect
 */
var checkDatabase = function(request, response) {
  if (request.method == 'POST') {
    var body = '';
    request.on('data', function (data) {
      body += data;
    });
    request.on('end', function () {
      var postData = qsLib.parse(body);
      var db = new sqliteLib.Database();
      db.open(postData['sqliteFile'], function(error) {
        if (error) { throw "Error opening genealogy DB: " + error; }
        db.prepare("SELECT id, father_id, mother_id, ext_ids FROM genealogy", function(error, statement) {
          if (error) { throw "Error selecting from genealogy: " + error; }
          statement.fetchAll(function (error, rows) {
            if (error) { throw "Error fetching from genealogy: " + error; }
            //console.log("Yep, got your stuff " + rows[0].id + " " + rows[0].father_id + " " + rows[0].mother_id + " " + rows[0].ext_ids);
            var allIds = [];
            for (var i = rows.length - 1; i >= 0; i--) {
              allIds = allIds.concat(JSON.parse(rows[i].ext_ids));
            }
            allIds.sort();
            //console.log("Searching for these IDs: " + JSON.stringify(allIds));
            // an array of file names
            incomingFiles = JSON.parse(postData['incomingFiles']);
            //console.log(" ... in these files: " + JSON.stringify(incomingFiles));
            // an array of objects with: file, context, position (similar to main in search.rb)
            var result = [{"file":incomingFiles[0], "context":"... had a little lamb...", "position":null}];
            response.write(JSON.stringify(result));
            response.end();
            statement.finalize(function(error) {
              if (error) { throw "Error finalizing genealogy statement: " + error; }
              db.close(function(error) {
                if (error) { throw "Error closing genealogy DB: " + error; }
              });
            });
          });
        });
      });
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

  } else if (req.url.indexOf('/check_database') === 0) {
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
