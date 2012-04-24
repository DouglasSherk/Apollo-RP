<?php include_once('template/header.html'); ?>
    <div class="title">Requirements</div>
    <p>Besides obviously needing to run Half-Life or one of its mods, you must 
    have the following:</p>
    <ul>
      <li>Metamod v1.19 (p32 optional) or newer.</li>
      <li>AMX Mod X v1.8.1 or higher. If you are using Counter-Strike, you must 
      install the Counter-Strike AMX Mod X package. This also follows for The 
      Specialists.</li>
      <li>MySQL 5.0 or newer (MySQL 5.1 recommended) OR SQLite (though this is 
      included in AMX Mod X).</li>
      <li>At least 800 MHz CPU and 512 MB of RAM.</li>
      <li>High-speed internet connection (at least 128 KB/s upstream per 
      player).</li>
    </ul>
    <div class="title">Installation</div>
    <div class="subtitle">Using MySQL</div>
    <p>MySQL is the standard SQL distro used with Apollo RP. It is designed to 
    handle very large databases and allow connections from multiple servers.</p>
    <p>To install Apollo RP using MySQL, complete the following steps:</p>
    <ol>
      <li>Copy the package into the TS directory such that all files are in 
      their correct locations (ex. files inside of ./plugins/ ended up in the 
      addons/amxmodx/plugins/ directory).</li>
      <li>Ensure that you are an admin using the AMX Mod X users.ini file or 
      your SQL database.</li>
      <li>Change the map/reload the server.</li>
      <li>Type "arp_config" in your console.</li>
      <li>Press 2, then fill in all the fields such that they reflect your 
      database settings.</li>
      <li>Change the map/reload the server.</li>
      <li>Press 1, or "Add First ARP Admin".</li>
      <li>Type "arp_config" in your console again.</li>
      <li>Press 3, or "Load Map SQL Database" and wait for it to load all 
      entries.</li>
      <li>Change the map/reload the server. You should be ready to RP!</li>
    </ol>
    <div class="subtitle">Using SQLite</div>
    <p>SQLite is an SQL distro which is designed to be compact, fast and easy 
    to integrate. It is built into AMXX and is easy to use. Apollo RP mostly 
    supports it, but as of yet, gunspawns do not work with it. SQLite has no 
    concept of networking and can only be used on the host machine.</p>
    <ol>
      <li>Copy the package into the TS directory such that all files are in 
      their correct locations (ex. files inside of ./plugins/ ended up in the 
      addons/amxmodx/plugins/ directory).</li>
      <li>Ensure that you are an admin using the AMX Mod X users.ini file or 
      your SQL database.</li>
      <li>Open your arp.ini and change the field "arp_sql_type" from "mysql" to 
      "sqlite".</li>
      <li>Open your modules.ini and remove the comment before ";sqlite" so that 
      the line reads "sqlite". If "mysql" is not commented, change it so that it 
      is is.</li>
      <li>Change the map/reload the server.</li>
      <li>Press 1, or "Add First ARP Admin".</li>
      <li>Type "arp_config" in your console again.</li>
      <li>Press 3, or "Load Map SQL Database" and wait for it to load all 
      entries.</li>
      <li>Change the map/reload the server. You should be ready to RP!</li>
    </ol>
    <div class="title">File Structure</div>
    <p>All configurable Apollo RP files are contained in the ./configs/arp/ 
    directory. ARP uses a special system to handle map configuration file. 
    The core attempts to load configuration files from the map 
    (./configs/arp/maps/<mapname>/) directory. Failing that, it loads from 
    the ARP configuration directory (./configs/arp/). The only file that 
    doesn't follow this rule is the "arp.ini" file, which actually loads 
    from both if they are both present. This file is first loaded from the 
    ARP base configuration directory, then any settings contained in the map 
    configuration directory overwrite those previously loaded.</p>
    <div class="title">SQL Connection Settings</div>
    <p>The SQL connection settings are stored in the file "arp.ini". The default
    settings are as follows:</p>
    <div class="code">
    arp_sql_host "localhost"<br />
    arp_sql_user "root"<br />
    arp_sql_pass ""<br />
    arp_sql_db "arp"<br />
    arp_sql_type "mysql"<br />
    <br />
    arp_table_users "arp_users"<br />
    arp_table_property "arp_property"<br />
    arp_table_doors "arp_doors"<br />
    arp_table_items "arp_items"<br />
    arp_table_keys "arp_keys"<br />
    arp_table_jobs "arp_jobs"<br />
    </div>
    <p>These can be modified in-game using the configuration (ARP_Config)
    plugin.</p>
    <div class="title">Game Settings</div>
    <p>Most game settings can be found in the "arp.cfg" file, located in
    ./configs/arp/. All CVARs and commands in it contain an explanation directly
    above them for what the CVAR or command does and what parameters it
    takes.</p>
    <div class="title">Access Flags</div>
    <p>Access flags in ARP use each letter of the alphabet as a separate flag.
    For example, if a user has flags "ac" and the police flag is "a", then they
    are considered a police officer on top of whatever flag "c" is assigned to.
    This allows players to be part of multiple factions or use multiple plugins
    that require a certain level of access to use them.</p>
    <p>Flags in ARP are divided into two sections and two sections only: access
    flags and job access flags. A player gathers access flags from two sources:
    independent access flags, job access flags. A player can only gather job
    access flags from a single source: their independent job access flags.
    Independent access flags are assigned using the "arp_setaccess" command. The
    player does not lose these flags unless the "arp_setaccess" command is run
    on them again without the flag assigned as one of the parameters. Job access
    flags are assigned to a user from their job. For example, a job like "MCPD
    Explorer" might have flag "a". If the user has the job "MCPD Explorer" and
    the command "arp_setaccess" is run on them such that they have flag "a", the
    flags do not stack. The player will still simply have flag "a", but if they
    lose their job, they will still have flag "a" because it was assigned to
    them using "arp_setaccess". Job access flags are, by default, assigned to
    allow players to hand out jobs that have a certain flag. For example, if a
    player has job access flag "a", that means that they can employ people to
    any job containing flag "a" (police officers, FBI or similar
    organizations).</p>
    <p>By default, the police access flag is "a", the medical access flag is "b"
    and the admin access flag is "z". These can all be edited in the "arp.cfg"
    file.</p>
    <div class="title">Properties</div>
    <p>Properties are divided into two different sections: properties and doors.
    While the door is the physical manifestation, the property is simply the
    concept. It contains all of the details, such as price, locked status,
    owner, name, etc. The door is a location that a property is present at.
    Properties and doors are linked using an "internal name", which is simply a
    tag for that property. It can be anything, although it is recommended that
    it is something easy to remember, like "md" for "Medical Department".</p>
    <div class="subtitle">Adding Properties</div>
    <p>Properties can be added through the "arp_addproperty" command. Any
    parameter that is to be left blank should be inputted as "". The command
    takes the following parameters:</p>
    <ul>
      <li><i>internalname</i> - tag used to link to doors</li>
      <li><i>externalname</i> - the name as it appears for users looking at a
      door linked to the property</li>
      <li><i>owner</i> - the name of the owner</li>
      <li><i>authid</i> - the authid of the owner</li>
      <li><i>price</i> - how much it is to be sold for (0 to indicate not for
      sale)</li>
      <li><i>lock</i> - whether or not to lock it (0 or 1)</li>
      <li><i>access</i> - what access flags should have access to it</li>
      <li><i>profit</i> - how much profit it has</li>
    </ul>
    <p>A door can then be linked to it by running "arp_adddoor". This command
    has only one parameter: the internal name of the property it is to be added
    to.</p>
    <div class="subtitle">Editing Properties</div>
    <p>Properties can be edited using the "arp_setproperty" command. This
    command is nearly identical to the "arp_addproperty" command, although it
    differs in two ways:</p>
    <p>The internal name parameter is not used to edit the property; it is used
    to reference it.</p>
    <p>Parameters that are not to be changed should be set to "!". For example,
    if you want to change only the locked status of a property, you should type:
    arp_setproperty <internalname> ! ! ! ! 1 ! !</p> 
    <p>Doors cannot be edited. If you want to move a door to another property,
    you should delete that door then re-add it to another property.</p>
    <div class="subtitle">Deleting Properties</div>
    <p>Properties and doors can be deleted using the "arp_deleteproperty" and
    "arp_deletedoor" commands. Both of these commands require you only to look
    at a door linked to a property for them to take effect.</p>
    <div class="title">NPCs</div>
    <p>NPCs are organized in the "npcs.ini" file found in the map directory for
    the map being run. There are 5 different types of NPCs by default: shops,
    doctors, banks, atms and gunshops. The following is an example entry in 
    npcs.ini:</p>
    <div class="code">type "shop"<br />
    name "Wawa Clerk"<br />
    model "models/mecklenburg/chef.mdl"<br />
    angle "180"<br />
    origin "-2374 1210 -445"<br />
    sell "Cigarette 10"<br />
    sell "Cuban_Cigar 20"<br />
    sell "Tobacco_Pipe 30"<br />
    sell "Lighter 10"<br />
    sell "Zippo 50"<br />
    sell "Spray_Can 50"<br />
    property "seveneleven"<br />
    robprofile "Wawa"<br />
    [END]</div>
    <p>The "type" parameter is used to determine which type of NPC it should be.
    The "name" parameter indicates what it should appear as when looked at. The
    "model" parameter is the model that should be used if the NPC is not a zone
    (this will be covered later). The "angle" parameter indicates which
    direction the NPC should be facing. The "origin" parameter indicates where
    in the game world the NPC should be located. Using "sell" tells the NPC to
    sell an item with a given name and price. Underscores are used to replace
    spaces in the configuration file. The "property" parameter is the property
    it should be linked to in order to enable profit gathering. Finally, the
    "robprofile" parameter is used to indicate which profile specified in
    rob.ini should be called when the NPC is robbed. This is all ended with the
    "[END]" command, which spawns the NPC.</p>
    <p>In addition to these, a line containing the word "zone" can be added to
    turn the NPC into a zone. Zones are used when there is an area with which an
    invisible and incorporeal NPC is needed. For example, a gunshop with an NPC
    behind glass or an ATM would need a zone-based NPC. When a zone is used, the
    "model" and "angle" parameters are ignored.</p>
    <div class="subtitle">Shops</div>
    <p>These are the most generalized of the NPCs. They are used to sell items
    to be robbed. They take no additional parameters.</p>
    <div class="subtitle">Doctors</div>
    <p>Doctors act like shops, except they cannot be robbed and they have an
    optional "!Heal" parameter which, when used, begins the heal process. To use
    this, input a "sell" command with item id "!Heal" and any price. For
    example, sell "!Heal 100".</p>
    <div class="subtitle">Banks</div>
    <p>Banks allow users to buy ATM cards, withdraw/deposit money and rob. They
    cannot sell items and do not gather profit.</p>
    <div class="subtitle">ATMs</div>
    <p>ATMs are essentially portable banks. The use of them requires an ATM
    card. They allow users to withdraw/deposit money. They cannot be robbed,
    cannot sell items and do not gather profit.</p>
    <div class="subtitle">Gunshops</div>
    <p>Gunshops are shops specializing in selling guns. They can take an
    additional "addgun" command. The "addgun" command is the same as "sell",
    except that it has a 3rd parameter which allows you to specify a license
    that a player must have to buy the item. The licenses are as follows:</p>
    <ul>
      <li>0 - non-restricted: this is the most basic license and tends to cost
      very little as it includes only basic guns.</li>
      <li>1 - restricted: this is the next license which includes most mid-range
      weapons.</li>
      <li>2 - prohibited: these guns cannot be bought at a gun store and are
      generally the most dangerous.</li>
    </ul>
    <p>Here is an example usage of "addgun":</p>
    <div class="code">
      addgun "glock-18 1000 0"
    </div>
    <p>Gunshops cannot be robbed, do not gather profit and cannot sell items
    that aren't declared using "addgun".</p>
    <div class="title">Jail Settings</div>
    <p>The jail plugin contains all of the functionality for jailing and cuffing
    - essentially the most important things for the police force. Jail origins
    are specified in the map directory, inside the file "jailmod.ini". Here is
    an example entry:</p>
    <div class="code">
    [Jail One]<br />
    origin "-2724 2214 -347"<br />
    command "1"<br />
    </div>
    <p>The "Jail One" section declares the name of the jail as it is to appear
    in the menu, which can be called up in-game with the command "jailmodmenu"
    in the console. The "origin" is where a player should be sent if they are
    jailed to this location. The "command" parameter declares the quick-command
    that can be used for binding and console access. The command to use this
    jail is always "jail <command>" in the console. In this case, it would be
    "jail 1".</p>
    <p>By default, cuffing requires the "Cuff" item, which is used up when
    someone is cuffed, then given back when they are uncuffed. This
    functionality can be disabled by opening the "ARP_JailMod.sma" file, putting
    "//" in front of "#define CUFF_ITEM", then recompiling and copying the new
    binary over to the server.</p>
    <div class="title">Rob Settings</div>
    <p>Rob Mod uses a light-weight scripting engine called RobScript, which was
    developed for ARP. With some changes, it can be used for other purposes
    including hacking, an alarm system and many other applications. RobScript
    sections are divided into "profiles", generally for each location that is to
    be robbed. There are two types of "commands" in RobScript:</p>
    <p>Configuration lines - These allow you to configure the messages and
    settings of a certain place. Their structure is: command "parameter"</p>
    <p>Execution lines - These allow you to run a sequence of events. Their
    structure is: !command "parameter"</p>
    <div class="title">Mod-Specific</div>
    <p>This section covers configuration specific to whatever Half-Life mod you
    are currently running ARP on. You should only do whatever is contained in
    your mod's section.</p>
    <div class="subtitle">Counter-Strike</div>
    <p>Uncomment ARP_CS.amxx from plugins-arp.ini</p>
    <div class="subtitle">The Specialists</div>
    <p>Uncomment ARP_TS.amxx from plugins-arp.ini</p>
    <p>Add the following cvars to your server.cfg, or change them to these
    values if they already exist:</p>
    <div class="code">
    nopowerup 1<br />
    weaponrestriction 1<br />
    mp_timelimit 0<br />
    slowmatch 0
    </div>
    <p>The TS plugin also has a weapon spawns addition to it. The command to add
    a weapon spawn is "arp_addgun <i>weaponid ammo extra save(0/1)</i>".</p>
    <ul>
      <li><i>weaponid</i> is the weapon id of the gun.</li>
      <li><i>ammo</i> is the amount of ammo the gun should spawn with.</li>
      <li><i>extra</i> is a bit value containing the properties of the weapon
      spawn.
        <ul>
          <li>1 - Silencer</li>
          <li>2 - Lasersight</li>
          <li>4 - Flashlight</li>
          <li>8 - Scope</li>
          <li>16 - Position weapon on wall rather than floor</li>
          <li>Note: add these up, don't put "1,2,4..."</li>
        </ul>
      </li>
      <li><i>save</i> determines whether or not the spawn should stay on the map
      change/server restart/etc.</li>
    </ul>
    <p>Weapon IDs are:</p>
    <ul>
      <li>1 - Glock 18</li>
      <li>3 - Mini Uzi</li>
      <li>4 - Benelli M3</li>
      <li>5 - M4A1</li>
      <li>6 - MP5SD</li>
      <li>7 - MP5K</li>
      <li>8 - Beretta</li>
      <li>9 - SOCOM Mk23</li>
      <li>11 - USAS-12</li>
      <li>12 - Desert Eagle</li>
      <li>13 - AK-47</li>
      <li>14 - Five-seveN</li>
      <li>15 - Steyr Aug</li>
      <li>17 - Skorpion</li>
      <li>18 - Barrett M82</li>
      <li>19 - HK PDW</li>
      <li>20 - SPAS-12</li>
      <li>21 - Golden Colts</li>
      <li>22 - Glock 20</li>
      <li>23 - UMP</li>
      <li>24 - M61 Grenade</li>
      <li>25 - Combat Knife</li>
      <li>26 - Mossberg 500</li>
      <li>27 - M16A4</li>
      <li>28 - Ruger Mk1</li>
      <li>31 - Raging Bull</li>
      <li>32 - M60</li>
      <li>33 - Sawed-Off Shotgun</li>
      <li>34 - Katana</li>
      <li>35 - Seal Knife</li>
      <li>36 - Contender G2</li>
    </ul>
    <div class="title">Zones</div>
    <p>Zones can be defined using the zones.ini file. This file can be 
    located in either the map config directory (configs/arp/maps/<my_map>) 
    or the base ARP config directory (configs/arp). Its general structure 
    is:</p>
    <div class="code">
    "Zone Name"<br />
    {<br />
        "boundaries1" "x y z",<br />
        "boundaries2" "x y z",<br />
    }<br />
    <br />
    "Zone Name 2"<br />
    {<br />
        "boundaries1" "x y z",<br />
        "boundaries2" "x y z",<br />
    }<br />
    </div>
    <div class="title">Plugins</div>
    <div class="subtitle">Installing Plugins</div>
    <p>Often, plugins will have their own directions if they need special
    installation requirements. However, this will instruct you on the basics of
    adding a plugin.</p>
    <p>Follow any directions the plugin author has given you. If the plugin
    requires extra steps or special files, make sure you have them in the proper
    place and order.</p>
    <p>If you are given a .sma source file instead of a .amxx, you must compile
    the plugin yourself. For more information, see Compiling Plugins.</p>
    <p>Place the plugin's .amxx file in the addons/amxmodx/plugins folder.</p>
    <p>Add the plugin's name to addons\amxmodx\configs\plugins-arp.ini after the
    "3rd Party Plugins" line. Example:</p>
    <div class="code">
    myplugin.amxx
    </div>
    <p>Change map or restart the server. If the plugin has any load errors, see
    <a href="http://wiki.amxmodx.org/Troubleshooting_AMX_Mod_X">Troubleshooting
    Plugins</a>.</p> 
    <div class="subtitle">Removing Plugins</div>
    <p>Remove the entry from addons\amxmodx\configs\plugins-arp.ini by deleting
    it or prepending a semi-colon to comment it out. Delete any associated
    files.</p> 
<?php include_once('template/footer.html'); ?>
