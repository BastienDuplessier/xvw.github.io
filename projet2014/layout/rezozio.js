function logo_animation(){
    var blogo = document.getElementById("block_logo");
    var y_axis = -30;
    var flag = false;
    function move_logo(){
	if (y_axis > -15 || y_axis < -30){
	    flag = !flag
	}
	y_axis = (flag) ? y_axis - 1 : y_axis + 1;
	blogo.style.bottom = y_axis + 'px';
    }
    var id = setInterval(move_logo, 30);
}

window.onload = function(){
    // Fonction de lancement de l'application
    logo_animation(); // Animation du logo
}