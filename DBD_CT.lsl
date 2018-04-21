//////////////////////////////////////////////////////////
// [K] Kira Komarov - 2011, License: GPLv3              //
// Please see: http://www.gnu.org/licenses/gpl.html     //
// for legal details, rights of fair usage and          //
// the disclaimer and warranty conditions.              //
//////////////////////////////////////////////////////////
 
// DPD: DATABASE CLIENT
 
//////////////////////////////////////////////////////////
//------------------- CONFIGURATION --------------------//
//////////////////////////////////////////////////////////
 
// Time in seconds between the Distributed Primitive 
// Database (DPD) URL address replication attempts.
// This determines how fast the current prim/DPD will
// attempt to connect to other prims/DPDs in your 
// network. Keep this at a sensible value, way beyond a 
// setting of 1. Do NOT be greedy and go too low on this
// or you will overclock the script till it breaks.
// Sensible values are well beyond 60s and it should be that
// way for slow to moderate storage.
integer URL_REPLICATION_TIME = 5;
// This is your whole Distributed Primitive Database (DPD) 
// network password. Nobody would be able to hook up to your 
// network unless they know this password. Make sure it is 
// something unique. If you want a good password, google for an 
// md5 hash generator and use that. ALL the prims in your 
// Distributed Primitive Database (DPD) network must have the 
// same password that you enter here. It can be anything you 
// choose but WITHOUT SPACES and without PUNCTUATION MARKS/SYMBOLS. 
string DATABASE_PASSWORD = "49c11b5dfa51597b3021578810a1ebd2";
 
//////////////////////////////////////////////////////////
//--------------------- INTERNALS ----------------------//
//////////////////////////////////////////////////////////
 
// pragma inline
integer isValidURL(string URL) {
    if(~llSubStringIndex(URL, "http://") &&
        ~llSubStringIndex(URL, "lindenlab.com") &&
        ~llSubStringIndex(URL, "cap")) return 1;
    return 0;
}
 
integer dbON = 1;
integer menuHandle = 0;
integer registerHandle = 0;
list urlBeacons = [];
integer urlBeaconsNum = 0;
string selfURL = "";
integer gitra;
integer gitrb;
 
default 
{
    state_entry() {
        llReleaseURL(selfURL);
        selfURL = "";
        llRequestURL();
        llMessageLinked(LINK_THIS, 3, "", "@db_FETCHKICKSTART");
        llSetTimerEvent(URL_REPLICATION_TIME);
    }
 
    changed(integer change) {
        if(change & CHANGED_REGION_START || change & CHANGED_REGION) {
            llReleaseURL(selfURL);
            selfURL = "";
            llRequestURL();
            llMessageLinked(LINK_THIS, 3, "", "@db_FETCHKICKSTART");
            llSetTimerEvent(URL_REPLICATION_TIME);
        }
    }
 
    on_rez(integer pin) {
        llReleaseURL(selfURL);
        selfURL = "";
        llRequestURL();
        llMessageLinked(LINK_THIS, 3, "", "@db_FETCHKICKSTART");
        llSetTimerEvent(URL_REPLICATION_TIME);
    }
 
    timer() {
        llSetTimerEvent(0);
        if(gitrb >= llGetListLength(urlBeacons)) {
            ++gitra;
            gitrb = 0;
        }
        if(gitra >= llGetListLength(urlBeacons)) {
            gitra=0;
        }
        if(isValidURL(llList2String(urlBeacons, gitra)) && isValidURL(llList2String(urlBeacons, gitrb)))
            llHTTPRequest(llList2String(urlBeacons, gitra), [HTTP_METHOD, "POST"], llList2String(urlBeacons, gitrb) + " " + DATABASE_PASSWORD);
        ++gitrb;
        llMessageLinked(LINK_THIS, 3, selfURL, "@db_SETKICKSTART=" + llList2CSV(urlBeacons));
        llMessageLinked(LINK_THIS, 1, llList2CSV(urlBeacons), selfURL + "@db_REPLICATE");
        llSetTimerEvent(URL_REPLICATION_TIME);
    }
 
    touch_start(integer total_number) {
        if(llDetectedKey(0) != llGetOwner()) return;
        integer comChannel = ((integer)("0x"+llGetSubString((string)llGetKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF;
        menuHandle = llListen(comChannel, "", llGetOwner(), "");
        llDialog(llGetOwner(), "Welcome to the Distributed Primitive Database (DPD) Client:\n\nAdd URL: Use this to add a new DPD.\n\nMy URL: Use this to get the address of this DPD.\n\List URLs: Use this to list all the linked DPDs.\n\nReset: Use this to permanently reset the current DPD since resettting the script will not unlink it from the network.\n\nOn/Off: This will turn the DPD on and off. It will remain connected to the network but will not receive or broadcast messages.\n\nList URLs: Use this to get a list of linked DPDs.", ["[ Add URL ]", "[ My URL ]", "[ List URLs ]", "[ Reset ]", "[ On ]", "[ Off ]"], comChannel);
    }
 
    listen(integer chan,string name,key id,string mes) {
        if(mes == "[ On ]") {
            dbON = 1;
            llOwnerSay("Distributed Primitive Database (DPD) is now: ON");
            jump close_chans;
        }
        if(mes == "[ Off ]") {
            dbON = 0;
            llOwnerSay("Distributed Primitive Database (DPD) is now: OFF");
            jump close_chans;
        }
        if(mes == "[ Reset ]") {
            llSetTimerEvent(0);
            llSetPrimitiveParams([PRIM_TEXT, "", <0,0,0>, 0.0]);
            llResetScript();
            return;
        }
        if(mes == "[ Add URL ]") {
            llOwnerSay("Please paste an URL on channel " + (string)89 + " in order to register it with the system by typing:\n/" + (string)89 + " URL\nWhere URL is the URL of another Distributed Primitive Database (DPD).");
            registerHandle = llListen(89, "", id, "");
            jump close_menu;
        }
        if(mes == "[ My URL ]") {
            if(selfURL == "") {
                llOwnerSay("I don't have an URL registered yet.");
                jump close_chans;
            }
            llOwnerSay("My URL is: " + selfURL);
            jump close_chans;
        }
        if(mes == "[ List URLs ]") {
            if(!llGetListLength(urlBeacons)) {
                llOwnerSay("No beacons registered.");
                jump close_chans;
            }
            integer itra;
            llOwnerSay("----- REGISTERED DATABASES -----");
            for(itra=0; itra<llGetListLength(urlBeacons); ++itra) {
                llOwnerSay(llList2String(urlBeacons, itra));
            }
            llOwnerSay("----- REGISTERED DATABASES -----");
            jump close_chans;
        }
        if(chan != 89) return;
        mes = llList2String(llParseString2List(mes, [" "], [""]), 0);
        if(!isValidURL(mes)) {
            llOwnerSay("Bad formatted URL");
            return;
        }
        if(~llListFindList(urlBeacons, [ mes ])) {
            llOwnerSay("URL already exists.");
            jump close_chans;
        }
        urlBeacons += mes;
        llOwnerSay("URL: " + mes + " has been registered.");
@close_chans;
        llListenRemove(registerHandle);
@close_menu;
        llListenRemove(menuHandle);
    }
 
    link_message(integer sender_num, integer num, string str, key id) {
        if(num != 0) return;
        if(id != "@db_KICKSTART") jump client;
        list kickstartBeacons = llCSV2List(str);
        integer itra;
        for(itra=0; itra<llGetListLength(kickstartBeacons); ++itra) {
            if(~llListFindList(urlBeacons, (list)llList2String(kickstartBeacons, itra)) || !isValidURL(llList2String(kickstartBeacons, itra))) jump continue;
            urlBeacons += [ llList2String(kickstartBeacons, itra) ];
@continue;
        }
        return;
@client;
        if(id != DATABASE_PASSWORD) return;
        if(!isValidURL(selfURL)) return;
        list qBeacons = llDeleteSubList(urlBeacons, llListFindList(urlBeacons, (list)selfURL), llListFindList(urlBeacons, (list)selfURL));
        string sendURL = llList2String((qBeacons = [] + qBeacons), (integer)llFrand(llGetListLength(qBeacons)));
        if(!isValidURL(sendURL)) return;
        llHTTPRequest(sendURL, [HTTP_METHOD, "PUT"], selfURL + str);
 
    }
 
    http_request(key id, string method, string body) {
        if(method == URL_REQUEST_GRANTED) {
            selfURL = body;
            urlBeacons += body;
            return;
        }
        if(method == URL_REQUEST_DENIED) {
            llRequestURL();
            return;
        }
        if(method == "POST") {
            list postPayload = llParseString2List(body, [" "], [""]);
            if(!isValidURL(llList2String(postPayload, 0))) return;;
            if(llList2String(postPayload, 1) != DATABASE_PASSWORD) return;
            if(~llListFindList(urlBeacons, (list)llList2String(postPayload, 0))) return;
            urlBeacons += llList2String(postPayload, 0);
            llHTTPResponse(id, 200, "OK");
            return;
        }
        if(method == "PUT") {
            if(~llSubStringIndex(body, "@db_REPLACE") || ~llSubStringIndex(body, "@db_FETCH")) return;
            llMessageLinked(LINK_THIS, 1, body, "db_ANSWER");
            llHTTPResponse(id, 200, "OK");
            return;
        }
    } 
 
    http_response(key id, integer status, list metadata, string body) {
        if(status == 404) {
            string badBeaconKey = llList2String(llParseString2List(body, [": ", "'"], [""]), 1);
            integer itra;
            for(itra=0; itra<llGetListLength(urlBeacons); ++itra) {
                if(~llSubStringIndex(llList2String(urlBeacons, itra), badBeaconKey))
                    urlBeacons = llDeleteSubList((urlBeacons = []) + urlBeacons, itra, itra);
            }
        }
    }
}
