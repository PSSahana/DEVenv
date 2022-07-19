add-content -path c:/Users/Dell/.ssh/config -value @'
Host ${hostname}
    HostName ${hostname}
    User ${user}
    Identityfile ${identityfile}
'@
