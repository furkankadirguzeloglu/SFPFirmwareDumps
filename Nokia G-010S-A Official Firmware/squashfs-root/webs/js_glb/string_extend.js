String.prototype.format = function() {
	var str = this ;
	for(var i=0;i<arguments.length;i++) {
		var re = new RegExp('\\{' + i + '\\}','gm');
		str = str.replace(re, arguments[i]);
	}
	return str;
}
