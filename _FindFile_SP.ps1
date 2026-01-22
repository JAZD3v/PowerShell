"`n"
$Site = "https://YourDomain/sites/SiteName"
Connect-PnPOnline -Url $Site -UseWebLogin

$bullet = [char]0x2022
$StringSearch="11 ?MSG"
$MatchItems=@()
$Counter=0

$DocumentLibraries=Get-PnPList | Where-Object {$_.BaseTemplate -eq 101 <#Or $_.BaseType -eq "DocumentLibrary" -and $_.Hidden -eq $false#> }

#NOTE: Get-PnPListItem works based on the logged in users/application permissions.If you have the permission for list items, they will be fetched. SEE: https://github.com/pnp/powershell/discussions/2277
foreach ($Lib in $DocumentLibraries){
$Files=Get-PnPListItem -List $($Lib).Title | select -ExpandProperty FieldValues

    foreach ($File in $Files)
    {
        if($File.FileLeafRef -match $StringSearch)
        {
            $Counter+++
            $bullet + " The file, " + $File.FileLeafRef + ", is in the " + $File.FileDirRef.remove(0,$File.FileDirRef.LastIndexOf("/") + 1) + " folder, in the '" + $($Lib).Title + "' Document Library"
        }
    }
}
if($Counter -eq 0)
{
write-host "No files matching '$($StringSearch)' were found on the site. Checking the Recycling Bin.`n" -ForegroundColor red
}

$RecycleBinItem = Get-PnPRecycleBinItem | Sort-Object -Property DeletedDateLocalFormatted -Descending #| select DeletedDateLocalFormatted,Title,DeletedByEmail

foreach ($Item in $RecycleBinItem)
{
    if($Item.Title -match $StringSearch)
    {
        $Counter++
        $MatchItems +=$Item
        if($Counter -eq 1)
        {
            write-host "Matching items in the Recycle Bin:" -ForegroundColor Yellow

        }
    }
}
if($MatchItems.Count -ge 1)
{
    foreach($MatchItem in $MatchItems)
    {
        $bullet + " " + $MatchItem.Title + ". Deleted by " + $MatchItem.DeletedByEmail
    }
}
else
{
    write-host "No files matching '$($StringSearch)' were found in the recycling Bin." -ForegroundColor red
}
    

write-host "`n NOTE: This script works based on the logged in users permissions. If you don't have permissions for the list items, it will NOT be fetched." -ForegroundColor yellow
