//////////////////////////////////////////////////////////
// [K] Kira Komarov - 2011, License: GPLv3              //
// Please see: http://www.gnu.org/licenses/gpl.html     //
// for legal details, rights of fair usage and          //
// the disclaimer and warranty conditions.              //
//////////////////////////////////////////////////////////
 
// DPD: DATABASE TEST MODULE
 
default
{
    state_entry()
    {
        llListen(0, "", llGetOwner(), "");
    }
 
    listen(integer chan,string name,key id,string mes) {
        if(~llSubStringIndex(mes, "@db_FETCH") || ~llSubStringIndex(mes, "@db_REPLACE"))
            llMessageLinked(LINK_THIS, 0, mes, "49c11b5dfa51597b3021578810a1ebd2");
    }
 
    link_message(integer sender_num, integer num, string str, key id) {
        if(id != "db_ANSWER") return;
        llSay(0, "DB3 answer: " + str);
    }
}
