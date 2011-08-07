All In The P2P / P2P-Docs
==============

User Stories
------------

A "-" means it's not done yet.

 * Repositories
    * CRUD
    * - numbers for repo IDs
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


Plans
-----

In priority order:

 * Doc Changes
 * fix crashes on repositories page with too many (21+) repos
 * fix crashes on repeated clicks back-and-forth from main to configure
 * fix crashes on search, eg "Robert"
 * repository choices (hints for choosing P2P folders; small x)
 * make this a background service... with notification hooks?
 * make the configuration a menu
 * documentation and/or help
 * search through repository files (not just Jean's file)
 * program auto-update


Finished
--------

