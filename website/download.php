<?php include_once('template/header.html'); ?>
    <div class="title">Third-Party Plugins</div>
    <p>All third-party plugins are available on GitHub under the "extra" 
    section. <a href="https://github.com/DouglasSherk/Apollo-RP/tree/master/extra">Direct link</a>.</p>
    <div class="title"><a href="https://github.com/downloads/DouglasSherk/Apollo-RP/ApolloRP_v1.3.zip">Apollo RP v1.3 (Sep 19, 2010)</a></div>
    <ul>
    <li>Fixed jail mod not saving at correct intervals.</li>
    <li>Corrected ordering of hunger mod in plugins-arp.ini.</li>
    <li>Fixed cuff/speed glitch.</li>
    <li>Added arp_delete (deletes all tables), arp_query (allows running queries in-game), arp_backup (allows backup of database) and arp_restore (restores a backup) commands which can be run only from the server console to ARP_Config.</li>
    <li>Fixed HUD not rendering while a player is dead.</li>
    <li>Fixed NPC zones requiring a precache.</li>
    <li>Added arp_getinfo command to ARP_Config which gets the current player's origin, angles, job rights and access flags.</li>
    <li>Fixed % commands (i.e. "%c", "%d", etc.) in chat throwing garbage.</li>
    <li>Removed potentially unstable touch code, which gets called when a player touches a door (it was supposed to open it if they had permission, but it never worked).</li>
    <li>Fixed GetGameDescription crashing the server (removed it).</li>
    <li>Added zone HUD info, which tells the user where they are.</li>
    <li>Added support for running on any HL mod; only CS, TS, and partially TFC are supported officially (although it will run with diminished functionality on other mods).</li>
    <li>Changed SQLite to be the default SQL setting.</li>
    <li>All models and sounds have been moved into their appropriate /arp/ directories (from random places like /harburp/, etc.).</li>
    <li>Missing models will no longer immediately crash ARP.</li>
    <li>Missing a config directory will no longer crash ARP.</li>
    <li>Having no SQL connection will no longer crash ARP (although it will have severely reduced functionality).</li>
    <li>Having an error in an existing SQL connection will no longer crash ARP (but it will still generate an error in logs).</li>
    <li>Moved all functionality of ARP_Weapons.amxx into ARP_TS.amxx, which is the TS compatibility plugin.</li>
    <li>Added speed API.</li>
    <li>Fixed data layer not saving due to memory fragmentation when iterating through all open classes.</li>
    <li>Fixed data layer destroying data mistakenly when ARP_ClassSave() is called and the plugin using the class is the only one that has it open.</li>
    <li>Fixed data layer failing to free classes that have been marked as closed due to memory fragmentation.</li>
    <li>Added ARP_ClassDestroy() native, which deletes a class and all records in it.</li>
    <li>Fixed data layer failing to delete keys that were stored anywhere other than the arp_data table.</li>
    <li>Added SQL injection protection to data layer SQL functions (this closed security holes, but none were actually exploitable).</li>
    <li>Fixed ARP_ClientPrint() not being treated like all other HUD calls (no HUD_Render call).</li>
    <li>Added ARP_PropertyClearAccess() native which destroys all keys on a property.</li>
    <li>Fixed overflow in ARP_FindItemId() native causing memory overwrites in other plugins.</li>
    <li>Added zone plugin, which tracks the user's current location.</li>
    </ul>
    <div class="title"><a href="https://github.com/downloads/DouglasSherk/Apollo-RP/ApolloRP_v1.2.zip">Apollo RP v1.2 (May 8, 2009)</a></div>
    <ul>
    <li>Applied new offsets for weapons and ammo (thanks Spekktram).</li>
    <li>Added some cvars to arp.cfg - just so everyone knows, there are a number of cvars which have existed for a while but aren't documented, so you can add them to your config file without v1.2; to find them, look in ARP_Core.sma under the "register_cvar" section.</li>
    <li>Fixed cops being able to jail other cops.</li>
    <li>Fixed cops being able to jail players while spectating.</li>
    <li>Fixed players receiving salaries while spectating.</li>
    <li>Updated HUD plugin to display a message to the user indicating that their account is being loaded if it isn't ready yet.</li>
    <li>Merged OOC sound from Notifications plugin into TalkArea.</li>
    <li>Added an optional (cvar: arp_colorchat) white name when messages made by you are printed out in TalkArea (I wanted to add more like red and blue for actions or phone calls but the only one TS allows is white).</li>
    <li>Added support for items being created directly into maps as entities.</li>
    <li>Fixed users being able to say "%c", "%i", "%d", etc. and they can now say them without causing errors in the console and everyone seeing the message.</li>
    <li>Cleaned up TalkArea commands so that they keep more in-sync together (i.e. periods, case switching, etc.).</li>
    <li>Fixed NPCs not allowing players to buy the correct items when on different pages.</li>
    <li>Fixed !Heal command on doctor NPCs (new command is "heal" and it is like "sell").</li>
    <li>Fixed property purchasing displaying the wrong property.</li>
    <li>Fixed arp_fire command.</li>
    <li>Added /unemploy command.</li>
    <li>Fixed flashlight item decaying too quickly.</li>
    <li>Fixed server console being spammed with "// ooc" commands; also it will now log these properly rather than just printing them to the console.</li>
    <li>Completely rewrote cell phone and NPC menus to be more stylish and function properly.</li>
    <li>Completely revamped the inventory screen to be more stylish and functional.</li>
    <li>Fixed cell phone page not moving.</li>
    <li>Fixed players losing their jobs if there is another job which contains the string that their job is (i.e. the "Chief of Police" will lose his job if there exists another job called "Deputy Chief of Police").</li>
    <li>Fixed entering message by default formatting weird, usually as "[ARP] Type ^" as opposed to "[ARP] Type 'arp_help' to get started."</li>
    <li>Added "Debit Card" item, which allows players to withdraw money anywhere if they have one.</li>
    <li>Job admins can now create new jobs.</li>
    <li>Added an arp_deletejob command which admins and job admins can use.</li>
    <li>Removed ARP_BCompat.amxx from the default activated plugins.</li>
    <li>Fixed rob alarms not registering properly.</li>
    <li>Fixed admins being able to use arp_config while the server is running & connected.</li>
    <li>Completely rewrote hunger mod to be more user-friendly and expansive.</li>
    <li>Removed rope and tape items until they can be done properly.</li> 
    <li>Added support for SQLite which forces CleverQuery to run in non-threaded only mode (great performance improvement); this also allows servers without access to a MySQL database to run a server as SQLite is included as part of AMXX.</li>
    <li>Added call for player's info being all loaded (Player_Ready event) and a native to check their ready status (ARP_PlayerReady).</li>
    <li>Fixed items being lost if their names contain any illegal characters.</li>
    <li>Fixed the Property_Buy event sending the wrong property index.</li>
    <li>Fixed HUD_AddItem not being called for arp_printmode 1.</li>
    <li>Added Chat_Message event, which is called whenever a player says something (do NOT use this in place of RegisterChat/AddChat); it is a filter/catch more than a block.</li>
    <li>Improved jail mod saving algorithm (it now accounts properly for players leaving between the time their class begins loading and it actually finishes).</li>
    <li>Added Player_HealBegin and Player_HealEnd events to catch/block when a doctor NPC heals a player.</li>
    <li>Added ARP_MedNum() stock to ARP_Jobs.inc, which returns the number of medical users on the server.</li>
    <li>Added ARP_IsAdmin() stock to ARP_Jobs.inc, which returns whether or not a player is an admin.</li>
    <li>Added ARP_IsJobAdmin() stock to ARP_Jobs.inc, which returns whether or not a player is a job admin.</li>
    <li>Added ARP_DeleteJob() native to ARP_Jobs.inc, which deletes a job by job id and sets anyone who has that job to unemployed.</li>
    </ul> 
    <div class="title"><a href="https://github.com/downloads/DouglasSherk/Apollo-RP/ApolloRP_v1.1.zip">Apollo RP v1.1 (Feb 10, 2009)</a></div>
    <ul>
    <li>Fixed arp_createitems, arp_createmoney and similar commands displaying invalid results.</li>
    <li>Fixed first time joiners losing their account.</li>
    <li>Fixed "%c" spam in chat.</li>
    <li>Corrected format of SQL batch files so they can be run properly without the config plugin.</li>
    <li>Added /911 command for players.</li>
    <li>Added sound to /com command (similar to in Radio Mod).</li>
    <li>Made cops unable to tazer other cops.</li>
    <li>Fixed jailmod jailing people randomly.</li> 
    <li>Enhanced saving algorithm.</li>
    <li>Fixed stopped status not updating properly in jailmod when the core shuts down.</li>
    <li>Lowered check bounds for NPCs so they don't get stuck in walls/ceilings</li>
    <li>Enhanced CleverQuery engine to run non-threaded queries on map changes to prevent data loss.</li>
    <li>Removed ARP_PrecacheModel and ARP_PrecacheSound (they were never really there anyway).</li>
    <li>Users will no longer be saved if they aren't loaded properly or their steam ID doesn't work; they will also be notified that there was a problem.</li>
    <li>Fixed properties randomly switching or being deleted.</li>
    <li>Servers can now operate without an SQL connection as if they are connected, although nothing is saved and a notification is displayed to all users that the server is not properly set up.</li>
    <li>Errors have been made more informative: SQL query errors will display the exact problem that occurred and will not cause a cascade failure in the whole ARP structure anymore.</li>
    <li>Fixed massive security hole which will not be discussed more until v1.1 is released.</li> 
    </ul>
    <div class="title"><a href="https://github.com/downloads/DouglasSherk/Apollo-RP/ApolloRP_v1.0.zip">Apollo RP v1.0 (Aug 27, 2008)</a></div>
    <ul>
      <li>Initial release.</li>
    </ul>
<?php include_once('template/footer.html'); ?>
