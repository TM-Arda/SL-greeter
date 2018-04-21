//////////////////////////////////////////////////////////
// [K] Kira Komarov - 2011, License: GPLv3              //
// Please see: http://www.gnu.org/licenses/gpl.html     //
// for legal details, rights of fair usage and          //
// the disclaimer and warranty conditions.              //
//////////////////////////////////////////////////////////
 
// DPD: DATABASE PROCESSOR
 
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
 
list dbKey = [];
list dbValue = [];
list dbStamp = [];
 
default
{
    link_message(integer sender_num, integer num, string str, key id) {
        if(num != 1) return;
        list dbData = llParseString2List(id, ["@", ""], [""]);
        string reqData = llList2String(dbData, 0); 
        if(!isValidURL(reqData)) return;
        dbData = llParseString2List(llList2String(dbData, 1), ["="], [""]);
        list reQ = llParseString2List(llList2String(dbData, 1), [":"], [""]);
 
        if(llList2String(dbData, 0) == "db_REPLICATE") {
            integer itra;
            for(itra=0; itra<llGetListLength(dbKey); ++itra) {
                string timeStamp = llList2String(dbStamp, itra);
                if(timeStamp == "")
                    timeStamp = "0";
                llMessageLinked(LINK_THIS, 2, str, reqData + "@db_COMMIT=" + llList2String(dbKey, itra) + ":" + llList2String(dbValue, itra) + ":" + timeStamp); 
            }
            return;
        }
 
        if(llList2String(dbData, 0) == "db_REPLACE") {
            integer itra;
            for(itra=0; itra<llGetListLength(dbKey); ++itra) {
                if(llList2String(dbKey, itra) == llList2String(reQ, 0) && llGetListLength(reQ) == 3 && llList2Integer(reQ, 2) > llList2Integer(dbStamp, itra)) {
                    dbValue = llListReplaceList((dbValue = []) + dbValue, [ llList2String(reQ, 1) ], itra, itra);
                    dbStamp = llListReplaceList((dbStamp = []) + dbStamp, [ llList2String(reQ, 2) ], itra, itra);
                    return;
                }
                if(llList2String(dbKey, itra) == llList2String(reQ, 0) && llGetListLength(reQ) == 3 && llList2Integer(reQ, 2) <= llList2Integer(dbStamp, itra)) return;
                if(llList2String(dbKey, itra) == llList2String(reQ, 0) && llGetListLength(reQ) == 2) {
                    dbValue = llListReplaceList((dbValue = []) + dbValue, [ llList2String(reQ, 1) ], itra, itra);
                    dbStamp = llListReplaceList((dbStamp = []) + dbStamp, [ llGetUnixTime() ], itra, itra);
                    return;
                }
            }
            dbKey += llList2String(reQ, 0);
            dbValue += llList2String(reQ, 1);
            dbStamp += llGetUnixTime();
            return;
        }
 
        if(llList2String(dbData, 0) == "db_FETCH") {
            integer itra;
            for(itra=0; itra<llGetListLength(dbKey); ++itra) {
                if(llList2String(dbKey, itra) == llList2String(reQ, 0)) {
                    if(!isValidURL(reqData)) return;
                    llHTTPRequest(reqData, [HTTP_METHOD, "PUT"], llList2String(dbValue, itra));
                    return;
                }
            }
            if(!isValidURL(reqData)) return; 
            llHTTPRequest(reqData, [HTTP_METHOD, "PUT"], "N/A");
            return;
        }
    }
}
