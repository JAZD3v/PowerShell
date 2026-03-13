$ServerRelativeUrl = "11445/ILSSInnovation" #https://info.health.mil/sites/AFDW-SG 
$Context = "https://YourDomain$($ServerRelativeUrl)"

$PermLevelHash=@{
Approve = 3
Limited_Access = 0
View_Only= 1
Read = 2
Design = 5
Contribute = 4
Edit = 6
Full_Control = 7
}

Connect-PnPOnline -Url $Context -UseWebLogin

$web = Get-PnPWeb -Includes RoleAssignments,SiteUserInfoList,SiteUsers #| FL RoleAssignments,SiteUserInfoList,SiteUsers

$HashT=@{}

# Load RoleAssignments
Get-PnPProperty -ClientObject $web -Property RoleAssignments | out-null


foreach ($ra in $web.RoleAssignments) 
{
    # Load the Member (Principal)
    Get-PnPProperty -ClientObject $ra -Property Member | out-null
    $member = $ra.Member
    #$PrincipalId = $ra.PrincipalId


    # Load Member properties
    if($member.PrincipalType -eq "SharePointGroup"){
        Get-PnPProperty -ClientObject $member -Property LoginName, Title, PrincipalType, Users | out-null
    }
    else
    {
        Get-PnPProperty -ClientObject $member -Property LoginName, Title, PrincipalType
    }
    # Load RoleDefinitionBindings (permission levels)
    Get-PnPProperty -ClientObject $ra -Property RoleDefinitionBindings | out-null

    # Expand each permission level
    foreach ($roleDef in $ra.RoleDefinitionBindings) 
    {
        Get-PnPProperty -ClientObject $roleDef -Property Name, Description <#-ErrorAction SilentlyContinue#> | out-null
        if($member.PrincipalType -eq "SharePointGroup")
        {
            $UserObj = [PSCustomObject]@{<##>
            #Principal       = $member.LoginName
            PrincipalTitle  = $member.Title
            PrincipalType   = $member.PrincipalType
            PermissionLevel = $roleDef.Name
            PermissionLevelNum = "XX"
            Description     = $roleDef.Description
            #PrincipalId     = $ra.PrincipalId
            Group              = "XX"
            GroupUsers      = $member.Users.Title -join " / "
        }
       $HashT.Add(($member.Title ),$UserObj) 
        }
        else
        {
            $UserObj = [PSCustomObject]@{
                    #Principal       = $member.LoginName
                    PrincipalTitle  = $member.Title
                    PrincipalType   = $member.PrincipalType
                    PermissionLevel = $roleDef.Name
                    Description     = $roleDef.Description
                    #PrincipalId     = $ra.PrincipalId
                    PermissionLevelNum = $PermLevelHash[($roleDef.Name).Replace(" ","_")]
                    Group              = "XX"
                    GroupUsers      = "XX"
                }
               $HashT.Add(($member.Title),$UserObj) 
        }
    }
}

### ITERATE THROUGH THE SHAREPOINT GROUPS AND GET ALL THE USERS ###
$UsersFromGrp = @{}
$UsersPermissionsHash=@{}
foreach($Key in $HashT.Keys)
{
    if($HashT[$Key].PrincipalType -eq "SharePointGroup") {
        $GroupUsers = @()
        $GroupUsers += [regex]::Split($HashT[$Key].GroupUsers,' / ')
        foreach($User in $GroupUsers)
        {
                $UsersGrpsObj = [PSCustomObject]@{
                PrincipalTitle  = $User
                PrincipalType   = "User"
                PermissionLevel = $HashT[$Key].PermissionLevel
                PermissionLevelNum = $PermLevelHash[($HashT[$Key].PermissionLevel).Replace(" ","_")]
                Description     = "XX"
                Group           = $Key
                GroupUsers      = "XX"
                }
                $UsersFromGrp.Add(($UsersGrpsObj.PrincipalTitle+"_"+$HashT[$Key].PrincipalTitle),$UsersGrpsObj)
                if($UsersPermissionsHash.ContainsKey($User))
                {
                    if($UsersPermissionsHash[$User].PermissionLevelNum -lt $UsersGrpsObj.PermissionLevelNum)
                    {
                        $UsersPermissionsHash.Remove($User)
                        $UsersPermissionsHash.Add($User , $UsersGrpsObj)
                    }
                
                }
                else {
                    $UsersPermissionsHash.Add($User , $UsersGrpsObj)
                }
        }
    }
}


Foreach($KeyObj in $UsersPermissionsHash.keys)
{
   if($HashT.ContainsKey($KeyObj))
   {
        if($UsersPermissionsHash[$KeyObj].PermissionLevelNum -Gt $PermLevelHash[($HashT[$KeyObj].PermissionLevel).Replace(" ","_")])
        {
            $HashT.Remove($KeyObj)
            $NewUserHash = [PSCustomObject]@{
                PrincipalTitle  = $KeyObj
                PrincipalType   = "User"
                PermissionLevel = $UsersPermissionsHash[$KeyObj].PermissionLevel
                PermissionLevelNum = $UsersPermissionsHash[$KeyObj].PermissionLevelNum
                Description     = "XX"
                Group           = $UsersPermissionsHash[$KeyObj].Group
                GroupUsers      = "XX"
            }
            $HashT.Add($KeyObj , $NewUserHash)
        }
    }
    else {
        $NewUserHash = [PSCustomObject]@{
                PrincipalTitle  = $KeyObj
                PrincipalType   = "User"
                PermissionLevel = $UsersPermissionsHash[$KeyObj].PermissionLevel
                PermissionLevelNum = $UsersPermissionsHash[$KeyObj].PermissionLevelNum
                Description     = "XX"
                Group           = $UsersPermissionsHash[$KeyObj].Group
                GroupUsers      = "XX"
            }
            $HashT.Add($KeyObj , $NewUserHash)
    }
}

$For_CSV = @()
foreach($e in $HashT.Keys)
{
    $For_CSV += $HashT[$e]
    #"---------------------------------------------------------------------------------------------------"
}

$For_CSV | ForEach-Object{ Export-Csv -InputObject $_ -Path "C:\Users\1384107288E\Desktop\$($ServerRelativeUrl.Replace("/","_"))Permissions.csv" -NoTypeInformation -Append -Force}
ii "C:\Users\1384107288E\Desktop\$($ServerRelativeUrl.Replace("/","_"))Permissions.csv"