function pingHost() {
    var hn = document.getElementById('hostnameinput').value
    var prt = document.getElementById('PortNo').value

    if (!hn) {
      hn = 'google.com'
    }
    
    if (prt == 'None') {
      prt = 0
    }
    document.getElementById('resultspanel').style.display = 'block'
    document.getElementById('resultsarea').value = ''
    document.getElementById('loadingpanel').innerText = 'Pinging Host...'
    document.getElementById('scansubmit').style.backgroundImage = "url('/images/loading.gif')"
    document.getElementById('scansubmit').innerText = '' 

    fetch('http://localhost:48080/ping', {
  method: 'post',
  headers: {
    'Accept': 'application/json, text/plain, */*',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    hostname: hn,
    port: prt,
})
})



.then(res => res.json())

.then((res) => {

    if (res.RemotePort == 0) {

      var results =  "Hostname: " + res.Computername + "\n" +
      "Remote Address: " + res.RemoteAddress + "\n" +
      "Ping Succeeded: " + res.PingSucceeded + "\n" +
      "Round Trip Time (RTT): " + res.RoundTripTime + "ms \n" +
      "Interface Alias: " + res.InterfaceAlias + "\n" +
      "Source Address: " + res.SourceAddress + "\n" +
      "Next Hop: " + res.NextHop + "\n"

    } else {

      var results =  "Hostname: " + res.Computername + "\n" +
      "Remote Address: " + res.RemoteAddress + "\n" +
      "Remote Port: " + res.RemotePort + "\n" +
      "TCP Test Succeeded: " + res.TcpTestSucceeded + "\n" +
      "Interface Alias: " + res.InterfaceAlias + "\n" +
      "Source Address: " + res.SourceAddress + "\n" +
      "Next Hop: " + res.NextHop + "\n"

    }
    document.getElementById('scansubmit').style.backgroundImage = ""
    document.getElementById('scansubmit').innerText = 'Submit!' 
    document.getElementById('loadingpanel').innerText = ''
    document.getElementById('resultsarea').style.backgroundImage = ''   
    document.getElementById('resultsarea').value = results
  });
}



function changeValue(port) {
  document.getElementById('PortNo').value = port
}