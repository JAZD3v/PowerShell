$Root = "Root-Site"
$ListName = "YourListName"
$Context = "https://YourDomain/sites/$($Root)"
Connect-PnPOnline -Url $Context -UseWebLogin

$HubSite = Get-PnPWeb -Includes SiteUsers,Author,LastItemModifiedDate,LastItemUserModifiedDate


Clear-Variable SCAs
$SCAs = @()

foreach($User in $HubSite.SiteUsers)
{

    if($User.IsSiteAdmin -eq $True)
    {
    
        $SCAs += $($User.ID)

    }
}

$SubSites = Get-PnPSubWeb -Recurse <#-IncludeRootWeb#> -Includes Author,LastItemModifiedDate,LastItemUserModifiedDate 

Connect-PnPOnline -Url "https://YourDomain/sites/YourSite" -UseWebLogin

Add-PnPListItem -List "YourListName" `
-Values @{"Title"=$HubSite.Title ; "ModernSiteURL"=$HubSite.Url ; "SiteCollectionAdmins"=$SCAs ; "SiteCreater" = $HubSite.SiteCreater ; "LastUserDateModified" = (get-date $HubSite.LastItemUserModifiedDate -f "MM/dd/yyyy") <#; "SubSites" = $_.SubSites#>} | Out-null


for($i=0; $i-le ($SubSites.count - 1); $i++){

   
        Add-PnPListItem -List "$ListName" `
        -Values @{"Title"=$($SubSites[$i].Title) ; "ModernSiteURL"=$($SubSites[$i].Url) ; "SiteCreater" = $($SubSites[$i].SiteCreater) ; "LastUserDateModified" = (get-date $SubSites[$i].LastItemUserModifiedDate -f "MM/dd/yyyy") <#; "SubSites" = $_.SubSites#>} | Out-null
    

}