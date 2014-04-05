function lisp(h) {
    var socket = new WebSocket(h);
    socket.onmessage = function (evt) { 
       alert(""+evt.data);
    };
    this.connection = socket
    this.count = 1;
}

lisp.prototype.raw = function (msg) {
    this.connection.send(JSON.stringify(["raw",msg]));
}

$(function() {
    $.post('/api/1.0/debug/p',{},function(ret){
        if(ret) {
            var button = $('<button>Reload</button>');
            button.click(function(){
                $.post('/api/1.0/debug/reload',{},function(data){});
            });
            $('#quit-button').parent().prepend(button);
        }
    })
})
