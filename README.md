All In The P2P / P2P-Docs
==============

User Stories
------------

A "-" means it's not done yet.

  * Repositories
    * CRUD
    * - allow individual files to be their own repository
  * - Doc Alerts: notify when there's new content
  * Doc Changes (external?): display the new content
  * - Doc Resolution: accept or reject the changes in my own versions
    * - then copy my version into any shared areas
  * - Search: search for items of interest
  * - Notifications: notify of changes, via desktop and via preferred media


Test Details:

* Register & unregister repos: add/remove funny names; add/remove duplicate names
* Create different repository configurations
    * empty ones
    * - combinations: empty repo, repo w/ files, repo w/ dirs, repo w/ files & dirs, recursively
    * - many repositories (eg. crashes on repositories page with 25 repos; see sample_repos test)
    * - ones with thousands of dirs/files
    * - repo changes, mirroring the tests in SettingsTest
* - test with blank incoming setting
* Automated test: ruby Resources/test/ruby/settings.rb (and check that there is no output)
* Test many repos in app:
    * run command: ruby Resources/test/ruby/settings_repositories.rb
    * edit application.properties (Mac: ~/Library/Application Support/Titanium/appdata/info.familyhistories.p2pdocs)
        * comment out the setting "settings-dir" with the prefix of "//"
        * add a line with a pointer to your app source path ending with "build/sample-repos", eg:
      
        settings-dir: /Users/tlarson/dev/p2pdocs/p2pdocs8/build/sample-repos

    * run app and test
        * If you click on a repo name (eg. "test 0"), then mark the checkbox, then click "Accept", it should disappear (rather than throw some JavaScript exception)
        * If you click on "Configure", then click "change" next to "Outgoing", then select a directory and hit "Open", it should set it (rather than crash)


Specific Plans
-----

In priority order:

 * Doc Changes
 * fix unknown crashes on repositories page when accepting a change too many (100) repos
   ... though if you go to repo create screen first it just stops on javascript at mark_reviewed on index.html
 * fix unknown crashes on repeated clicks back-and-forth from main to configure
 * fix unknown crashes on search, eg "Robert"
 * fix unknown crashes on deleting a repo (though it works if you got to create screen first)
 * default to versioned files, but allow to overwrite (both incoming and outgoing)
 * default to keep old reviewed versions, but allow deletion
 * default to keep old outgoing versions, but allow deletion
 * allow to make outgoing same location as incoming
 * when creating/editing repo: warn if outbound w/o home, no home under incoming, no out under home (small)
 * repository choices (hints for choosing P2P folders; small x) (medium)
 * make this a background service... with notification hooks? (medium)
 * make the configuration a menu (medium)
 * transitions between screens (small)
 * documentation and/or help (medium)
   * FAQ: on repo crashes, go to add a repo and cancel and then it works
 * search through repository files (not just Jean's file)
 * program auto-update (medium)
 * use repo ID numbers everywhere (instead of names)
 * fix the new-repo transition to slide whole screen (not half)
 * make a consistent styling for the whole app
 * rework graphics with repo pic
   * http://www.clker.com/clipart-vertical-file-cabinet.html
   * http://search.coolclips.com/media/?D=busi1110


Finished
--------


Externalities
-------------

 * JavaScript libraries: see Resources/js files
 * icons for home-interact-people from dellustrations.com: see http://www.smashingmagazine.com/2008/10/01/dellipack-2-a-free-icon-set/
