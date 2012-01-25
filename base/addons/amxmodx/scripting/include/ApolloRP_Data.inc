#if defined _ApolloRP_Data_included
	#endinput
#endif

#define _ApolloRP_Data_included

#include <ApolloRP>
#include <celltravtrie>

// Loads a class
// Calls forward "ARP_ClassLoaded" when complete
// Also calls the "handler" string
// Note that if it's already loaded by another plugin,
// the forward will be called instantly
// const class[] - name of the class to load
// const handler[] - local function to call when done
// data[] = "" - data to pass
// table[] = "" - table to load from (leave blank for data table)
native ARP_ClassLoad(const class[],const handler[],const data[] = "",const table[] = "")

// Saves a class
// Class:class_id - class id as given in ARP_ClassLoaded
// close=0 - whether or not to also close the class
// Note that if another plugin is using it, close
// will not completely close it until the other stops
// If close = 1, class_id will be set to 0
native ARP_ClassSave(&Class:class_id,close=0)

// Sets a hook for saving a class
// This is the best time to set values
// Don't do it right before calling a class save;
// this is a bad idea because another plugin could start
// the save before you get a chance to set anything.
// This forward guarantees that you can save it properly.
// Also note that you can call it repeatedly in order to
// change the "data" parameter.
// Class:class_id - class id as given in ARP_ClassLoaded
// const handler[] - function called when the class is being saved
// data[] - data to pass
native ARP_ClassSaveHook(Class:class_id,const handler[],const data[] = "")

// Deletes a key
// This dispatches an SQL query on the spot, so avoid using it
// excessively.
// Class:class_id - class id as given in ARP_ClassLoaded
// const key[] - the key to delete
native ARP_ClassDeleteKey(Class:class_id,const key[])

// Deletes all records in a class.
// Class:class_id - class id as given in ARP_ClassLoaded
native ARP_ClassDestroy(Class:class_id)

stock ARP_ClassSetChanged(Class:class_id,const key[],const value[])
{
	if(key[0] == '/' || key[0] == '^0') return FAILED

	new Forward = CreateMultiForward("ARP_ClassKeyChange",ET_CONTINUE,FP_CELL,FP_STRING,FP_STRING),Return
	if(!Forward || !ExecuteForward(Forward,Return,class_id,key,value))
	{
		//ARP_ThrowError(AMX_ERR_NATIVE,0,"Could not execute forward")
		set_fail_state("Could not execute forward")
		return FAILED
	}
	DestroyForward(Forward)

	if(Return)
		return FAILED

	new TravTrie:ChangedTrie
	TravTrieGetHCell(TravTrie:class_id,"/changed",ChangedTrie)

	TravTrieSetHCell(ChangedTrie,key,1)

	return SUCCEEDED
}

stock ARP_ClassGetInt(Class:class_id,const key[])
{
	if(key[0] == '/' || key[0] == '^0') return FAILED

	new Value[64],Success = TravTrieGetString(TravTrie:class_id,key,Value,63)

	return str_to_num(Value) * Success
}

stock ARP_ClassSetInt(Class:class_id,const key[],value)
{
	if(key[0] == '/' || key[0] == '^0') return FAILED

	new Value[64],OldValue[64]
	format(Value,63,"%d",value)

	TravTrieGetString(TravTrie:class_id,key,OldValue,63)

	if(str_to_num(OldValue) != value && ARP_ClassSetChanged(class_id,key,Value))
		return TravTrieSetString(TravTrie:class_id,key,Value)

	return FAILED
}

stock ARP_ClassGetFloat(Class:class_id,const key[],&Float:value)
{
	if(key[0] == '/' || key[0] == '^0') return FAILED

	new Value[64],Success = TravTrieGetString(TravTrie:class_id,key,Value,63)
	value = str_to_float(Value)

	return Success
}

stock ARP_ClassSetFloat(Class:class_id,const key[],Float:value)
{
	if(key[0] == '/' || key[0] == '^0') return FAILED

	new Value[64],OldValue[64]
	format(Value,63,"%f",value)

	TravTrieGetString(TravTrie:class_id,key,OldValue,63)

	if(str_to_float(OldValue) != value && ARP_ClassSetChanged(class_id,key,Value))
		return TravTrieSetString(TravTrie:class_id,key,Value)

	return FAILED
}

stock ARP_ClassGetString(Class:class_id,const key[],string[],len)
{
	if(key[0] == '/' || key[0] == '^0') return FAILED

	return TravTrieGetString(TravTrie:class_id,key,string,len)
}

stock ARP_ClassSetString(Class:class_id,const key[],string[])
{
	if(key[0] == '/' || key[0] == '^0') return FAILED

	static Tmp[1024]
	
	TravTrieGetString(TravTrie:class_id,key,Tmp,1023)

	if(!equal(Tmp,string) && ARP_ClassSetChanged(class_id,key,string))
		return TravTrieSetString(TravTrie:class_id,key,string)

	return FAILED
}

stock ARP_ClassSize(Class:class_id)
	return TravTrieSize(TravTrie:class_id) - 8

stock ARP_ClassClear(Class:class_id)
	return TravTrieClear(TravTrie:class_id)

stock ClassIter:ARP_ClassGetIterator(Class:class_id)
{
	new ClassIter:Iter = ClassIter:GetTravTrieIterator(TravTrie:class_id)
	ArrayPushCell(Array:Iter,class_id)

	return Iter
}

stock ARP_ClassReadKey(ClassIter:iter,key[],len)
{
	new Trie:trie = Trie:ArrayGetCell(Array:iter,0);
	
	new Array:dp;
	if(!TrieGetCell(trie,"",_:dp)) return false;
	
	new index = ArrayGetCell(Array:iter,1);
	ArrayGetString(dp,index,key,len);

	if(key[0] == '/' || key[0] == '^0') 
	{
		ArraySetCell(Array:iter,1,index + 1);
		return ARP_ClassReadKey(iter,key,len);
	}

	return true;	
}

stock ARP_ClassReadInt(ClassIter:iter)
{
	static tmp[TRAVTRIE_MAX_KEY_LEN];
	ARP_ClassReadKey(iter,tmp,1);
	new TravTrie:trie = TravTrieIteratorHandler(Array:iter,tmp,TRAVTRIE_MAX_KEY_LEN - 1);
	
	return ARP_ClassGetInt(Class:trie,tmp);
}

stock ARP_ClassReadFloat(ClassIter:iter,&Float:value)
{
	static tmp[TRAVTRIE_MAX_KEY_LEN];
	ARP_ClassReadKey(iter,tmp,1);
	new TravTrie:trie = TravTrieIteratorHandler(Array:iter,tmp,TRAVTRIE_MAX_KEY_LEN - 1);
	
	return ARP_ClassGetFloat(Class:trie,tmp,value);
}

stock ARP_ClassReadString(ClassIter:iter,string[],len)
{
	static tmp[TRAVTRIE_MAX_KEY_LEN];
	ARP_ClassReadKey(iter,tmp,1);
	new TravTrie:trie = TravTrieIteratorHandler(Array:iter,tmp,TRAVTRIE_MAX_KEY_LEN - 1);
	
	return ARP_ClassGetString(Class:trie,tmp,string,len);
}

stock ARP_ClassMoreData(ClassIter:iter)
{
	new Class:CurClass = Class:ArrayGetCell(Array:iter,2)

	if(!ARP_ClassSize(CurClass))
		return FAILED

	return MoreTravTrie(travTrieIter:iter)
}

stock ARP_ClassDestroyIterator(&ClassIter:iter)
	DestroyTravTrieIterator(travTrieIter:iter)

forward ARP_ClassLoaded(Class:class_id,const class[])

// return PLUGIN_HANDLED to block
forward ARP_ClassKeyChange(Class:class_id,const key[],const value[])
