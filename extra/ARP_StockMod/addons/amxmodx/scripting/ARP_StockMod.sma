#include <amxmodx>
#include <amxmisc>
#include <sockets>
#include <ApolloRP>
#include <ApolloRP_Chat>

//new g_Treasuries[3]

//#define DEBUG

new p_UpdateTime

new g_File[] = "stocks.ini"
new g_WriteFile[] = "stocks.txt"

new TravTrie:g_Tickers

new g_Socket

new g_Buffer[4096]

new g_NPC

new g_StockOptionsMenu
new g_TradeMenu
new g_NumberMenu

new g_Mode[33]

new g_Ticker[33][12]

new g_MarketClosed

new g_BlackBerry

new g_NumChecks

public ARP_Init()
{
	ARP_RegisterPlugin("Stock Mod","1.0","Hawk552","Allows players to make investments")
	
	ARP_RegisterCmd("arp_stockquote","CmdStockQuote","(ADMIN) Updates and prints current stock status")
	
	p_UpdateTime = register_cvar("arp_stock_updatetime","300")
	
	set_task(get_pcvar_float(p_UpdateTime),"UpdateStocks")
	
	g_StockOptionsMenu = menu_create("Stock Options","StockOptionsHandler")
	menu_additem(g_StockOptionsMenu,"Buy")
	menu_additem(g_StockOptionsMenu,"Sell")
	menu_additem(g_StockOptionsMenu,"Current Quotes")
	
	//g_TradeMenu = menu_create("Trade Menu","TradeMenuHandle")
	
	g_NumberMenu = menu_create("Trade Number","TradeNumberHandle")
	menu_additem(g_NumberMenu,"1")
	menu_additem(g_NumberMenu,"5")
	menu_additem(g_NumberMenu,"10")
	menu_additem(g_NumberMenu,"20")
	menu_additem(g_NumberMenu,"50")
	menu_additem(g_NumberMenu,"100")
	menu_additem(g_NumberMenu,"1000")
	
	ARP_AddChat(_,"CmdSay")
	ARP_AddCommand("say /quote <# to start at or ticker symbol>","Allows you to check stocks")
}

public CmdSay(id)
{
	new Args[256]
	read_args(Args,255)
	
	remove_quotes(Args)
	
	if(!equali(Args,"/quote",5))
		return PLUGIN_CONTINUE
	
	new Index,Body
	get_user_aiming(id,Index,Body,300)
	
	if(Index != g_NPC && !ARP_GetUserItemNum(id,g_BlackBerry))
	{
		client_print(id,print_chat,"[ARP] You are not looking at the investment broker.")
		return PLUGIN_HANDLED
	}
	
	replace(Args,255,"/quote","")
	
	remove_quotes(Args)
	trim(Args)
	
	if(!strlen(Args))
		ShowCurrentQuote(id,0)
	
	if(is_str_num(Args)) ShowCurrentQuote(id,str_to_num(Args))
	else
	{
		new travTrieIter:Iter = GetTravTrieIterator(g_Tickers),Ticker[12],Value[64],Company[64],Stock[10]
		while(MoreTravTrie(Iter))
		{
			ReadTravTrieKey(Iter,Ticker,11)
			ReadTravTrieString(Iter,Value,63)
			
			strtok(Value,Company,63,Stock,9,'|')
			
			if(equali(Args,Ticker))
			{
				client_print(id,print_chat,"[ARP] %s (%s) is currently trading at $%s.",Company,Ticker,Stock)
				DestroyTravTrieIterator(Iter)
				return PLUGIN_HANDLED
			}
		}
		DestroyTravTrieIterator(Iter)
		
		client_print(id,print_chat,"[ARP] No ticker was found with that name.")
	}
	
	return PLUGIN_HANDLED
}

public UpdateStocks()
{
	UpdateInfo()
	
	set_task(get_pcvar_float(p_UpdateTime),"UpdateStocks")
}

public plugin_end() 
{
	TravTrieDestroy(g_Tickers)
	menu_destroy(g_StockOptionsMenu)
	menu_destroy(g_TradeMenu)
	menu_destroy(g_NumberMenu)
}

public CmdStockQuote(id)
{
	if(!ARP_AdminAccess(id))
	{
		console_print(id,"You do not have access to this command")
		return PLUGIN_HANDLED
	}
	
	UpdateInfo()
	
	console_print(id,"Stock values have been updated")
	
	return PLUGIN_HANDLED
}

public ARP_RegisterItems()
{
	g_Tickers = TravTrieCreate()
	
	new File = ARP_FileOpen(g_File,"rt+")
	if(!File)
	{
		ARP_Log("Could not open file ^"%s^"",g_File)
		return
	}
	
	// Model stuff for the NPC
	new Model[64],StrAngle[10],Float:Angle,OriginStr[33],SplitOrigin[3][10],Float:Origin[3],Garbage[2]
	
	new Ticker[12],Value[64],Company[64],Stock[10],ZoneStr[3],Zone
	while(!feof(File))
	{
		fgets(File,g_Buffer,4095)
		
		if(g_Buffer[0] == ';' || !g_Buffer[0]) continue
		
		replace_all(g_Buffer,4095,"^n","")
		remove_quotes(g_Buffer)
		trim(g_Buffer)
		
		if(g_Buffer[0] == '*')
		{
			if(equali(g_Buffer[1],"model",5))
			{
				parse(g_Buffer[1],Garbage,1,Model,63)
				remove_quotes(Model)
			}
			if(equali(g_Buffer[1],"angle",5))
			{
				parse(g_Buffer[1],Garbage,1,StrAngle,9)
				Angle = str_to_float(StrAngle)
			}
			if(equali(g_Buffer[1],"origin",6))
			{
				parse(g_Buffer[1],Garbage,1,OriginStr,32)
				parse(OriginStr,SplitOrigin[0],9,SplitOrigin[1],9,SplitOrigin[2],9)
				
				for(new i = 0;i < 3;i++)
					Origin[i] = str_to_float(SplitOrigin[i])
			}
			if(equali(g_Buffer[1],"zone",4))
			{
				parse(g_Buffer[1],Garbage,1,ZoneStr,2)
				Zone = str_to_num(ZoneStr)
			}
			
			continue
		}
		//parse(g_Buffer,Ticker,11,Name,63)
		
		//remove_quotes(Ticker)
		//remove_quotes(Name)
		
		//TravTrieSetString(g_Tickers,Ticker,Name)
		TravTrieSetString(g_Tickers,g_Buffer,"")
	}
	fclose(File)
	
	if(file_exists(Model))
	{
		precache_model(Model)
		g_NPC = ARP_RegisterNpc("Investment Broker",Origin,Angle,Model,"NPCHandler",Zone)
	}
	else 
	{
		set_fail_state("Could not create NPC, file missing")
		return
	}
	
	UpdateInfo()
	
	new travTrieIter:Iter = GetTravTrieIterator(g_Tickers),Description[64]
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKey(Iter,Ticker,11)
		ReadTravTrieString(Iter,Value,63)
		
		strtok(Value,Company,63,Stock,9,'|')
		
		format(Value,63,"%s Stock",Company)
		format(Description,63,"Stock in %s (%s).",Company,Ticker)
		
		ARP_RegisterItem(Value,"_Stock",Description)
	}
	DestroyTravTrieIterator(Iter)
	
	g_BlackBerry = ARP_RegisterItem("BlackBerry Storm","_BlackBerry","Displays stock quote data")
	
	//ARP_RegisterItem("Population Fund","_PopulationFund","Increases and decreases in value with average server population")
	//ARP_RegisterItem("Random Fund","_RandomFund","Increases and decreases totally randomly every 10 minutes")
	
	//g_Treasuries[0] = ARP_RegisterItem("Treasury Bill","_Treasury","Low yield, low return time treasury")
	//g_Treasuries[1] = ARP_RegisterItem("Treasury Note","_Treasury","Medium yield, medium return time treasury")
	//g_Treasuries[2] = ARP_RegisterItem("Treasury Bond","_Treasury","High yield, high return time treasury")
}

public _Stock(id) client_print(id,print_chat,"[ARP] This item cannot be used.")

public _BlackBerry(id) client_print(id,print_chat,"[ARP] To use this, say /quote <stock # to start at or ticker symbol>.")

ShowCurrentQuote(id,Num)
{		
	if(Num < 0 || Num >= TravTrieSize(g_Tickers))
	{
		client_print(id,print_chat,"[ARP] That is not a valid start number.")
		return
	}
	
	/*new travTrieIter:Iter = GetTravTrieIterator(g_Tickers),Ticker[12],Value[64],Company[64],Stock[10],Len = format(g_Buffer,4095,"Company (Ticker) - Quote^n^n")
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKey(Iter,Ticker,11)
		ReadTravTrieString(Iter,Value,63)
		
		strtok(Value,Company,63,Stock,9,'|')
	
		Len += format(g_Buffer[Len],4095 - Len,"%s (%s) - $%s^n",Company,Ticker,Stock)
	}
	DestroyTravTrieIterator(Iter)*/
	
	new Pos = Num,Ticker[12],Value[64],Company[64],Stock[10],Len = format(g_Buffer,4095,"Company (Ticker) - Quote^n^n"),Size = TravTrieSize(g_Tickers)
	while(Pos < Num + 15 && Pos < Size)
	{
		TravTrieNth(g_Tickers,Pos,Ticker,11)
		TravTrieGetString(g_Tickers,Ticker,Value,63)
		
		strtok(Value,Company,63,Stock,9,'|')
	
		Len += format(g_Buffer[Len],4095 - Len,"%d. %s (%s) - $%s^n",Pos + 1,Company,Ticker,Stock)
		
		Pos++
	}
	
	if(g_MarketClosed)
		Len += format(g_Buffer[Len],4095 - Len,"^nThe market is currently closed.")
	
	if(Pos < Size)
		Len += format(g_Buffer[Len],4095 - Len,"^nType ^"/quote %d^" for more entries.",Pos)
	
	show_motd(id,g_Buffer,"Stock Quotes")
	
	return
}

public NPCHandler(id,NPC)
	if(NPC == g_NPC && ARP_NpcDistance(id,NPC))
		menu_display(id,g_StockOptionsMenu)

public StockOptionsHandler(id,Menu,Item)
	switch(Item)
	{
		case 0,1: 
		{
			g_Mode[id] = Item
			menu_display(id,g_TradeMenu)
		}
		case 2: client_print(id,print_chat,"[ARP] To use this, say /quote <stock # to start at>.")
	}

public TradeMenuHandle(id,Menu,Item)
{
	if(Item == MENU_EXIT) return
	
	new Access
	menu_item_getinfo(Menu,Item,Access,g_Ticker[id],11,_,_,Access)
	
	menu_display(id,g_NumberMenu)
}

public TradeNumberHandle(id,Menu,Item)
{
	new Num
	switch(Item)
	{
		case 0 : Num = 1
		case 1 : Num = 5
		case 2 : Num = 10
		case 3 : Num = 20
		case 4 : Num = 50
		case 5 : Num = 100
		case 6 : Num = 1000
		default : return
	}
	
	new travTrieIter:Iter = GetTravTrieIterator(g_Tickers),Ticker[12],Value[64],Company[64],Stock[10],Cost
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKey(Iter,Ticker,11)
		ReadTravTrieString(Iter,Value,63)
		
		if(equali(Ticker,g_Ticker[id]))
		{
			strtok(Value,Company,63,Stock,9,'|')
			
			Cost = str_to_num(Stock) * Num
			
			break
		}
	}
	DestroyTravTrieIterator(Iter)
	
	new ItemIds[1]
	format(Value,63,"%s Stock",Company)
	
	if(!ARP_FindItemId(Value,ItemIds,1))
	{
		client_print(id,print_chat,"[ARP] Error finding stock. Please contact administrator.")
		return
	}
	
	new ItemId = ItemIds[0],ItemNum = ARP_GetUserItemNum(id,ItemId),Money = ARP_GetUserBank(id)
	
	if(!g_Mode[id] && Money < Cost)
	{
		client_print(id,print_chat,"[ARP] You do not have enough money to purchase this stock.")
		return
	}
	
	if(g_Mode[id] && ItemNum < Num)
	{		
		client_print(id,print_chat,"[ARP] You do not have enough of this stock to sell.")
		return
	}
	
	// There's a huge memory corruption bug here so I had to use if statements instead of a condensed condition
	if(g_Mode[id])
	{
		ARP_SetUserItemNum(id,ItemId,ItemNum - Num)
		ARP_SetUserBank(id,Money + Cost)
	}
	else
	{	
		ARP_SetUserItemNum(id,ItemId,ItemNum + Num)
		ARP_SetUserBank(id,Money - Cost)
	}
	
	client_print(id,print_chat,"[ARP] You have %s %d stocks in %s (%s) for $%d.",g_Mode[id] ? "sold" : "purchased",Num,Company,Ticker,Cost)
	if(g_MarketClosed)
		client_print(id,print_chat,"[ARP] The market is currently closed. The value of your stock will not fluctuate until it reopens.")
}

public UpdateInfo()
{
	new Error
	g_Socket = socket_open("download.finance.yahoo.com",80,SOCKET_TCP,Error);
	
	if(Error || !g_Socket)
	{
		log_amx("Error with socket: %d",Error)
		return
	}
	
	new travTrieIter:Iter = GetTravTrieIterator(g_Tickers),Tickers[384],Key[10],Garbage[2]
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKey(Iter,Key,9)
		
		add(Tickers,383,Key)
		
		ReadTravTrieString(Iter,Garbage,1)
		
		if(MoreTravTrie(Iter))
			add(Tickers,383,",")
	}	
	DestroyTravTrieIterator(Iter)
	
	/*new TickersLen = strlen(Tickers)
	if(TickersLen <= sizeof(Tickers))
		Tickers[TickersLen - 1] = 0*/
	
	format(g_Buffer,4095,"GET /d/quotes.csv?s=%s&f=snl1 HTTP/1.0^nHost: download.finance.yahoo.com^n^n",Tickers)
#if defined DEBUG
	log_amx("Send cmd: %s",g_Buffer)
#endif
	socket_send(g_Socket,g_Buffer,4095)
	
	g_Buffer[0] = 0
	socket_recv(g_Socket,g_Buffer,4095)
#if defined DEBUG
	log_amx("Get cmd: %s",g_Buffer)
#endif
	
	if(!g_Buffer[0] || containi(g_Buffer,"Bad Request") != -1)
	{
		ARP_Log("Error reading data from website")
		return
	}
	
	new DataLoc = containi(g_Buffer,"octet-stream") + strlen("octet-stream") + 1
	trim(g_Buffer[DataLoc])
	
	write_file(g_WriteFile,g_Buffer[DataLoc])
	
	if(g_TradeMenu) menu_destroy(g_TradeMenu)
	g_TradeMenu = menu_create("Trade Menu","TradeMenuHandle")
	
	new Line,Ticker[12],TempCombined[64],Company[64],StockStr[10],Value[64],Quote,OldValue[64],Different
	while(read_file(g_WriteFile,Line++,g_Buffer,4095,Garbage[0]))
	{
		if(!g_Buffer[0]) continue

#if defined DEBUG
		log_amx("Read buffer: %s",g_Buffer)
#endif
		
		strtok(g_Buffer,Ticker,11,TempCombined,63,',')
		strtok(TempCombined,Company,63,StockStr,9,',')
		
		remove_quotes(Ticker)
		remove_quotes(Company)
		remove_quotes(StockStr)
		
		format(Value,63,"%s|%d",Company,Quote = floatround(str_to_float(StockStr) * 100))
		
		TravTrieGetString(g_Tickers,Ticker,OldValue,63)
		
		if(!equali(OldValue,Value))
			Different = 1
		
		TravTrieSetString(g_Tickers,Ticker,Value)
		
		format(Value,63,"%s (%s) - $%d",Company,Ticker,Quote)
		menu_additem(g_TradeMenu,Value,Ticker)
	}
	
	if(g_NumChecks > 1)
	{
		if(!g_MarketClosed && !Different)
		{
			client_cmd(0,"spk fvox/alert")
			client_print(0,print_chat,"[ARP] The stock market is now closed (overnight trading permitted).")
		}
		else if(g_MarketClosed && Different)
		{	
			client_cmd(0,"spk fvox/alert")
			client_print(0,print_chat,"[ARP] The stock market is now open.")
		}
	}
	
	g_MarketClosed = !Different
	
	delete_file(g_WriteFile)
	
	socket_close(g_Socket)
	
	g_NumChecks++
}