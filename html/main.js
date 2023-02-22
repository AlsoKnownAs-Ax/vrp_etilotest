const closeKey = "27";

// var popup_sound = new Audio('popup.mp3');
// popup_sound.volume = 0.2;
// popup_sound.play();
$(".loader").hide();

function display(bool) {
    if (bool) {
        $("#container").fadeIn();
    } else{
        $('.number').text(`0.00%`);
        $("#container").fadeOut();
    }
}

function ShowAlch(drunk_level){
    $(".loader").fadeOut('slow',function(){
        if(drunk_level < 100 && drunk_level >= 10){         // 2 digits
            $('.number').text(`0.${drunk_level}%`);
        }else if(drunk_level < 10 && drunk_level >= 0){      // 1 digit
            $('.number').text(`0.0${drunk_level}%`);
        }else{
            $('.number').text(`1.00%`);
        }
        
        $(".number").fadeIn('slow');
    }); 
}

function playSound(){
    var blow_sound = new Audio('assets/sound.mp3');
    blow_sound.volume = 0.3;
    blow_sound.play();
}

window.addEventListener('message', function(event) {
    var data = event.data;

    if(data.open) {
        display(true)
    }
    if(data.close){
        display(false)
    }
    if(data.test){
        let drunk_level = data.drunk_level
        playSound()
        $(".number").fadeOut('slow',function(){
            $(".loader").fadeIn();
        });
        setTimeout(function() {
            ShowAlch(drunk_level)
            if(data.target){
                setTimeout(function(){
                    display(false)
                },2500)
            }
        }, 4000);
    }
});

$(document).on('click', "#close", function() {
    display(false)
    sendData("action","close")
});

$(document).on('click', "#use", function() {
    sendData("action","use")
});


$(document).ready(function(){
    document.onkeyup = function(data) {
        if (data.which == closeKey) {
            display(false)
            sendData("action","close")
        }
    };
});


function sendData(data,type){
    $.post(`https://${GetParentResourceName()}/`+data, JSON.stringify({
        type: type
    }));
};
