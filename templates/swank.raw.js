function make (p) {
    var port=$("#port").val();
    var pid =$("#check-pid").prop("checked")?$("#to").val():[];
    var host=$("#check-pid").prop("checked")?[]:$("#to").val(); 
    $.post('/api/1.0/swank/info?port='+port+'&pid='+pid+'&host='+host,{},function(data){
        reflesh();
    })
}

function totop (p) {
    var ar=$(p.target).parent().parent().children();
    var port=$(ar[2]).html();
    var pid =$(ar[3]).html();
    var host=$(ar[4]).html(); 
    $.post('/api/1.0/swank/totop?port='+port+'&pid='+pid+'&host='+host,{},function(data){
        reflesh();
    })
}

function kill (p) {
    var ar=$(p.target).parent().parent().children();
    var port=$(ar[2]).html();
    var pid =$(ar[3]).html();
    var host=$(ar[4]).html(); 
    $.post('/api/1.0/swank/delete?port='+port+'&pid='+pid+'&host='+host,{},function(data){
        reflesh();
    })
}

function reflesh() {
    var table =$('#table');
    $.post('/api/1.0/swank/list',{},function(data){
        table.html('');
        if (data) {
            {
                var raw=$("<div class='row'>");
                raw.append($("<div>"))
                    .append($("<div>"))
                    .append($("<div>port</div>"))
                    .append($("<div>pid</div>"))
                    .append($("<div>host</div>"));
                table.append(raw);
            }
            for (var i=0;i<data.length;i++) {
                var raw=$("<div class='row'>");
                var button=$("<button>Top</button>");
                button.click(totop);
                if(i==0){
                    button="default";
                }
                raw.append($("<div>").append(button));
                button=$("<button>delete</button>");
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
    $('#check-pid').click(function(){
        var p;
        if(this.checked) {
            p="pid:";
        }else {
            p="host:";
        }
        $("#pidhost").html(p);
    });
});
