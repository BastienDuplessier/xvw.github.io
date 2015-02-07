var option, textnd, current;
var content = document.getElementById('innercontent');
var childs  = content.querySelectorAll('h1,h2,h3,h4,h5,h6');
var toc     = document.createElement('select');
var target  = document.getElementById('rtitle');
for(i = 0; i < childs.length; i++) {
		current = childs.item(i);
		textnd  = document.createTextNode(current.firstChild.data);
		option  = document.createElement('option');
		option.value = current.getAttribute('id');
		option.appendChild(textnd);
		toc.appendChild(option)
}
toc.addEventListener('change', function (e) {
		window.location = "#"+(e.target.options[e.target.selectedIndex].value)
})
target.appendChild(toc);
