cortana
=======

This is a pack of Cortana scripts commonly used on our pentests.


Currently Included:

    load_all.cna - loads up every script contained in this pack
    beacon.cna - adds the ability to replace icons on active beacon hosts, and adds a host label (so a filtering workspace can be created)
    grabcreds.cna - does auto-hashdumping and mimikatz-running on new hosts to come in, and checks if a particular user is logged in
    safetynet.cna - adds the ability to auto-inject 'safetynet' payloads into new hosts (beacons or otherwise)
    user_hunter.cna - allows you to hunt for particular users on the network 
    veil_evasion.cna - integrates the functionality of Veil-Evasion to generate AV-evading payloads that can optionally hook psexec calls
    references.cna - adds useful reference links to the help menu


Cortana is an attack scripting languaged used to extend the functionality of [Armitage](http://www.fastandeasyhacking.com/) or [Cobalt Strike](http://advancedpentest.com/).

A more comprehensive set of Cortana scripts is maintained by the creator of Cortana/Armitage/Cobalt Strike (Raphael Mudge) and is located at https://github.com/rsmudge/cortana-scripts

Raphael has also provided excellent tutorials on [Cortana](www.fastandeasyhacking.com/download/cortana/cortana_tutorial.pdf) as well as [Sleep](http://sleep.dashnine.org/documentation.html), the langauge Cortana is built on. 

