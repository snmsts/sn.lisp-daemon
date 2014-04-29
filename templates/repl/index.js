function addslashes(str) {
    return (str + '').replace(/[\\"]/g, '\\$&').replace(/\u0000/g, '\\0');
}

var jqconsole;
var connection;
$(function() {
    connection=new swank;
    connection.writeString = function (data,attr) {
	var result = "";
	$.map(attr, function(val,key){ result= result+" o"+key});
	if(result.length==0) {
	    if(data[1][0][0]===";") {
		result = "jqconsole-output-none"
		data[1][0]=data[1][0]+"\n";
	    }else {
		result = "jqconsole-output";
	    }
	} else {
	    result = "jqconsole-output-object"+ result;
	}
        jqconsole.Write(data[1][0], result, true);
    }
    connection.connect("ws://"+location.host+"/websocket/swank").then(function(x) {
	console.log(x);
	jqconsole = $('#console').jqconsole('Welcome to lisp!\n\n', '');
	jqconsole.RegisterMatching('(', ')', 'parents');
	if (localStorage.getItem("jqhist"))
	    jqconsole.SetHistory(JSON.parse(localStorage.getItem("jqhist")));
	var startPrompt = function () {
	    // Start the prompt with history enabled.
	    jqconsole.Write(
		connection.info[":PACKAGE"][":PROMPT"] + '> ', 'jqconsole-prompt-package');
	    jqconsole.Write("", 'jqconsole-prompt')
	    jqconsole.Prompt(true, function (input) {
		// Output input with the class jqconsole-return.
		if (input[0] != ','){
		    try {
			//var vs = lisp.evalInput(input);
			// for (var i=0; i<vs.length; i++){
			//jqconsole.Write(lisp.print(vs) + '\n', 'jqconsole-return');
			console.log(addslashes(input));
			connection.eval("(swank:listener-eval \""+addslashes(input)+"\")",":repl-thread").then(function(x){
			    if(x[0] == "abort") {
				jqconsole.Write("; Evaluation aborted on "+JSON.parse(x[1])+".\n", 'jqconsole-return', true);
			    }
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
