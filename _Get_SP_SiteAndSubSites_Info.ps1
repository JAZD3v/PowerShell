#Replace with your site url
$Context = "https://YourDomain/sites/SiteName"

Connect-PnPOnline -Url $Context -UseWebLogin

if($Subsites.count -ge 1)
{
Clear-Variable SubSites
}

if($HubSite.count -eq 1)
{
Clear-Variable HubSite
}

$HubSite = Get-PnPWeb -Includes SiteUsers,Author,LastItemModifiedDate,LastItemUserModifiedDate

$SCAsInfo = @()
foreach($User in $HubSite.SiteUsers)
{

    if($User.IsSiteAdmin -eq $True)
    {
        $SCAsInfo += $($User)
    }
}

$SubSites = Get-PnPSubWeb -Recurse -Includes Author,LastItemModifiedDate,LastItemUserModifiedDate 

#Rplace Url with list you want to add the info to
$ListSite= "https://YourDomain/sites/ListName"
#Rplace with List Name
$ListName="ListName"

Connect-PnPOnline -Url $ListSite -UseWebLogin

Add-PnPListItem -List $ListName -ContentType "Item" -Values @{"Title"=$HubSite.Title ; "ModernSiteURL"=$HubSite.Url ; "SiteCollectionAdmins"=$SCAsInfo.LoginName ; "SiteCreater" = $HubSite.Author.Email ; "LastUserDateModified" = (get-date $HubSite.LastItemUserModifiedDate -f "MM/dd/yyyy")} | Out-null

if($SubSites.count -ge 1){
    Write-Host "There are $($SubSites.count) Subsites in $($Context)" -BackgroundColor DarkGreen
    for($i=0; $i-le ($SubSites.count - 1); $i++)
    {
        Add-PnPListItem -List $ListName -ContentType "Item" -Values @{"Title"=$($SubSites[$i].Title) ; "ModernSiteURL"=$($SubSites[$i].Url) ; "SiteCreater" = $($SubSites[$i].Author.Email) ; "LastUserDateModified" = (get-date $SubSites[$i].LastItemUserModifiedDate -f "MM/dd/yyyy")} | Out-null  
    }
}
else
{
    Write-Host "There are $($SubSites.count) Subsites in $($Context)" -BackgroundColor DarkYellow
}
