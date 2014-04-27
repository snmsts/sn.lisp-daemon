function swank(h) {
    var socket = new WebSocket(h);
    socket.par= this;
    socket.onmessage = function (evt) { 
	console.log(evt.data);
        var data = JSON.parse(evt.data);
        if(data[0]==="return") {
            this.par.callback[data[2]](data[1]);
            delete(this.par.callback[data[2]]);
        }else if(data[0]==="write-string"){
            console.log(data);
            jqconsole.Write(data[1][0], 'jqconsole-output', true);
        }else if(data[0]==="presentation-start") {
	    console.log(data);
        }else if(data[0]==="presentation-end") {
            console.log(data);
	}else if(data[0]==="ping") {
	    this.par.raw.call(this.par,"(:emacs-pong "+data[1][0]+" "+data[1][1]+")");
        }else
        {
            console.log(data);
        }
    };
    this.package = "COMMON-LISP-USER";
    this.callback = {};
    this.connection = socket;
    this.count = 1;
}

swank.prototype.raw = function (msg) {
    this.connection.send(JSON.stringify(["raw",msg]));
}

swank.prototype.mode = function (method,types) {
    this.connection.send(JSON.stringify(["mode",method,types]));
}

function addslashes(str) {
    return (str + '').replace(/[\\"]/g, '\\$&').replace(/\u0000/g, '\\0');
}

swank.prototype.eval = function (expression,thread) {
    var dfd = $.Deferred();
    if(thread){
        thread = thread+' ';
    }else {
        thread = "t ";
    }
    console.log(addslashes(expression));
    this.connection.send(JSON.stringify(["raw","(:emacs-rex"+expression+"\""+ this.package + "\" "+thread+ this.count +")"]));
    this.callback[this.count]=function(x){ dfd.resolve(x)};
    this.count++;
    return dfd.promise();
}

waitForSocketConnection = function (socket,callback) {
    setTimeout(function () {
        if (socket.readyState === 1) {
            if(callback != null){
                callback();
            }
            return;
        } else {
            waitForSocketConnection(socket,callback);
        }
    },5);
}

var jqconsole;

$(function() {
    connection = new swank("ws://"+location.host+"/websocket/swank");
    waitForSocketConnection(connection.connection,function () {
        connection.mode("set","json");
        connection.eval("(swank-json:connection-info)")
	    .then(function(x) {
		connection.info = JSON.parse(JSON.parse(x[1]));
		return connection.eval("(swank:swank-require (quote (swank-trace-dialog swank-package-fu swank-presentations swank-fuzzy swank-fancy-inspector swank-c-p-c swank-arglists swank-repl)))")
            }).then(function(x){
		console.log(x);
		return connection.eval("(swank:create-repl nil :coding-system \"utf-8-unix\")")
	    }).then(function(x) {
		console.log(x);
		//not sure but it is required 
		jqconsole = $('#console').jqconsole('Welcome to lisp!\n\n', '');
		jqconsole.RegisterMatching('(', ')', 'parents');
		if (localStorage.getItem("jqhist"))
		    jqconsole.SetHistory(JSON.parse(localStorage.getItem("jqhist")));
		var startPrompt = function () {
		    // Start the prompt with history enabled.
		    jqconsole.Write(
			connection.info[":PACKAGE"][":PROMPT"] + '> ', 'jqconsole-prompt');
		    jqconsole.Prompt(true, function (input) {
			// Output input with the class jqconsole-return.
			if (input[0] != ','){
			    try {
				//var vs = lisp.evalInput(input);
				// for (var i=0; i<vs.length; i++){
				//jqconsole.Write(lisp.print(vs) + '\n', 'jqconsole-return');
				connection.eval("(swank:listener-eval \""+addslashes(input)+"\")",":repl-thread").then(function(x){
				    //jqconsole.Write(x + '\n', 'jqconsole-return')
				    localStorage.setItem("jqhist", JSON.stringify(jqconsole.GetHistory()));
				    startPrompt();
				})
				// }
			    } catch(error) {
				var msg = error.message || error || 'Unknown error';
				if (typeof(msg) != 'string') msg = xstring(msg);
				jqconsole.Write('ERROR: ' + msg + '\n', 'jqconsole-error');
				startPrompt();
			    }
			} else {
			    //jqconsole.Write(lisp.compileString(input.slice(1)) + '\n', 'jqconsole-return');
			    startPrompt();
			}
		    }, function(input){
			try {
			    //lisp.read(input[0]==','? input.slice(1): input);
			} catch(error) {
			    return 0;
			}
			return false;
		    });
		};
		startPrompt();
	    });
    })
})
