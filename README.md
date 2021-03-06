P2P Document Bus
================

Use this together with the file-sharing program of your choice to
share files in more of a publish/subscribe model (and maintain your
own changes separately), keeping your own organization of files.

Get the application on various platforms here: http://p2pdocs.familyhistories.info/download

See general updates on this project here: http://p2pdocs.familyhistories.info

Currently the application lets you monitor the files that are changing,
and search through your copies for certain text.

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
clients.  So this project aims to move files to the right locations;
it detects changes and prompts the user to review the changes and pull
or push them to the right places (incrementing versions in the file
names if necessary).

First, you'll need to know where your shared files are stored.  Here
are some common locations:

  * In Dropbox, click on the Dropbox icon and "Open Dropbox Folder".

  * In Vuze, look for a "Vuze Downloads" folder under "Documents".

  * In AeroFS, click on the AeroFS icon and look at "Browse Library".

  * In uTorrent, look for a "uTorrent Downloads" folder under "Documents".

  * In AllianceP2P, go to "View" then "My share" then "Shared files".


To start, configure it with those folders:

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
minutes (or even hours with torrents) after you make your changes.
(This may change as our P2P technologies improve... I hope the need
for this program goes away because these features get incorporated
into mainstream P2P clients.)

User Stories
------------

A "-" means it's not done yet.

  * Libraries (AKA Repositories)
    * - manage folders/friends from the sharing tools
    * - allow individual files to be their own repository
    * allow outgoing to the same place as incoming
  * Search: search for items of interest
    * - make this a plugin, ancillary to the file tracking
  * Doc Changes (external?): display the new content
    * - set up trust for certain incoming files, to shortcut to my copy
    * - Notifications: notify of changes, via desktop and/or preferred media
  * - Doc Resolution: accept or reject the changes in my own versions
    * - then copy my version into any shared areas
  * - Work as a plugin/client for some of the main file-sharing
      systems (eg. Vuze, Dropbox, Singly), to hide some of the ugliness of
      maintenance and duplication that this tool imposes


Tests:

* Automated test: ruby Resources/test/ruby/settings.rb (and check that there is no output)
* Try things on the test page: click on the gear at the top right (may require a 'Cancel' on first screen),
  scroll to the bottom, move the mouse to the right, then down under the last text on the screen until the cursor shows something clickable, then click, and select a test
* Create different repository configurations (some covered by the previous item):
    * empty ones
    * add/remove funny names; add/remove duplicate names
    * - combinations: empty repo, repo w/ files, repo w/ dirs, repo w/ files & dirs, recursively
    * - many repositories
    * - ones with thousands of dirs/files
    * - repo changes, mirroring the tests in SettingsTest
    * edit, delete


Development Setup:

* To create:
  * Create a new Titanium desktop app, with Ruby.  Then close Titanium.
  * Copy all the files from a git repository into it, including .git.
  * Reopen Titanium and play.
* To disable the app calling Appcelerator (for tracking), add this in tiapp.xml inside ti:app element:
  <analytics>false</analytics>
* To enable/disable family history features (eg. identifying yourself
  inside genealogy files), play with this flag in index.html:
  include-family-history-features
* When updating versions, make sure to change in both places (UI that modifies tiapp.xml, and nodeApp.js) and update versions.html on website

Bookmarklet to add script to a page (when this app is running):

    javascript:  var scriptElem=document.createElement("script");  scriptElem.setAttribute("type","text/javascript");  scriptElem.setAttribute("src","http://localhost:1338/load-script/jquery");  document.body.appendChild(scriptElem); setTimeout(function(){$.getScript("http://localhost:1338/load-script/for-histories")}, 500);  void(0);



To-Do User Story Details, In Priority Order
-------------------------------------

 * sometimes accepted item doesn't disappear... first time after start?
 * browser add-on: pop-up to explore person elsewhere, eg. in FamilySearch, in Gramps, relationship to self
    * show error if it fails to load
 * allow indication (checkbox?) to mark dirs/files as ignored forever (logic already written) [medium] [middle]
 * allow to open the file location for any file (or repo?) [small] [middle]
 * look for Dropbox/AeroFS/other sharing folders and recommend for new repository
 * option to auto-copy from incoming to home
 * look for genealogy (eg. .GED) files and recommend for new identity
 * search for stories (locally)
   * search for data within tree, ie. restricted sets of files rather than all
     * if match has children, suggest browsing down to find closest ancestor
   * terms
   * semantic data
 * import "tree-of-interest"
   * add spinner, for waiting while a new identity is searched and while it's added with full tree
   * find matching people in existing GEDCOM file
     * add search ancestry to DB
       * correlate FAMS and FAMC if FAM records don't exist (Does that happen?)
     * show birthdate [tiny]
     * preemptively parse through file when selected, to determine if it's a valid GEDCOM file (ie. if our parser works on it)
   * accept other types of repositories: ancestry.com, familysearch.org, git-ged
   * allow to remove(/disable?) identities; will require removing related application.properties ancestryIds, and probably reindexing all ancestryIds and doc references
   * optimize the size of ancestryIds, eg. by recording the file/URL only once for each set of ancestors
 * allow selection of outgoing files to publish [small]
 * bug: when I removed one version of Dad's journal, it didn't show as a change to push (intentional? until later?)
 * allow copying/merging to my own copy (via link?)
 * show repositories in a way that focuses on people/groups/circles with whom we're sharing the files (maybe first we detect sharing program and offer help)
 * for outgoing changes: show diffs, maybe links to repos and sharing circle [small]
 * error in versioned-repo test environment when we mark files as reviewed... because it's removing the previous_path, where it should be replacing it (and why am I removing again?)
 * fix error marking reviewed the files starting with "."
 * fix error loading properties when royal.ged INDI 1 is used as an identity
 * remove the static Ruby class variable that's not static (in settings.rb)
 * default to versioned files, but allow to overwrite (both incoming and outgoing)
 * default to keep old reviewed versions, but allow deletion
 * default to keep old outgoing versions, but allow deletion
 * on searches, notify the user for skipped files
 * allow to make outgoing same location as incoming
 * when creating/editing repo: warn if outbound w/o home, no home under incoming, no out under home [small]
 * allow choice to copy an incoming file all the way to the home location(?)
 * repository choices (hints for choosing P2P folders; small x) [medium]
 * make this a background service... with notification hooks? [medium]
 * make the configuration a menu [medium]
 * transitions between screens [small]
 * documentation and/or help [medium]
 * program auto-update [medium]
 * show an appropriate error if two apps are running... or something to avoid clashing node processes [small]
 * change links with JavaScript actions (eg. inFolderChooser in repositories.html) from "a" to "span" to avoid page jumps when clicking [small]
 * mark the repo as well when found an ancestor's record [small]
 * use repo ID numbers everywhere (instead of names)
 * fix the new-repo transition to slide whole screen (not half)
 * make a consistent styling for the whole app
 * search - only searchable files (exclude images)
 * search - HTML anchors: not just "a name=" strings, and not just single- and double-quotes
 * search - case-insensitive
 * use a true change-control system to store file histories (eg. git)
 * move ancestry and ancestryIds from application.properties to settings
 * change format of settings from YAML to JSON(?)[small]
 * maybe we shouldn't save copies of files without extensions by default (by changing "!ext_match" conditional in Updates.cp_r_maybe_without_history)
 * rework graphics with repo pic
   * http://www.clker.com/clipart-vertical-file-cabinet.html
   * http://search.coolclips.com/media/?D=busi1110


Externalities
-------------

 * Thanks to Appcelerator appcelerator.com for the Titanium desktop framework (and for open-sourcing it!), and the TideSDK tidesdk.org people for continuing the project.
 * JavaScript libraries: see files in Resources/js directory
 * icons for home-interact-people by Wendell Fernandes at dellustrations.com; see http://www.smashingmagazine.com/2008/10/01/dellipack-2-a-free-icon-set/
   (These were modified to grey with Gimp, by desaturating and then increasing brightness & contrast.)
 * gear-raw.32.png by Icon Shock; see http://www.gettyicons.com/free-icon/101/programmers-pack-icon-set/free-settings-icon-png/
 * binoculars-raw.32.png by DaPino; see http://www.iconarchive.com/show/fishing-equipment-icons-by-dapino/binoculars-icon.html
 * rss-feed-raw.jpg by Carl Newton: http://carlnewton.deviantart.com/art/RSS-Icon-37808083 via http://wonderful-tricks.blogspot.com/2009/05/collection-of-free-rss-feed-icons.html
 * rss-feed-raw2.jpg by burnsflipper: http://burnsflipper.deviantart.com/art/MyCircles-RSS-Icon-40357449 via http://wonderful-tricks.blogspot.com/2009/05/collection-of-free-rss-feed-icons.html
 * anim-flower.gif by ajaxload.info
 * anim-bars-small.gif by ajaxload.info and then edited for size and timing with Gimp
 * button-green-solid.16.png by OCAL: http://www.clker.com/clipart-2590.html
 * button-red-x and edit-yellow images from Brant Snow

Other Commentary
----------------

 * Dear cyberchaos05 (http://cyberchaos05.deviantart.com/): I would have used your magnifying glass, but you don't allow derivatives.  http://www.iconspedia.com/icon/search-10368.html
 