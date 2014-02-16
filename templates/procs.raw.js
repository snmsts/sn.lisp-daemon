function make () {
    var name=$("#new-name").val();
    $.post('/api/1.0/process/swank?name='+name,{},function(data){
    $("#new-name").val("");
    })
}

function kill (p) {
    var name=$($(p.target).parent().parent().children()[1]).html();
    if(window.confirm('kill '+name+'?')){
        $.post('/api/1.0/process/kill?name='+name,{},function(data){
        })
    }
}

function reflesh() {
    var table =$('#table');
    $.post('/api/1.0/process/list',{},function(data){
        table.html('');
        if (data) {
            {
                var raw=$("<div class='row'>");
                raw.append($("<div>")).append($("<div>name</div>"));
                table.append(raw);
            }
            for (var i=0;i<data.length;i++) {
                var raw=$("<div class='row'>");
                var button=$("<button>kill</button>");
                button.click(kill);
                raw.append($("<div>").append(button));
                for(var j=0;j<data[i].length;j++){
                    raw.append($("<div>"+data[i][j]+"</div>"));
                }
                table.append(raw);
            }
        }else {
            table.append("no processes");
        }})
    setTimeout("reflesh()",5000);
}
function quit (p) {
    if(window.confirm('quit lisp?')){
        $.post('/api/1.0/process/quit',{},function(data){
        })
    }
}

$(function() {
    reflesh();
    $('#new-button').click(make)
    $('#quit-button').click(quit)
    $.post('/api/1.0/debug/p',{},function(ret){
        if(ret) {
            var button = $('<button>Reload</button>');
            button.click(function(){
                $.post('/api/1.0/debug/reload',{},function(data){});
            });
            $('#quit-button').parent().prepend(button);
        }
    })
});
