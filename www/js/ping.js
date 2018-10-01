function pingHost() {
    var hn = document.getElementById('hostnameinput').value
    var prt = document.getElementById('PortNo').value

    fetch('http://localhost:8080/ping', {
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

      var results = "Computername: res.ComputerName \
                     RemoteAddress: res.RemoteAddress \
                     RemotePort: res.RemotePort \
                     NameResolutionResults: res.NameResolutionResults \
                     InterfaceAlias: res.InterfaceAlias \
                     InterfaceAlias: res.InterfaceAlias \
                     TcpTestSucceeded: res.TcpTestSucceeded \
                    "

    document.getElementById('resultsarea').value = results
  });
}