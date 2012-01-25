#if defined _cell_travtrie_included
 #endinput
#endif
#define _cell_travtrie_included

#include <cellarray>
#include <celltrie>

//
//#define HOMOGENEOUS_MODE

//#define __TRAVTRIE_DEBUG

enum TravTrie
{
    Invalid_TravTrie = 0
}

new __TotalTravTries

#define TRAVTRIE_MAX_KEY_LEN 1024

stock g_Key[TRAVTRIE_MAX_KEY_LEN]
stock g_Value[TRAVTRIE_MAX_KEY_LEN]

#if defined __TRAVTRIE_DEBUG
public plugin_cfg()
    register_concmd("totaltravtries","CmdTotalTravTries")

public CmdTotalTravTries(id)
{
    new file[33]
    get_plugin( -1, file, 32, "", 0, "", 0, "", 0, "", 0 )
    id ? console_print( id, "[[[%s]]] %d", file, __TotalTravTries ) : log_amx( "[[[%s]]] %d", file, __TotalTravTries )
}
#endif

stock TravTrie:TravTrieCreate(keylength = 64, startsize = 32)
{
#if defined __TRAVTRIE_DEBUG
    if ( __TotalTravTries++ > 1000 )
    {
        log_amx( "halting here" )
        set_user_health(33,100)
    }
#endif
        
    new Trie:tmp = TrieCreate();
    TrieSetCell(tmp, "", _:ArrayCreate(keylength, startsize));
    return TravTrie:tmp;
}

stock TravTrieDestroy(&TravTrie:trie)
{
    __TotalTravTries--
    new Array:iter;
    if(!TrieGetCell(Trie:trie,"",any:iter)) { TrieDestroy(Trie:trie); return; }

    ArrayDestroy(iter);
    TrieDestroy(Trie:trie);
}

/* Hawk552: Set a cell casted from a cell to a string. This
    preserves homogeneity */
#if defined HOMOGENEOUS_MODE
stock bool:TravTrieSetHCell(TravTrie:trie, const key[], any:cell)
{
    if(key[0] == '^n') return false;

    static value[64];
    format(value,63,"%d",cell);    
    
    new val[4];
    if(!TrieKeyExists(Trie:trie,key) || !TravTrieGetString(trie, key, val,sizeof(val)) )
    {
        new Array:iter;
        if(!TrieGetCell(Trie:trie,"",any:iter)) return false;
    
        ArrayPushString(iter,key);
    }
    
    if(key[0] == '^n') return false;
    
    TrieSetString(Trie:trie,key,value);
    return true;
}
#else
#define TravTrieSetHCell TravTrieSetCell
#endif

stock bool:TravTrieSetCell(TravTrie:trie, const key[], any:value)
{
    if(key[0] == '^n') return false;
    
    new any:val;
    if(!TrieKeyExists(Trie:trie,key) || !TravTrieGetCell(trie, key, val) )
    {
        new Array:iter;
        if(!TrieGetCell(Trie:trie,"",any:iter)) return false;
    
        ArrayPushString(Array:iter,key);
    }
    if(key[0] == '^n') return false;
    
    TrieSetCell(Trie:trie,key,value);
    return true;
}

stock bool:TravTrieSetArray(TravTrie:trie, const key[], const array[], num_items)
{
    if(key[0] == '^n') return false;
    
    new val[2];
    if(!TrieKeyExists(Trie:trie,key) || !TravTrieGetArray(trie, key, val,sizeof(val)) )
    {
        new Array:iter;
        if(!TrieGetCell(Trie:trie,"",any:iter)) return false;
    
        ArrayPushString(iter,key);
    }
    
    if(key[0] == '^n') return false;
    
    TrieSetArray(Trie:trie,key,array,num_items);
    return true;
}

stock bool:TravTrieSetString(TravTrie:trie, const key[], value[])
{
    if(key[0] == '^n') return false;

    if(equali(key,"")) return false;
    
    new val[4];
    if(!TrieKeyExists(Trie:trie,key) || !TravTrieGetString(trie, key, val,sizeof(val)) )
    {
        new Array:iter;
        if(!TrieGetCell(Trie:trie,"",any:iter)) return false;
    
        ArrayPushString(iter,key);
    }
    
    if(key[0] == '^n') return false;
    
    TrieSetString(Trie:trie,key,value);
    return true;
}

/* Hawk552: Get a cell casted from a string to a cell. This
    preserves homogeneity */
#if defined HOMOGENEOUS_MODE
stock bool:TravTrieGetHCell(TravTrie:trie, const key[], &any:value)
{
    if(key[0] == '^n' || !TrieKeyExists(Trie:trie,key)) return false;

    static temp[64],bool:result;
    result = TrieGetString(Trie:trie,key,temp,63)
    value = str_to_num(temp);

    return result;
}
#else
#define TravTrieGetHCell TravTrieGetCell
#endif

stock bool:TravTrieGetCell(TravTrie:trie, const key[], &any:value)
{
    return (/*!TrieKeyExists(Trie:trie,key) ||*/ key[0] == '^n') ? false : TrieGetCell(Trie:trie,key,value);
}

stock bool:TravTrieGetArray(TravTrie:trie, const key[], any:array[], num_items)
{
    return (!TrieKeyExists(Trie:trie,key) || key[0] == '^n') ? false : TrieGetArray(Trie:trie,key,array,num_items);
}

stock bool:TravTrieGetString(TravTrie:trie, const key[], value[], max_size)
{
    return (!TrieKeyExists(Trie:trie,key) || key[0] == '^n') ? false : TrieGetString(Trie:trie,key,value,max_size);
}

stock bool:TravTrieDeleteKey(TravTrie:trie, const key[])
{
    if(!TrieKeyExists(Trie:trie,key)) return false;

    if(key[0] != '^n' && TrieDeleteKey(Trie:trie,key) )
    {
        new Array:iter;
        if(!TrieGetCell(Trie:trie,"",any:iter)) return false;
    
        static tmp[TRAVTRIE_MAX_KEY_LEN];
        new index = 0;

        while(index < ArraySize(iter) )
        {
            ArrayGetString(iter, index, tmp, TRAVTRIE_MAX_KEY_LEN - 1);
            if(equal(tmp,key)) return (ArrayDeleteItem(iter, index) == 1);
            index++;
        }
    }
    return false;
}

stock TravTrieClear(TravTrie:trie)
{
    new Array:iter;
    if(!TrieGetCell(Trie:trie,"",any:iter)) { TrieClear(Trie:trie); return; }

    ArrayClear(iter);
    TrieClear(Trie:trie);
}

//stock TravTrieSize(TravTrie:trie) return TrieGetSize(trie) - 1;

// Rukia: Use this to prepare the TravTrie for SORTED traversal
//    If you do not use this, it will be traversed in FIFO order
stock bool:PrepareTravTrie(TravTrie:trie) 
{
    new Array:iter;
    if(!TrieGetCell(Trie:trie,"",any:iter)) { TrieClear(Trie:trie); return; }

    ArraySort(iter, "SortADTArrayDesc");
}

public SortADTArrayDesc(Array:array, item1, item2, const data[], data_size)
{
    static item1str[TRAVTRIE_MAX_KEY_LEN], item2str[TRAVTRIE_MAX_KEY_LEN]
    ArrayGetString(array,item1,item1str,TRAVTRIE_MAX_KEY_LEN - 1);
    ArrayGetString(array,item2,item2str,TRAVTRIE_MAX_KEY_LEN - 1);

    return strcmp ( item2str, item1str );
}

// Rukia: Get a mutable iterator to the travtrie
//    This Handle MUST be closed using CloseHandle, and delete/insert will invalidate iterator
stock travTrieIter:GetTravTrieIterator(TravTrie:trie)
{
    new Array:dp = ArrayCreate();
    ArrayPushCell(dp,_:trie);
    ArrayPushCell(dp,0);
    return travTrieIter:dp;
}

// Rukia: Read the string key that the iterator points to.
//    WILL NOT INCREMENT ITERATOR
stock bool:ReadTravTrieKey(travTrieIter:dp,key[],len)
{
    new Trie:trie = Trie:ArrayGetCell(Array:dp,0);
    
    new Array:iter;
    if(!TrieGetCell(trie,"",_:iter)) return false;
    
    new index = ArrayGetCell(Array:dp,1);
    ArrayGetString(iter,index,key,len);

    return true;
}

stock TravTrieSize(TravTrie:trie)
{
    new Array:iter;
    if(!TravTrieGetCell(trie,"",_:iter)) return false;

    return ArraySize(iter);
}

// Rukia: These functions read from the travtrie via the iterator
//    They WILL INCREMENT THE ITERATOR

#if defined HOMOGENEOUS_MODE
stock bool:ReadTravTrieHCell(travTrieIter:dp,&any:value)
{
    static tmp[TRAVTRIE_MAX_KEY_LEN],strtemp[64];
    new TravTrie:trie = TravTrieIteratorHandler(Array:dp,tmp,TRAVTRIE_MAX_KEY_LEN - 1);
	new result = TravTrieGetString(trie,tmp,strtemp,63)
    
    return result ? str_to_num(strtemp) : 0;
}
#else
#define ReadTravTrieHCell ReadTravTrieCell
#endif

stock bool:ReadTravTrieCell(travTrieIter:dp,&any:value)
{
    static tmp[TRAVTRIE_MAX_KEY_LEN];
    new TravTrie:trie = TravTrieIteratorHandler(Array:dp,tmp,TRAVTRIE_MAX_KEY_LEN - 1);
    
    return TravTrieGetCell(trie,tmp,value);
}

stock bool:ReadTravTrieArray(travTrieIter:dp, value[], max_num)
{
    static tmp[TRAVTRIE_MAX_KEY_LEN];
    new TravTrie:trie = TravTrieIteratorHandler(Array:dp,tmp,TRAVTRIE_MAX_KEY_LEN - 1);
    
    return TravTrieGetArray(trie,tmp,value,max_num);
}

stock bool:ReadTravTrieString(travTrieIter:dp, value[], max_num)
{
    static tmp[TRAVTRIE_MAX_KEY_LEN];
    new TravTrie:trie = TravTrieIteratorHandler(Array:dp,tmp,TRAVTRIE_MAX_KEY_LEN - 1);
    
    return TravTrieGetString(trie,tmp,value,max_num);
}

stock TravTrie:TravTrieIteratorHandler(Array:dp,pos[],len)
{
    new Trie:trie = Trie:ArrayGetCell(dp,0);
    
    new Array:iter;
    if(!TrieGetCell(trie,"",any:iter)) return TravTrie:Invalid_Trie;
    
    new index = ArrayGetCell(dp,1);
    ArrayGetString(iter,index,pos,len);
    
    ArraySetCell(dp,1,index + 1);
    
    return TravTrie:trie;
}

// Rukia: Returns true if there is more to read from the iterator

stock bool:MoreTravTrie(travTrieIter:dp)
{
    new Trie:trie = Trie:ArrayGetCell(Array:dp,0);
    
    new Array:iter;
    if(!TrieGetCell(trie,"",any:iter)) return false;
    
    new index = _:ArrayGetCell(Array:dp,1);
    if(ArraySize(iter) <= index) return false;
    
    return true;
}

stock DestroyTravTrieIterator(&travTrieIter:dp)
{
    ArrayDestroy(Array:dp);
}

stock bool:TravTrieDeleteKeyEx(TravTrie:trie, key)
{
    formatex(g_Key,TRAVTRIE_MAX_KEY_LEN - 1,"%d",key);

    return TravTrieDeleteKey(trie,g_Key);
}

//stock TravTrieSize(TravTrie:trie) return TrieGetSize(trie) - 1;

// Hawk: Gets the nth key, starting at 0

stock bool:TravTrieNth(TravTrie:trie, nth, key[], len)
{
    new Array:iter;
    PrepareTravTrie(trie);
    if(!TravTrieGetCell(trie,"",iter)) return false;
    
    new value[TRAVTRIE_MAX_KEY_LEN], result = ArrayGetString(iter,nth,value,TRAVTRIE_MAX_KEY_LEN - 1);
    copy(key,len,value);

    return bool:result;
}

stock bool:TravTrieNthEx(TravTrie:trie,nth,&key)
{
    new bool:result = TravTrieNth(trie,nth,g_Key,TRAVTRIE_MAX_KEY_LEN - 1);
    key = str_to_num(g_Key);
    
    return result;
}

// Hawk: Extended functions for passing an integer as a key

stock bool:TravTrieGetCellEx(TravTrie:trie, key, &any:value)
{
    formatex(g_Key,TRAVTRIE_MAX_KEY_LEN - 1,"%d",key);
    new tempvalue, bool:result = TravTrieGetCell(trie,g_Key,tempvalue);
    value = tempvalue;
    return result;
}

stock bool:TravTrieGetStringEx(TravTrie:trie, key, value[], len)
{
    formatex(g_Key,TRAVTRIE_MAX_KEY_LEN - 1,"%d",key);
    new bool:result = TravTrieGetString(trie,g_Key,g_Value,TRAVTRIE_MAX_KEY_LEN - 1);
    copy(value,abs(min(len,TRAVTRIE_MAX_KEY_LEN - 1)),g_Value);

    return result;
}

stock bool:TravTrieGetArrayEx(TravTrie:trie, key, any:value[], len)
{
    formatex(g_Key,TRAVTRIE_MAX_KEY_LEN - 1,"%d",key);
    new result = TravTrieGetArray(trie,g_Key,g_Value,abs(min(TRAVTRIE_MAX_KEY_LEN,len)));
    for(new count; count < len; count++)
        value[count] = g_Value[count];

    return result;
}

stock bool:TravTrieSetCellEx(TravTrie:trie, key, any:value)
{
    formatex(g_Key,TRAVTRIE_MAX_KEY_LEN - 1,"%d",key);
    return TravTrieSetCell(trie,g_Key,value);
}

stock bool:TravTrieSetStringEx(TravTrie:trie, key, value[])
{
    formatex(g_Key,TRAVTRIE_MAX_KEY_LEN - 1,"%d",key);
    return TravTrieSetString(trie,g_Key,value);
}

stock bool:TravTrieSetArrayEx(TravTrie:trie, key, any:value[], len)
{
    formatex(g_Key,TRAVTRIE_MAX_KEY_LEN - 1,"%d",key);
    return TravTrieSetArray(trie,g_Key,value,len);
}

/*
#define TravTrieSetCellEx(%1,%2,%3) format(g_Key,TRAVTRIE_MAX_KEY_LEN - 1,"%d",%2); TravTrieSetCell(%1,g_Key,%3);
#define TravTrieSetArrayEx(%1,%2,%3,%4) format(g_Key,TRAVTRIE_MAX_KEY_LEN - 1,"%d",%2); TravTrieSetArray(%1,g_Key,%3,%4);
#define TravTrieSetStringEx(%1,%2,%3) format(g_Key,TRAVTRIE_MAX_KEY_LEN - 1,"%d",%2); TravTrieSetString(%1,g_Key,%3);
#define TravTrieGetCellEx(%1,%2,%3) format(g_Key,TRAVTRIE_MAX_KEY_LEN - 1,"%d",%2); TravTrieGetCell(%1,g_Key,%3);
#define TravTrieGetArrayEx(%1,%2,%3,%4) format(g_Key,TRAVTRIE_MAX_KEY_LEN - 1,"%d",%2); TravTrieGetArray(%1,g_Key,%3,%4);
#define TravTrieGetStringEx(%1,%2,%3,%4) format(g_Key,TRAVTRIE_MAX_KEY_LEN - 1,"%d",%2); TravTrieGetString(%1,g_Key,%3,%4);
*/

stock bool:ReadTravTrieKeyEx(travTrieIter:dp,&key)
{
    new bool:result = ReadTravTrieKey(dp,g_Key,TRAVTRIE_MAX_KEY_LEN - 1);
    key = str_to_num(g_Key);

    return result;
}
