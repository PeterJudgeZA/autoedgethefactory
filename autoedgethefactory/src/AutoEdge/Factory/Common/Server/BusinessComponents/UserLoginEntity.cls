/** ------------------------------------------------------------------------
    File        : UserLoginEntity
    Purpose     : 
    Syntax      : 
    Description : 
    @author pjudge
    Created     : Wed Dec 22 10:06:26 EST 2010
    Notes       : 
  ---------------------------------------------------------------------- */
routine-level on error undo, throw.

using OpenEdge.BusinessComponent.Entity.StandardBusinessEntity.
using OpenEdge.DataAccess.IDataAccess.
using OpenEdge.CommonInfrastructure.Common.IServiceManager.
using OpenEdge.CommonInfrastructure.Common.IComponentInfo.

class AutoEdge.Factory.Common.Server.BusinessComponents.UserLoginEntity inherits StandardBusinessEntity: 
    define temp-table eUserLogin no-undo
        field ApplicationUserId as character
        field UserCategory      as character    /* supplier/customer/employee */
        field LastLoginDate     as datetime-tz
        field LastLoginLocation as character
        field LocaleName        as character
        field LoginName         as character
        field LoginDomain       as character
        field Password          as character
        index idx1 as primary LoginDomain LoginName 
        .
    
    define private dataset dsUser for eUserLogin.        
    
	constructor public UserLoginEntity ( input poServiceManager as IServiceManager, input poComponentInfo as IComponentInfo ):
		super (input poServiceManager, input poComponentInfo).
	end constructor.
		
	constructor public UserLoginEntity ( input poServiceManager as IServiceManager, input poComponentInfo as IComponentInfo, input poDAO as IDataAccess ):
		super (input poServiceManager, input poComponentInfo, input poDAO).
	end constructor.

    method override protected handle CopyStaticDataset (output dataset-handle phDataset):
        phDataset = dataset dsUser:handle.
    end method.
    
end class.