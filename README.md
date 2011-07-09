All In The P2P / P2PDOCs
==============

User Stories
------------

 * Repositories: CRUD for repositories
 * Doc Alerts: notify when there's new content
 * Doc Changes (external?): display the new content
 * Doc Resolution: accept or reject the changes in my own versions
 * Search (external?): search for items of interest
 * Notifications: notify of changes, via desktop and via preferred media

To do before next release:

 * repository choices (dir choosing: browse, hints; small x)
 * hook up real search for content
 * program auto-update
 * make this a background service... with notification hooks?
 * documentation and/or help
 * any failing tests (below)

Current task:

 * fix the 'view' link showing after directories (should only show after files)

Tests

 * Register & unregister repos: add/remove funny names; add/remove duplicate names
 * Create different repository configurations: empty ones, ones with thousands of dirs/files
