# Apollo RP SQL Prebuilt configuration for "augsburg_b1"
# Apply using in-game tool or any SQL editor

CREATE TABLE IF NOT EXISTS arp_doors (targetname VARCHAR(36),internalname VARCHAR(66),UNIQUE KEY (targetname))

insert  into arp_doors values ('t|711', '711')
insert  into arp_doors values ('t|AptA', 'AptA')
insert  into arp_doors values ('t|AptB', 'AptB')
insert  into arp_doors values ('t|AptC', 'AptC')
insert  into arp_doors values ('t|AptD', 'AptD')
insert  into arp_doors values ('t|Bank', 'bank')
insert  into arp_doors values ('t|bank_laser_button', 'bank')
insert  into arp_doors values ('t|bank_tresor', 'bank')
insert  into arp_doors values ('t|Club', 'Club')
insert  into arp_doors values ('t|dumbster2', 'Dumpster')
insert  into arp_doors values ('t|GM_Court', 'GM_Court')
insert  into arp_doors values ('t|GM_Office', 'GM_Office')
insert  into arp_doors values ('t|GM_Suit', 'GM_Suit')
insert  into arp_doors values ('t|president_suit', 'GM_Suit')
insert  into arp_doors values ('t|Gunshop', 'Gunshop')
insert  into arp_doors values ('t|hideout1', 'hideout1')
insert  into arp_doors values ('t|Hideout2', 'Hideout2')
insert  into arp_doors values ('t|Hideout3', 'Hideout3')
insert  into arp_doors values ('t|Hideout5', 'Hideout5')
insert  into arp_doors values ('t|Hideout6', 'Hideout6')
insert  into arp_doors values ('e|127', 'Hotel1')
insert  into arp_doors values ('e|145', 'Hotel1')
insert  into arp_doors values ('e|146', 'Hotel2')
insert  into arp_doors values ('t|hotel2', 'Hotel2')
insert  into arp_doors values ('t|hotel3', 'Hotel3')
insert  into arp_doors values ('t|hotel4', 'Hotel4')
insert  into arp_doors values ('t|MD', 'MD')
insert  into arp_doors values ('t|Office-Conferenz', 'Office-Conferenz')
insert  into arp_doors values ('t|Office1', 'Office1')
insert  into arp_doors values ('t|Office2', 'Office2')
insert  into arp_doors values ('t|Office3', 'Office3')
insert  into arp_doors values ('t|Office4', 'Office4')
insert  into arp_doors values ('t|Office5', 'Office5')
insert  into arp_doors values ('t|PizzaHut', 'PizzaHut')
insert  into arp_doors values ('t|Police Departement', 'Police Departement')
insert  into arp_doors values ('t|srlocker1', 'srlocker1')
insert  into arp_doors values ('t|srlocker2', 'srlocker2')
insert  into arp_doors values ('t|srlocker3', 'srlocker3')
insert  into arp_doors values ('t|srlocker4', 'srlocker4')
insert  into arp_doors values ('t|srlocker5', 'srlocker5')
insert  into arp_doors values ('e|266', 'warehouse')
insert  into arp_doors values ('t|warehouse', 'warehouse')
insert  into arp_doors values ('t|warehouse1', 'warehouse1')
insert  into arp_doors values ('t|W_Boxhouse04', 'Warehouse')

CREATE TABLE IF NOT EXISTS arp_jobs (name VARCHAR(32),salary INT(11),access VARCHAR(27),UNIQUE KEY (name))

insert  into arp_jobs values ('MCPD Jail Guard', 15, 'a')
insert  into arp_jobs values ('MCPD Explorer', 20, 'a')
insert  into arp_jobs values ('MCPD Officer', 30, 'a')
insert  into arp_jobs values ('MCPD Senior Officer', 35, 'a')
insert  into arp_jobs values ('MCPD Trainer', 40, 'a')
insert  into arp_jobs values ('MCPD Lieutenant', 50, 'a')
insert  into arp_jobs values ('MCPD Sergeant', 45, 'a')
insert  into arp_jobs values ('MCPD Captain', 60, 'a')
insert  into arp_jobs values ('MCPD Deputy Chief', 70, 'a')
insert  into arp_jobs values ('MCPD Chief', 80, 'a')
insert  into arp_jobs values ('Edeka Employee', 20, 't')
insert  into arp_jobs values ('Edeka Guard', 20, 't')
insert  into arp_jobs values ('Bank Guard', 20, 't')
insert  into arp_jobs values ('Bank Clerk', 20, 't')
insert  into arp_jobs values ('Bank Manager', 25, 't')
insert  into arp_jobs values ('Lawyer', 20, 't')
insert  into arp_jobs values ('City Judge', 30, 'e')
insert  into arp_jobs values ('Hobo', 15, 't')
insert  into arp_jobs values ('Advertiser', 15, 't')
insert  into arp_jobs values ('Postman', 15, 't')
insert  into arp_jobs values ('Photographer', 15, 't')
insert  into arp_jobs values ('Pizzaboy', 15, 't')
insert  into arp_jobs values ('Taxi Driver', 10, 't')
insert  into arp_jobs values ('Economist', 15, 't')
insert  into arp_jobs values ('Professor', 15, 't')
insert  into arp_jobs values ('Weapons Dealer', 15, 't')
insert  into arp_jobs values ('Reporter', 15, 't')
insert  into arp_jobs values ('Porn Star', 20, 't')
insert  into arp_jobs values ('Salesman', 20, 't')
insert  into arp_jobs values ('Bodyguard', 30, 't')
insert  into arp_jobs values ('Hitman', 25, 't')
insert  into arp_jobs values ('S.W.A.T Rookie', 50, 'a')
insert  into arp_jobs values ('S.W.A.T Member', 55, 'a')
insert  into arp_jobs values ('S.W.A.T Leader', 70, 'a')
insert  into arp_jobs values ('S.W.A.T Experienced', 60, 'a')
insert  into arp_jobs values ('MCMD Nurse', 25, 'bp')
insert  into arp_jobs values ('MCMD Paramedic', 35, 'b')
insert  into arp_jobs values ('MCMD Medic', 45, 'b')
insert  into arp_jobs values ('MCMD Doctor', 55, 'b')
insert  into arp_jobs values ('MCMD Head Doctor', 65, 'b')
insert  into arp_jobs values ('MCMD Advanced Brain Surgeon', 80, 'b')
insert  into arp_jobs values ('Spy', 30, 't')
insert  into arp_jobs values ('Thief', 20, 't')
insert  into arp_jobs values ('Terrorist', 40, 't')
insert  into arp_jobs values ('Drug Dealer', 20, 't')
insert  into arp_jobs values ('Chaffeur', 30, 't')
insert  into arp_jobs values ('Exotic Dancer', 15, 't')

CREATE TABLE IF NOT EXISTS arp_property (internalname VARCHAR(66),externalname VARCHAR(66),ownername VARCHAR(40),ownerauth VARCHAR(36),price INT(11),locked INT(11),access VARCHAR(27),profit INT(11),UNIQUE KEY (internalname))

insert  into arp_property values ('711', '7/11', '', '', 100000, 1, '', 0)
insert  into arp_property values ('AptA', 'Apartment A', '', '', 80000, 1, '', 0)
insert  into arp_property values ('AptB', 'Apartment B', '', '', 80000, 1, 'm', 0)
insert  into arp_property values ('AptC', 'Apartment C', '', '', 80000, 1, '', 0)
insert  into arp_property values ('AptD', 'Apartment D', '', '', 80000, 1, '', 0)
insert  into arp_property values ('bank', 'Nations Bank', '', '', 90000, 1, 'q', 0)
insert  into arp_property values ('Club', 'Xevi Club', '', '', 90000, 1, '', 0)
insert  into arp_property values ('Dumpster', 'Dumpster', '', '', 50000, 1, '', 0)
insert  into arp_property values ('GM_Court', 'Court Room', '', '', 0, 1, '', 0)
insert  into arp_property values ('GM_Office', 'Government Office', '', '', 0, 1, '', 0)
insert  into arp_property values ('GM_Suit', 'Government Suite', '', '', 0, 1, '', 0)
insert  into arp_property values ('Gunshop', 'Ammu-Nation', '', '', 80000, 1, '', 0)
insert  into arp_property values ('Hotel1', 'Hotel #1', '', '', 20000, 1, '', 0)
insert  into arp_property values ('Hotel2', 'Hotel #2', '', '', 20000, 1, '', 0)
insert  into arp_property values ('Hotel3', 'Hotel #3', '', '', 20000, 1, '', 0)
insert  into arp_property values ('Hotel4', 'Hotel #4', '', '', 20000, 1, '', 0)
insert  into arp_property values ('hideout1', 'Hideout #1', '', '', 80000, 1, '', 0)
insert  into arp_property values ('Hideout2', 'Hideout #2', '', '', 80000, 1, '', 0)
insert  into arp_property values ('Hideout3', 'Hideout #3', '', '', 80000, 1, '', 0)
insert  into arp_property values ('hideout5', 'Hideout #4', '', '', 80000, 1, '', 0)
insert  into arp_property values ('Hideout6', 'Hideout #5', '', '', 80000, 1, '', 0)
insert  into arp_property values ('MD', 'Medical Department', '', '', 0, 1, 'bc', 0)
insert  into arp_property values ('Office-Conferenz', 'Office Conference Room', '', '', 50000, 1, '', 0)
insert  into arp_property values ('Office1', 'Office #1', '', '', 40000, 1, '', 0)
insert  into arp_property values ('Office2', 'Office #2', '', '', 40000, 1, '', 0)
insert  into arp_property values ('Office3', 'Office #3', '', '', 40000, 1, '', 0)
insert  into arp_property values ('Office4', 'Office #4', '', '', 40000, 1, '', 0)
insert  into arp_property values ('Office5', 'Office #5', '', '', 40000, 1, '', 0)
insert  into arp_property values ('PizzaHut', 'Pizza Hut', '', '', 80000, 1, '', 0)
insert  into arp_property values ('Police Departement', 'Police Department', '', '', 0, 1, 'a', 0)
insert  into arp_property values ('president_suit', 'Presidential Suite', '', '', 0, 1, '', 0)
insert  into arp_property values ('srlocker1', 'Locker #1', '', '', 80000, 1, '', 0)
insert  into arp_property values ('srlocker2', 'Locker #2', '', '', 80000, 1, '', 0)
insert  into arp_property values ('srlocker3', 'Locker #3', '', '', 80000, 1, '', 0)
insert  into arp_property values ('srlocker4', 'Locker #4', '', '', 80000, 1, '', 0)
insert  into arp_property values ('srlocker5', 'Locker #5', '', '', 80000, 1, '', 0)
insert  into arp_property values ('Warehouse', 'Warehouse', '', '', 80000, 1, '', 0)
insert  into arp_property values ('warehouse1', 'Warehouse #2', '', '', 80000, 1, '', 0)
