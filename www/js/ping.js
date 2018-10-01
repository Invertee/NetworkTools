function pingHost() {
    var hn = document.getElementById('hostnameinput').value
    var prt = document.getElementById('PortNo').value

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
}).then(res => res.json())

  .then((res) => {

      var results =  "Computername: " + res.ComputerName + "\n" +
                     "RemoteAddress: " + res.RemoteAddress + "\n" +
                     "RemotePort: " + res.RemotePort + "\n" +
                     "NameResolutionResults: " + res.NameResolutionResults + "\n" +
                     "InterfaceAlias: " + res.InterfaceAlias + "\n" +
                     "InterfaceAlias: " + res.InterfaceAlias + "\n" +
                     "TcpTestSucceeded: " + res.TcpTestSucceeded 
                    

    document.getElementById('resultsarea').value = results
  });
}