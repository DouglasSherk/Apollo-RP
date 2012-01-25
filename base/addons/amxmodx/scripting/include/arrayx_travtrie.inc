#if defined _array_array_included
    #endinput
#endif
#define _array_array_included

#include <amxmodx>
#include <amxmisc>
#include <celltravtrie>

// Whether or not to use trie fixing mode.
//  Tries are not designed to be used as a heterogeneous container.
//  This mode defines all types as a string which can be casted
//  around to whatever data type is needed.
#define TRIE_FIX

stock array_create() return _:TravTrieCreate()

stock array_destroy(&array) 
{
	TravTrieDestroy(TravTrie:array)
	
	return true
}

stock array_clear(array)
{
	TravTrieClear(TravTrie:array)
	
	return true
}

stock array_get_nth(array,nth,start = -1,&success = 0)
{
	// this is to get rid of the warning for start being useless
	float(start)
	
	new key[64]
	success = TravTrieNth(TravTrie:array,nth - 1,key,63)
	return str_to_num(key)
}
	
stock array_isfilled(array,index)
{
#if defined TRIE_FIX
	new temp[2],result = TravTrieGetStringEx(TravTrie:array,index,temp,1)
#else
	new cell,result = TravTrieGetCellEx(TravTrie:array,index,cell)
#endif
	return result
}

stock array_isempty(array,index)
	return !array_isfilled(array,index)

stock array_delete(array,index)
	TravTrieDeleteKeyEx(TravTrie:array,index)

stock array_get_int(array,index)
{
#if defined TRIE_FIX
	static temp[64]
	TravTrieGetStringEx(TravTrie:array,index,temp,63)
	
	return str_to_num(temp)
#else
	new cell,bool:result = TravTrieGetCellEx(TravTrie:array,index,cell)
	
	return result ? cell : 0
#endif
}
	
stock array_set_int(array,index,int)
{
#if defined TRIE_FIX
	static temp[64]
	format(temp,63,"%d",int)

	return TravTrieSetStringEx(TravTrie:array,index,temp)
#else
	return TravTrieSetCellEx(TravTrie:array,index,int)
#endif
}

stock array_get_string(array,index,string[],len)
	return TravTrieGetStringEx(TravTrie:array,index,string,len)

stock array_set_string(array,index,string[])
	return TravTrieSetStringEx(TravTrie:array,index,string)

stock Float:array_get_float(array,index)
{
#if defined TRIE_FIX
	static temp[64]
	TravTrieGetStringEx(TravTrie:array,index,temp,63)
	
	return str_to_float(temp)
#else
	new cell,result = TravTrieGetCellEx(TravTrie:array,index,cell)
	
	return Float:(cell * result)
#endif
}

stock array_set_float(array,index,Float:fl)
{
#if defined TRIE_FIX
	static temp[64]
	format(temp,63,"%f",fl)

	return TravTrieSetStringEx(TravTrie:array,index,temp)
#else
	return TravTrieSetCellEx(TravTrie:array,index,_:fl)
#endif
}

stock array_first(array,index,&success = 0)
{
	new key[64]
	success = TravTrieNth(TravTrie:array,0,key,63)
	
	float(index)
	
	return str_to_num(key)
}

/*stock array_next(array,index,&success = 0)
{
	new key[64],result,cell
	for(new count;result;count++)
	{
		result = TravTrieNth(TravTrie:array,count,key,63)
		if(equali(key,""))
			continue
		
		cell = str_to_num(key)
		
		if(cell == index || index < 0)
		{			
			TravTrieNth(TravTrie:array,index < 0 ? 0 : count + 1,key,63)
			if(equali(key,""))
				TravTrieNth(TravTrie:array,index < 0 ? 1 : count + 2,key,63)
			
			new ret
			success = TravTrieGetCell(TravTrie:array,key,ret)
			return ret
		}
	}
	
	return false
}

stock array_last(array,index,&success = 0)
{
	new key[64],num,succ,lastkey[64]
	do 
	{
		lastkey = key
		succ = TravTrieNth(TravTrie:array,++num,key,63)
	}
	while(succ)
		
	if(lastkey[0]) success = 1
	
	float(index)
	
	return str_to_num(lastkey)
}*/

stock array_size(array) return TravTrieSize(TravTrie:array)
	
	