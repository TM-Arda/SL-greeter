//////////////////////////////////////////////////////////
// [K] Kira Komarov - 2011, License: GPLv3              //
// Please see: http://www.gnu.org/licenses/gpl.html     //
// for legal details, rights of fair usage and          //
// the disclaimer and warranty conditions.              //
//////////////////////////////////////////////////////////
 
// Cross-region intercom: DATABASE KICKSTART MODULE
 
//////////////////////////////////////////////////////////
/////////////// BEGIN IMPORTED BLOCK /////////////////////
 
// This compression algorithm is created by Becky Pippen and is available @
// https://wiki.secondlife.com/wiki/User:Becky_Pippen/Text_Storage
 
//////////////////////////////////////////////////////////
//   Becky Pippen, 2009, contributed to Public Domain   //
//////////////////////////////////////////////////////////
 
string compressAscii(string s){
    integer len = llStringLength(s);
    if ((len % 2)) {
        (s += " ");
        (++len);
    }
    string encodedChars;
    integer i;
    for ((i = 0); (i < len); (i += 2)) {
        integer cInt = llBase64ToInteger(llStringToBase64(llGetSubString(s,i,i)));
        if ((!(cInt & -2147483648))) {
            (cInt = (cInt >> 24));
        }
        else  {
            if (((cInt & -536870912) == -1073741824)) {
                (cInt = (((cInt & 520093696) >> 18) | ((cInt & 4128768) >> 16)));
            }
            else  {
                (cInt = ((((cInt & 251658240) >> 12) | ((cInt & 4128768) >> 10)) | ((cInt & 16128) >> 8)));
            }
        }
        integer _cInt5 = llBase64ToInteger(llStringToBase64(llGetSubString(s,(i + 1),(i + 1))));
        if ((!(_cInt5 & -2147483648))) {
            (_cInt5 = (_cInt5 >> 24));
        }
        else  {
            if (((_cInt5 & -536870912) == -1073741824)) {
                (_cInt5 = (((_cInt5 & 520093696) >> 18) | ((_cInt5 & 4128768) >> 16)));
            }
            else  {
                (_cInt5 = ((((_cInt5 & 251658240) >> 12) | ((_cInt5 & 4128768) >> 10)) | ((_cInt5 & 16128) >> 8)));
            }
        }
        string _ret6;
        integer num = ((cInt << 7) | _cInt5);
        if (((num < 0) || (num >= 32768))) {
            (_ret6 = "�");
            jump _end7;
        }
        (num += 4096);
        integer n = (224 + (num >> 12));
        string hexChars = "0123456789abcdef";
        integer _n4 = (128 + ((num >> 6) & 63));
        string _hexChars5 = "0123456789abcdef";
        integer _n8 = (128 + (num & 63));
        string _hexChars9 = "0123456789abcdef";
        (_ret6 = llUnescapeURL(((((("%" + (llGetSubString(hexChars,(n >> 4),(n >> 4)) + llGetSubString(hexChars,(n & 15),(n & 15)))) + "%") + (llGetSubString(_hexChars5,(_n4 >> 4),(_n4 >> 4)) + llGetSubString(_hexChars5,(_n4 & 15),(_n4 & 15)))) + "%") + (llGetSubString(_hexChars9,(_n8 >> 4),(_n8 >> 4)) + llGetSubString(_hexChars9,(_n8 & 15),(_n8 & 15))))));
        @_end7;
        (encodedChars += _ret6);
    }
    return encodedChars;
}
 
string uncompressAscii(string s){
    string result;
    integer len = llStringLength(s);
    integer i;
    for ((i = 0); (i < len); (++i)) {
        string utf8 = llEscapeURL(llGetSubString(s,i,i));
        integer cInt15 = (((((((integer)("0x" + llGetSubString(utf8,1,2))) & 31) << 12) + ((((integer)("0x" + llGetSubString(utf8,4,5))) & 63) << 6)) + (((integer)("0x" + llGetSubString(utf8,7,8))) & 63)) - 4096);
        integer n = (cInt15 >> 7);
        string hexChars = "0123456789abcdef";
        integer _n7 = (cInt15 & 127);
        string _hexChars8 = "0123456789abcdef";
        (result += llUnescapeURL(((("%" + (llGetSubString(hexChars,(n >> 4),(n >> 4)) + llGetSubString(hexChars,(n & 15),(n & 15)))) + "%") + (llGetSubString(_hexChars8,(_n7 >> 4),(_n7 >> 4)) + llGetSubString(_hexChars8,(_n7 & 15),(_n7 & 15))))));
    }
    return llStringTrim(result,3);
}
 
//////////////// END IMPORTED BLOCK //////////////////////
//////////////////////////////////////////////////////////
 
list getKickstartURLs() {
    list kickStartURLs = llCSV2List(llList2String(llGetPrimitiveParams([PRIM_TEXT]), 0));
    integer itra;
    list kickstartBeacons = [];
    for(itra=0; itra<llGetListLength(kickStartURLs); ++itra) {
        // Decompression by Becky Pippen, 2009
        string newBeacon = uncompressAscii(llList2String(kickStartURLs, itra));
        if(!isValidURL(newBeacon)) jump continue;
        kickstartBeacons += newBeacon;
@continue;
    }
    return kickstartBeacons;
}
 
setKickstartURLs(list beacons) {
    list rndIndices = [];
    list selectedBeacons = [];
    integer itra;
    for(itra=0; itra<llGetListLength(beacons); ++itra) {
        rndIndices += itra;
    }
    while(llGetListLength(rndIndices) && llGetListLength(selectedBeacons) < 6) {
        integer rndPick = llList2Integer(rndIndices, (integer) llFrand(llGetListLength(rndIndices)));
        rndIndices = llDeleteSubList((rndIndices = []) + rndIndices, llListFindList(rndIndices, [ rndPick ]), llListFindList(rndIndices, [ rndPick ]));
        // Compression by Becky Pippen, 2009
        selectedBeacons += compressAscii(llList2String(beacons, rndPick));
    }
    llSetPrimitiveParams([PRIM_TEXT, llList2CSV(selectedBeacons), <0,0,0>, 0.0]);
}
 
// pragma inline
integer isValidURL(string URL) {
    if(~llSubStringIndex(URL, "http://") &&
        ~llSubStringIndex(URL, "lindenlab.com") &&
        ~llSubStringIndex(URL, "cap")) return 1;
    return 0;
}
 
default {
    link_message(integer sender_num, integer num, string str, key id) {
        if(num != 3) return;
        if(id != "@db_FETCHKICKSTART") jump section_kickstart;
        llMessageLinked(LINK_THIS, 0, llList2CSV(getKickstartURLs()), "@db_KICKSTART");
        return;
@section_kickstart;
        list msg = llParseString2List(id, ["="], [""]);
        if(llList2String(msg, 0) != "@db_SETKICKSTART") return;
        setKickstartURLs(llDeleteSubList(llCSV2List(llList2String(msg, 1)), llListFindList(llCSV2List(llList2String(msg, 1)), (list) str), llListFindList(llCSV2List(llList2String(msg, 1)), (list) str)));
    }
}
