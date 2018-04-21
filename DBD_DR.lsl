//////////////////////////////////////////////////////////
// [K] Kira Komarov - 2011, License: GPLv3              //
// Please see: http://www.gnu.org/licenses/gpl.html     //
// for legal details, rights of fair usage and          //
// the disclaimer and warranty conditions.              //
//////////////////////////////////////////////////////////
 
// DPD: DATABASE DATA REPLICATOR
 
//////////////////////////////////////////////////////////
//------------------- CONFIGURATION --------------------//
//////////////////////////////////////////////////////////
 
// Time in seconds between the Distributed Primitive 
// Database (DPD) data address replication attempts.
// This determines how fast the current prim/DPD will
// attempt to connect to other prims/DPDs in your 
// network and replicate the data it contains. 
// Keep this at a sensible value, way beyond a setting of 
// 1. Do NOT be greedy and go too low on this or you will 
// overclock the script till it breaks. Sensible values 
// are well beyond 60s and it should be that way for slow 
// to moderate storage.
integer DATA_REPLICATION_TIME=5;
 
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
 
list beaconQueue = [];
list messageQueue = [];
integer gitra = 0;
 
default
{
    state_entry() {
        llSetTimerEvent(DATA_REPLICATION_TIME);
    }
 
    link_message(integer sender_num, integer num, string str, key id) {
        if(num != 2) return;
        list dbData = llParseString2List(id, ["@"], [""]);
        string reqData = llList2String(dbData, 0);
        if(!isValidURL(reqData)) return;
        dbData = llParseString2List(llList2String(dbData, 1), ["="], [""]);
        if(llList2String(dbData, 0) != "db_COMMIT") return;
        list newBeacons = llCSV2List(str);
        if(!llGetListLength(newBeacons)) return;
        integer itra;
        string cBeacon;
        for(itra=0, cBeacon = llList2String(newBeacons, itra); itra<llGetListLength(newBeacons); cBeacon = llList2String(newBeacons, ++itra)) {
            if(~llListFindList(beaconQueue, [ cBeacon ])) jump next_beacon; 
            if(isValidURL(llList2String(newBeacons, itra))) beaconQueue += [ cBeacon ];
@next_beacon;
        }
        if(~llListFindList(messageQueue, [ (reqData + "@db_REPLACE=" + llList2String(dbData, 1)) ])) return;
        messageQueue += [ (reqData + "@db_REPLACE=" + llList2String(dbData, 1)) ];
    }
 
    timer() {
        llSetTimerEvent(0);
        if(gitra >= llGetListLength(beaconQueue)) {
            messageQueue = llDeleteSubList((messageQueue = []) + messageQueue, 0, 0);
            gitra = 0;
        }
        if(isValidURL(llList2String(beaconQueue, gitra))) {
            llHTTPRequest(llList2String(beaconQueue, gitra), [HTTP_METHOD, "PUT"], llList2String(messageQueue, 0));
            jump next_beacon;
        }
        beaconQueue = llDeleteSubList((beaconQueue = []) + beaconQueue, gitra, gitra);
@next_beacon;
        ++gitra;
        llSetTimerEvent(DATA_REPLICATION_TIME);    
    }
}
