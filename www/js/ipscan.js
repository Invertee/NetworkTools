function ipScan() {
    document.getElementById('resultspanel').style.display = 'block'
    document.getElementById('resultstable').innerHTML = ''
    document.getElementById('loadingpanel').innerText = 'Scanning IP range...'
    document.getElementById('scansubmit').style.backgroundImage = "url('/images/loading.gif')"
    document.getElementById('scansubmit').innerText = ''        

    fetch('http://localhost:48080/ipscan', {
  method: 'post',
  headers: {
    'Accept': 'application/json, text/plain, */*',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    StartIP: (document.getElementById('startIP').value),
    EndIP: (document.getElementById('endIP').value),
})
})

.then(res => res.json())
// Create table from JSON
.then((res) => {
    
    var table = generateTable(res)

    document.getElementById('resultstable').innerHTML = table;
    document.getElementById('loadingpanel').innerText = ''
    document.getElementById('scansubmit').style.backgroundImage = ""
    document.getElementById('scansubmit').innerText = 'Submit!' 

  });
}



function int2ip (ipInt) {
    var reip = ( (ipInt>>>24) +'.' + (ipInt>>16 & 255) +'.' + (ipInt>>8 & 255) +'.' + (ipInt & 255) ).split('.');
    return [reip[3],reip[2],reip[1],reip[0]].join('.')
}

function changeValue(port) {
  document.getElementById('PortNo').value = port
}

// Replace with something nicer :)
function generateTable(json) {
console.log(json)
var table = "<table id='ipTable'>"
table += "<tr><th>Status:</th><th>IPv4Address:</th><th>Hostname:</th><th>MAC Address:</th><th>Vendor:</th><th>Response Time(ms):</th></tr>";
//Dynamic content --------------------------------------------------------
for (var i = 0; i < json.length ;i++)
{
	table += ("<tr><td>" + '✔' + "</td><td>" + int2ip(json[i].IPv4Address.Address) + "</td><td>" + json[i].Hostname +"</td><td>" + json[i].MAC +"</td><td>" + json[i].Vendor +"</td><td>" + json[i].ResponseTime +"</td></tr>");
}
//Static content  --------------------------------------------------------
table += ("</table>")

return table;

}