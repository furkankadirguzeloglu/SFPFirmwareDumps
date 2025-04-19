function update_node(obj,prefix)
{
    for(prop in obj){
        if($("#"+(prefix?prefix:"")+prop).length){
            $("#"+prop).html(obj[prop])
        }
    }
}
String.prototype.trim=function()
{
    return this.replace(/(^\s*)|(\s*$)/g,"");
}
String.prototype.isdd=function()
{
    return this.match(/^\d+$/);
}

function ValidNumberInStr(text) {
    return text.match(/[0-9]/g)!=null;
}

function ValidUpperCaseInStr(text) {
    return text.match(/[A-Z]/g)!=null;
}

function ValidLowerCaseInStr(text) {
    return text.match(/[a-z]/g)!=null;
}

function ValidCheckForText(text, input, alertInfo) {
    if(alertInfo.numberError && (ValidNumberInStr(text)==false)) {
        alert(alertInfo.numberError);
        input.focus();
        return false;
    }

    if(alertInfo.upperCaseError && (ValidUpperCaseInStr(text)==false)) {
        alert(alertInfo.upperCaseError);
        input.focus();
        return false;
    }

    if(alertInfo.lowerCaseError && (ValidLowerCaseInStr(text)==false)) {
        alert(alertInfo.lowerCaseError);
        input.focus();
        return false;
    }
}


function ValidUrlStr(urlStr)
{
   tstr=urlStr.trim()
   if(/[#\\\'+\," ]/.test(tstr))
   {
      return false;
   }
   if(!(/[A-Za-z0-9]/.test(tstr)))
   {
      return false;
   }
   if(!(/^(?:(?:(?:https?|ftp):)?\/\/)(?:\S+(?::\S*)?@)?(?:(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)(?:\.(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)*(?:\.(?:[a-z\u00a1-\uffff]{2,})).?)(?::\d{2,5})?(?:[/?#]\S*)?$/i .test(tstr)))
   {
      return false;
   }
   urlhead = tstr.split(':');
   if( urlhead[0] == "http" || urlhead[0] == "https" || urlhead[0] == "ftp" || urlhead[0] == "file" || urlhead[0] == "MMS"   || urlhead[0] == "ed2k"  || urlhead[0] == "Flashget"  || urlhead[0] == "thunder" )
   {
      if(!(/:\/\//.test(tstr)))
      {
         alert("URL is not right!");
          return false;
      }
   }
   return true;

}
function ValidPortNum(portNumStr)
{
    tstr=portNumStr.trim()
    if(tstr=="") return false;
    if(!(/^\d{1,5}$/.test(tstr))) return false;
	var portNum = parseInt(tstr);
    return (portNum<=65535&&portNum>=0)
}
function ValidIpStr(ipStr)
{
    tstr=ipStr.trim()
    if(tstr=="")return false;
    if(!(/^(\d{1,3}\.){3}\d{1,3}$/.test(tstr)))return false;

    nos= tstr.split(".");
    for(var i in nos){
        if(nos[i]<0 || nos[i]>255){
            return false;
        }
    }
    return true;
}

function isValidIpAddress(address)
{
	ipParts = address.split('/');
	if (ipParts.length > 2) return false;
	if (ipParts.length == 2) {
		num = parseInt(ipParts[1]);
		if (num <= 0 || num > 32)
			return false;
	}

	if (ipParts[0] == '0.0.0.0' || ipParts[0] == '255.255.255.255')
		return false;

	addrParts = ipParts[0].split('.');
	if ( addrParts.length != 4 ) { 
		return false;
	}
	
	if ('0' == addrParts[0]) {
		return false;
	}
	
	for (i = 0; i < 4; i++) {
		if (isNaN(addrParts[i]) || addrParts[i] =="")
			return false;
		num = parseInt(addrParts[i]);
		if ( num < 0 || num >= 255 )
			return false;
	}
	return true;
}

function ValidSpecialIp(ipStr)
{
    tstr=ipStr.trim()
    if(tstr=="")return false;
    if(!(/^(\d{1,3}\.){3}\d{1,3}$/.test(tstr)))return false;

    nos= tstr.split(".");
    if((nos[0]=="192")&&(nos[1]=="168")&&(nos[2]=="2")){
            return false;
    }
    
    return true;
}


function ValidMaskStr(maskStr)
{
    tstr=maskStr.trim()
	if(tstr=="") return false;
    if(!(/^(\d{1,3}\.){3}\d{1,3}$/.test(tstr)))return false;

    nary= tstr.split(".");
    for(var i in nary){
        if(nary[i]<0 || nary[i]>255){
            return false;
        }
    }
    var _n2bin=function(ipInt){ return (parseInt(ipInt)+256).toString(2).substring(1); }
    var bin_str = _n2bin(nary[0]) + _n2bin(nary[1]) + _n2bin(nary[2]) + _n2bin(nary[3]);
    if(-1 != bin_str.indexOf("01"))return false;
    else return bin_str.indexOf("0")+256;
}
function ValidMacAddress(macStr)
{
    tstr=macStr.trim();
   	if(!(/^([0-9A-Fa-f]{1,2}:){5}[0-9A-Fa-f]{1,2}$/.test(tstr)) || tstr.length != 17) return false;
	else return true;
}
function ValidMacAddress2(macStr)
{
    //Added new routine to overcome duplicate and invalid mac entries issue ALU02136333
    valid_macaddr=/^([0-9a-f]{2}([:-]|$)){6}$|([0-9a-f]{4}([.]|$)){3}$/i;
    if (valid_macaddr.test(macStr.trim()) && macStr.trim().length == 17)
        return true;
    else
        return false;
}
function ValidAscii(str)
{
    return !/[^\x00-\xff]/g.test(str);
}
function ValidInput(str)
{
    return !/[\"\'<>]/g.test(str);
}
function ip2int(ipstr){
    var aip=ipstr.split("."); 
    for(var i in aip) {
        if(parseInt(aip[i])<16) {
            aip[i]="0"+parseInt(aip[i]).toString(16);
        } else {
            aip[i]=parseInt(aip[i]).toString(16);
        }
    }
    var nip=parseInt("0x"+aip[0]+aip[1]+aip[2]+aip[3])
    return nip;
}
function checkipv6(str)
{
    if(!str.trim())return false;
    var t=str.split("/");
    ipstr=t[0];
    if (! /^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$/.test(ipstr) )
        return false;
    pl=t[1];
    if(pl){
        if(pl.isdd() && parseInt(pl)>=0 && parseInt(pl)<=128){
            return true;
        }
        return false;
    }
    return true;
}

function check_ipv6_prefix(str_prefix)
{
	if((str_prefix.search("::/64") == -1) || str_prefix.match(new RegExp("::/64","g")).length > 1 || !(/.*::\/64$/.test(str_prefix)))
		return false;
	if(str_prefix.split("::/64")[0] == "")
		return true;
	var prefix_addr = str_prefix.split("::/64")[0].split(":");
	if(prefix_addr.length > 4)
		return false;
	for(var i = 0; i < prefix_addr.length; i++)
	{
		if(!(/^[0-9A-Fa-f]{1,4}$/.test(prefix_addr[i])))
			return false;
	}
	return true;
}

var urlParams = {};
(function () {
    var e,
        a = /\+/g,  // Regex for replacing addition symbol with a space
        r = /([^&=]+)=?([^&]*)/g,
        d = function (s) { return decodeURIComponent(s.replace(a, " ")); },
        q = window.location.search.substring(1);

    while (e = r.exec(q))
       urlParams[d(e[1])] = d(e[2]);
})();

/* @projectDescription jQuery Serialize Anything - Serialize anything (and not just forms!)
* @author Bramus! (Bram Van Damme)
* @version 1.0
* @website: http://www.bram.us/
* @license : BSD
*/

(function($) {

    $.fn.serializeAnything = function() {

        var toReturn    = [];
        var els         = $(this).find(':input').get();

        $.each(els, function() {
            if (this.name && !this.disabled && (this.checked || /select|textarea/i.test(this.nodeName) || /text|hidden|password/i.test(this.type))) {
                var val = $(this).val();
                toReturn.push( encodeURIComponent(this.name) + "=" + encodeURIComponent( val ) );
            }
        });   

        return toReturn.join("&").replace(/%20/g, "+");
    }

})(jQuery);

$(document).ajaxComplete(function(e,xhr,opt){
    if(xhr.getResponseHeader("relogin")){
        top.location.href='/';
    }
})
function xalert(xhr,s){
    if(xhr.getResponseHeader("relogin")){
        top.location.href='/';
    }else{
        alert(s);
    }
}


function isValidName(name)
{
	var i = 0;

	for ( i = 0; i < name.length; i++ ) {
		if ( isNameUnsafe(name.charAt(i)) == true )
			return false;
	}
	return true;
}

function isValidName_allowSpecialChar(name)
{
	return true;
}

function isNameUnsafe(compareChar)
{

	//var unsafeString = "\"<>%\\^[]`\+\$\,='#&@.: \t";
	//var unsafeString = "\"<>()\\^`\+\\,'&\t";	
	var unsafeString = "\"<>\\^`\+\\,'&\t";	

	if ( unsafeString.indexOf(compareChar) == -1
		&& compareChar.charCodeAt(0) > 31
		&& compareChar.charCodeAt(0) < 123 )
	{
		return false; // found no unsafe chars, return false
	}
	else
	{
		return true;
	}
}

function isValidHexKey(val, size)
{
	var ret = false;
	if (val.length == size) {
		for ( i = 0; i < val.length; i++ ) {
			if ( isHexaDigit(val.charAt(i)) == false ) {
				break;
			}
		}
		if ( i == val.length ) {
			ret = true;
		}
	}

	return ret;
}


function isHexaDigit(digit)
{
	var hexVals = new Array("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "a", "b", "c", "d", "e", "f");
	var len = hexVals.length;
	var i = 0;
	var ret = false;

	for (i = 0; i < len; i++)
	{
		if ( digit == hexVals[i] )
		{
			ret = true;
			break;
		}
	}

	return ret;
}

function isValidName_ASCII(name)
{
	var reg = /^\w+$/;
	return reg.test(name);
}

function checkDomain(domain)
{
    var patrn=/^[0-9a-zA-Z]+[0-9a-zA-Z\.-]*\.[a-zA-Z]{2,4}$/;
    if(patrn.test(domain))
    {
        return true;
	}
    return false;	
}

function disable_all_buttons()
{
    $(":button").prop("disabled",true);
    $(":submit").prop("disabled",true);
}

function refresh()
{
	window.location.reload();
}


