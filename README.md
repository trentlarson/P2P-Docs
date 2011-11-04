P2P-Docs
==============

Use this together with the file-sharing program of your choice to
share files in more of a publish/subscribe model (and maintain your
own changes separately), keeping your own organization of files.

Download packages for Windows, Mac, and Linux here:
http://api.appcelerator.net/p/pages/app_page?token=04txtaw6

Let's say, for example, you're working on some historical
documentation, and you subscribe to other people's feeds where they
share their updates... and you may insert some of their info into your
copies, but not all of it: maybe you only want information that's
relevant (eg. to your family), or maybe you only fully trust
information from certain people.  Anyway, you may want to know when
they make changes, or you may want to apply some of their changes to
your copies, or you may want to push your changes out to others.  Or
maybe you want it all.  (You can see more user stories at
http://familyhistories.info .)

Hopefully this will help.  Current file-sharing programs have
shortcomings for projects with files with similar (but not exactly the
same) histories: they typically synchronize all changes, and they
publish and subscribe to the (torrent) file and don't do updates.  The
ideal implementation would be a plugin in each content app, one that
publishes or consumes the info to/from the right locations;
second-best would be to build this publishing/consuming into the P2P
clients.  So P2P-Docs aims to move files to the right locations; it
detects changes and prompts the user to review the changes and pull or
push them to the right places (incrementing versions in the file names
if necessary).

First, you'll need to know where your shared files are stored.  Here
are some common locations:

  * In Dropbox, click on the Dropbox icon and "Open Dropbox Folder".

  * In Vuze, look for a "Vuze Downloads" folder under "Documents".

  * In AeroFS, click on the AeroFS icon and look at "Browse Library".

  * In uTorrent, lood for a "uTorrent Downloads" folder under "Documents".

  * In AllianceP2P, go to "View" then "My share" then "Shared files".


Start P2P-Docs and configure it with those folders:

 * If you're subscribing to someone's files, then make that folder the
   "incoming" folder (eg. a Dropbox or "Vuze Downloads" folder).

 * If you've got your own copy of the files (maybe changed) in another
   place, then make that folder the "home" folder.

 * If you're publishing files, then make that folder the "outgoing"
   folder (eg. a Dropbox or Vuze share folder).

After that, whenever there is a change to any of these files, this
will show you what has changed and prompt you to move those files to
the right locations, with new version numbers if necessary, whether
you've reviewed the incoming change (ie. you want to "mark it as
read") or you want to publish your outgoing change.  Note that this
has a rudimentary search for text and HTML files; this is part of a
larger effort at http://familyhistories.info to create great tools for
sharing and searching family histories.

See the User Stories below to see what features are finished and what are planned.

BTW, there are projects where this approach will not work well.  Don't
try it if you need real-time sharing; most updates won't happen for
hours (or days?) after you make your changes.  (This may change as our
P2P technologies improve... I hope the need for this program goes away
because these features get incorporated into mainstream P2P clients.)

User Stories
------------

A "-" means it's not done yet.

  * Libraries (AKA Repositories)
    * - manage folders/friends from the sharing tools
    * - allow individual files to be their own repository
    * - allow outgoing to the same place as incoming
  * - Doc Alerts: notify when there's new content
  * Doc Changes (external?): display the new content
    * - set up trust for certain incoming files, to shortcut to my copy
  * - Doc Resolution: accept or reject the changes in my own versions
    * - then copy my version into any shared areas
  * Search: search for items of interest
  * - Notifications: notify of changes, via desktop and via preferred media
  * - Use a true file-control system underneath (eg. git)
  * - Work as a plugin/client for some of the main file-sharing
      systems (eg. Vuze, Dropbox, Singly), to hide some of the ugliness of
      maintenance and duplication that this tool imposes


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

    * run app and test on the 'feed' screen
        * If you click on a repo name (eg. "test 0"), then mark the checkbox, then click "Accept Changes", it should disappear (rather than throw some JavaScript exception)
        * If you click on "Configure" (gear icon), then click "change" next to "Outgoing", then select a directory and hit "Open", it should set it (rather than crash)


Details, By Priority
--------------------

 * Doc Changes
 * fix crashes on repo outgoing dir changes
 * fix unknown crashes on repositories page when accepting a change too many (100) repos
   ... though if you go to repo create screen first it just stops on javascript at mark_reviewed on index.html
 * default to versioned files, but allow to overwrite (both incoming and outgoing)
 * default to keep old reviewed versions, but allow deletion
 * default to keep old outgoing versions, but allow deletion
 * on searches, notify the user for skipped files
 * allow to make outgoing same location as incoming
 * when creating/editing repo: warn if outbound w/o home, no home under incoming, no out under home (small)
 * repository choices (hints for choosing P2P folders; small x) (medium)
 * make this a background service... with notification hooks? (medium)
 * make the configuration a menu (medium)
 * transitions between screens (small)
 * documentation and/or help (medium)
   * FAQ: on repo crashes, go to add a repo and cancel and then it works
 * program auto-update (medium)
 * use repo ID numbers everywhere (instead of names)
 * fix the new-repo transition to slide whole screen (not half)
 * make a consistent styling for the whole app
 * search - HTML anchors: not just "a name=" strings, and not just single- and double-quotes
 * rework graphics with repo pic
   * http://www.clker.com/clipart-vertical-file-cabinet.html
   * http://search.coolclips.com/media/?D=busi1110


Externalities
-------------

 * JavaScript libraries: see files in Resources/js directory
 * icons for home-interact-people by Wendell Fernandes at dellustrations.com; see http://www.smashingmagazine.com/2008/10/01/dellipack-2-a-free-icon-set/
 * gear-raw.32.png by Icon Shock; see http://www.gettyicons.com/free-icon/101/programmers-pack-icon-set/free-settings-icon-png/
 * binoculars-raw.32.png by DaPino; see http://www.iconarchive.com/show/fishing-equipment-icons-by-dapino/binoculars-icon.html
 * rss-feed-raw.jpg by Carl Newton: http://carlnewton.deviantart.com/art/RSS-Icon-37808083 via http://wonderful-tricks.blogspot.com/2009/05/collection-of-free-rss-feed-icons.html
 * rss-feed-raw2.jpg by burnsflipper: http://burnsflipper.deviantart.com/art/MyCircles-RSS-Icon-40357449 via http://wonderful-tricks.blogspot.com/2009/05/collection-of-free-rss-feed-icons.html

Other Commentary
----------------

 * Dear cyberchaos05 (http://cyberchaos05.deviantart.com/): I would have used your magnifying glass, but you don't allow derivatives.  http://www.iconspedia.com/icon/search-10368.html
 