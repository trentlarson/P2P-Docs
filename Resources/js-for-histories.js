
// This is loaded from the local app server to attach events onto the loaded page.
// It's in a separate file for general use (eg. Titanium, browser).

alert("Congrats!  You just loaded a script onto this page and executed it.");

$('span[itemtype|="http://historical-data.org/HistoricalPerson.html"]').css('border','3px dotted green');

$('span[itemtype|="http://historical-data.org/HistoricalPerson.html"]').mouseover(function(event){
  alert('yo');
});

