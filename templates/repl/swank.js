function swank() {
    this.event = {
	"return":function(data) {
            this.callback[data[2]](data[1]);
            delete(this.callback[data[2]]);
	},"write-string":function (data) {
	    this.writeString(data,this.presentation[data[1][1]] || {});
	},"presentation-start":function (data) {
	    var hash = this.presentation[data[1][1]] || {};
	    hash[data[1][0]] = true;
	    this.presentation[data[1][1]] = hash;
	},"presentation-end":function (data) {
	    var hash = this.presentation[data[1][1]] || {};
	    delete(hash[data[1][0]]);
	    this.presentation[data[1][1]]= hash;
	},"ping":function (data) {
	    this.raw.call(this,"(:emacs-pong "+data[1][0]+" "+data[1][1]+")");
	}
    };
    this.presentation = {};
    this.callback = {};
    this.count = 1;
}

swank.prototype.connect = function (h) {
    var socket = new WebSocket(h);
    this.connection = socket;
    var t = socket.par= this;
    socket.onmessage = function (evt) {
	console.log(evt.data);
        var data = JSON.parse(evt.data);
	if(this.par.event.hasOwnProperty(data[0])) {
	    this.par.event[data[0]].call(this.par,data);
	}
    };
    var dfd = $.Deferred();
    var waitForSocketConnection = function (socket) {
	setTimeout(function () {
            if (socket.readyState === 1) {
		dfd.resolve()
		return;
            } else {
		waitForSocketConnection(socket);
            }
	},5);
    };
    waitForSocketConnection(socket)
    return dfd.promise().then(function() {
	return t.eval.call(t,"(swank-json:connection-info)");
    }).then(function(x) {
	t.info = JSON.parse(JSON.parse(x[1]));
	return t.eval.call(t,"(swank:swank-require (quote (swank-trace-dialog swank-package-fu swank-presentations swank-fuzzy swank-fancy-inspector swank-c-p-c swank-arglists swank-repl)))")
    }).then(function(x){
	return t.eval("(swank:create-repl nil :coding-system \"utf-8-unix\")")
    });
}

swank.prototype.raw = function (msg) {
    this.connection.send(JSON.stringify(["raw",msg]));
}

swank.prototype.mode = function (method,types) {
    this.connection.send(JSON.stringify(["mode",method,types]));
}

swank.prototype.eval = function (expression,thread) {
    var dfd = $.Deferred();
    var package = this.info?this.info[":PACKAGE"][":NAME"]:"COMMON-LISP-USER";
    thread = thread?thread+' ':"t ";
    this.callback[this.count]=function(x){ dfd.resolve(x)};
    this.raw("(:emacs-rex"+expression+"\""+ package + "\" "+thread+ this.count +")");
    this.count++;
    return dfd.promise();
}
